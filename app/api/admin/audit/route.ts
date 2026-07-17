import { NextRequest, NextResponse } from 'next/server'
import { requireAdmin, isErrorResponse } from '@/lib/adminAuth'
import { getServiceClient } from '@/lib/adminClient'

export const dynamic = 'force-dynamic'
export const runtime = 'nodejs'

export async function GET(req: NextRequest) {
  const ctx = await requireAdmin(req)
  if (isErrorResponse(ctx)) return ctx

  const url = new URL(req.url)
  const page = Math.max(1, parseInt(url.searchParams.get('page') || '1', 10))
  const pageSize = Math.min(
    100,
    Math.max(1, parseInt(url.searchParams.get('pageSize') || '30', 10))
  )
  const action = url.searchParams.get('action') || ''

  try {
    const supabase = getServiceClient()
    let query = supabase
      .from('admin_audit_logs')
      .select('*', { count: 'exact' })
      .order('created_at', { ascending: false })

    if (action) query = query.eq('action', action)

    const from = (page - 1) * pageSize
    query = query.range(from, from + pageSize - 1)

    const { data, count, error } = await query
    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    const items = (data || []).map((row: any) => ({
      id: row.id,
      adminEmail: row.admin_email,
      action: row.action,
      resourceType: row.resource_type,
      resourceId: row.resource_id,
      details: row.details,
      createdAt: row.created_at,
    }))

    return NextResponse.json({ items, total: count ?? 0, page, pageSize })
  } catch (err: any) {
    console.error('[ADMIN_AUDIT]', err)
    return NextResponse.json(
      { error: err?.message || 'Failed to load audit logs' },
      { status: 500 }
    )
  }
}
