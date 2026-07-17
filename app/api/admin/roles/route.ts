import { NextRequest, NextResponse } from 'next/server'
import { requireSuperAdmin, isErrorResponse } from '@/lib/adminAuth'
import { getServiceClient, writeAuditLog } from '@/lib/adminClient'
import { getUserByEmail } from '@/lib/getUserByEmail'

export const dynamic = 'force-dynamic'
export const runtime = 'nodejs'

const ASSIGNABLE_ROLES = ['user', 'admin', 'super_admin'] as const
type AssignableRole = (typeof ASSIGNABLE_ROLES)[number]

export async function POST(req: NextRequest) {
  const ctx = await requireSuperAdmin(req)
  if (isErrorResponse(ctx)) return ctx

  let body: { email?: string; role?: string }
  try {
    body = await req.json()
  } catch {
    return NextResponse.json({ error: 'Invalid request body' }, { status: 400 })
  }

  const email = (body.email || '').trim().toLowerCase()
  const role = body.role as AssignableRole

  if (!email) {
    return NextResponse.json({ error: 'Email is required' }, { status: 400 })
  }
  if (!ASSIGNABLE_ROLES.includes(role)) {
    return NextResponse.json(
      { error: 'role must be "user", "admin", or "super_admin"' },
      { status: 400 }
    )
  }

  try {
    const supabase = getServiceClient()
    const target = await getUserByEmail(supabase, email)
    if (!target) {
      return NextResponse.json(
        { error: 'No registered user found with that email' },
        { status: 404 }
      )
    }

    // Prevent a super admin from demoting themselves and locking everyone out.
    if (target.id === ctx.user.id && role !== 'super_admin') {
      return NextResponse.json(
        { error: 'You cannot remove your own super admin role' },
        { status: 400 }
      )
    }

    // Never allow the last super admin to be demoted.
    if (role !== 'super_admin') {
      const { data: currentRole } = await supabase
        .from('user_roles')
        .select('role')
        .eq('user_id', target.id)
        .maybeSingle()
      if (currentRole?.role === 'super_admin') {
        const { count } = await supabase
          .from('user_roles')
          .select('user_id', { count: 'exact', head: true })
          .eq('role', 'super_admin')
        if ((count ?? 0) <= 1) {
          return NextResponse.json(
            { error: 'Cannot demote the last remaining super admin' },
            { status: 400 }
          )
        }
      }
    }

    if (role === 'user') {
      const { error } = await supabase
        .from('user_roles')
        .delete()
        .eq('user_id', target.id)
      if (error) {
        return NextResponse.json({ error: error.message }, { status: 500 })
      }
    } else {
      const { error } = await supabase.from('user_roles').upsert({
        user_id: target.id,
        role,
        granted_by: ctx.user.id,
        granted_at: new Date().toISOString(),
      })
      if (error) {
        return NextResponse.json({ error: error.message }, { status: 500 })
      }
    }

    await writeAuditLog({
      adminId: ctx.user.id,
      adminEmail: ctx.user.email,
      action: 'user.role_change',
      resourceType: 'user',
      resourceId: target.id,
      details: { email, newRole: role },
    })

    return NextResponse.json({ success: true })
  } catch (err: any) {
    console.error('[ADMIN_ROLES]', err)
    return NextResponse.json(
      { error: err?.message || 'Failed to update role' },
      { status: 500 }
    )
  }
}
