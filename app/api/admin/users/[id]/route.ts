import { NextRequest, NextResponse } from 'next/server'
import { requireAdmin, isErrorResponse, getUserRole } from '@/lib/adminAuth'
import { getServiceClient, writeAuditLog } from '@/lib/adminClient'

export const dynamic = 'force-dynamic'
export const runtime = 'nodejs'

function extractId(req: NextRequest): string | null {
  const match = new URL(req.url).pathname.match(/\/api\/admin\/users\/([^\/]+)/)
  return match ? match[1] : null
}

// Permanent ban duration used to represent a suspended account.
const SUSPEND_DURATION = '876000h' // ~100 years

export async function PATCH(req: NextRequest) {
  const ctx = await requireAdmin(req)
  if (isErrorResponse(ctx)) return ctx

  const targetId = extractId(req)
  if (!targetId) {
    return NextResponse.json({ error: 'Missing user id' }, { status: 400 })
  }

  let body: { action?: string }
  try {
    body = await req.json()
  } catch {
    return NextResponse.json({ error: 'Invalid request body' }, { status: 400 })
  }

  const action = body.action
  if (action !== 'suspend' && action !== 'reactivate') {
    return NextResponse.json(
      { error: 'action must be "suspend" or "reactivate"' },
      { status: 400 }
    )
  }

  if (targetId === ctx.user.id) {
    return NextResponse.json(
      { error: 'You cannot change your own account status' },
      { status: 400 }
    )
  }

  // Protect super admins from being suspended.
  const targetRole = await getUserRole(targetId)
  if (action === 'suspend' && targetRole === 'super_admin') {
    return NextResponse.json(
      { error: 'A super admin cannot be suspended' },
      { status: 403 }
    )
  }

  try {
    const supabase = getServiceClient()
    const { error } = await supabase.auth.admin.updateUserById(targetId, {
      ban_duration: action === 'suspend' ? SUSPEND_DURATION : 'none',
    })
    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    await writeAuditLog({
      adminId: ctx.user.id,
      adminEmail: ctx.user.email,
      action: action === 'suspend' ? 'user.suspend' : 'user.reactivate',
      resourceType: 'user',
      resourceId: targetId,
    })

    return NextResponse.json({ success: true })
  } catch (err: any) {
    console.error('[ADMIN_USER_PATCH]', err)
    return NextResponse.json(
      { error: err?.message || 'Failed to update user' },
      { status: 500 }
    )
  }
}
