import { NextRequest, NextResponse } from 'next/server'
import type { User } from '@supabase/supabase-js'
import { requireUser } from '@/lib/requireUser'
import { getServiceClient } from '@/lib/adminClient'

export type AdminRole = 'admin' | 'super_admin'

export type AdminContext = {
  user: User
  role: AdminRole
}

/**
 * Resolve the platform role for a given user id. Returns null for regular users.
 */
export async function getUserRole(userId: string): Promise<AdminRole | null> {
  const supabase = getServiceClient()
  const { data, error } = await supabase
    .from('user_roles')
    .select('role')
    .eq('user_id', userId)
    .maybeSingle()
  if (error || !data) return null
  return data.role as AdminRole
}

/**
 * Verify the request comes from an authenticated admin or super admin.
 * Returns the admin context, or a ready-to-return NextResponse error.
 */
export async function requireAdmin(
  req: NextRequest
): Promise<AdminContext | NextResponse> {
  const user = await requireUser(req)
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }
  const role = await getUserRole(user.id)
  if (role !== 'admin' && role !== 'super_admin') {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
  }
  return { user, role }
}

/**
 * Verify the request comes from an authenticated super admin.
 */
export async function requireSuperAdmin(
  req: NextRequest
): Promise<AdminContext | NextResponse> {
  const result = await requireAdmin(req)
  if (result instanceof NextResponse) return result
  if (result.role !== 'super_admin') {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
  }
  return result
}

export function isErrorResponse(
  value: AdminContext | NextResponse
): value is NextResponse {
  return value instanceof NextResponse
}
