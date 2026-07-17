import { NextRequest, NextResponse } from 'next/server'
import { requireAdmin, isErrorResponse } from '@/lib/adminAuth'
import { getServiceClient } from '@/lib/adminClient'

export const dynamic = 'force-dynamic'
export const runtime = 'nodejs'

export async function GET(req: NextRequest) {
  const ctx = await requireAdmin(req)
  if (isErrorResponse(ctx)) return ctx

  const url = new URL(req.url)
  const search = (url.searchParams.get('search') || '').trim().toLowerCase()
  const health = url.searchParams.get('health') || ''
  const page = Math.max(1, parseInt(url.searchParams.get('page') || '1', 10))
  const pageSize = Math.min(
    100,
    Math.max(1, parseInt(url.searchParams.get('pageSize') || '20', 10))
  )

  try {
    const supabase = getServiceClient()
    const [binsRes, profilesRes, membersRes] = await Promise.all([
      supabase.from('bins').select('*'),
      supabase.from('profiles').select('id, first_name, last_name'),
      supabase.from('bin_members').select('bin_id'),
    ])

    if (binsRes.error) {
      return NextResponse.json({ error: binsRes.error.message }, { status: 500 })
    }

    const profileMap = new Map(
      (profilesRes.data || []).map((p: any) => [p.id, p])
    )
    const memberCounts = new Map<string, number>()
    for (const m of membersRes.data || []) {
      memberCounts.set(m.bin_id, (memberCounts.get(m.bin_id) || 0) + 1)
    }

    let rows = (binsRes.data || []).map((b: any) => {
      const owner = profileMap.get(b.user_id) || {}
      const ownerName =
        `${owner.first_name || ''} ${owner.last_name || ''}`.trim() ||
        'Unknown'
      return {
        id: b.id,
        name: b.name || 'Untitled bin',
        location: b.location || '',
        ownerId: b.user_id,
        ownerName,
        healthStatus: b.health_status || 'Unknown',
        memberCount: memberCounts.get(b.id) || 0,
        createdAt: b.created_at,
      }
    })

    if (search) {
      rows = rows.filter(
        (r) =>
          r.name.toLowerCase().includes(search) ||
          r.location.toLowerCase().includes(search) ||
          r.ownerName.toLowerCase().includes(search)
      )
    }
    if (health) {
      rows = rows.filter((r) => r.healthStatus === health)
    }

    rows.sort((a, b) => {
      const at = a.createdAt ? new Date(a.createdAt).getTime() : 0
      const bt = b.createdAt ? new Date(b.createdAt).getTime() : 0
      return bt - at
    })

    const total = rows.length
    const start = (page - 1) * pageSize
    const items = rows.slice(start, start + pageSize)

    return NextResponse.json({ items, total, page, pageSize })
  } catch (err: any) {
    console.error('[ADMIN_BINS]', err)
    return NextResponse.json(
      { error: err?.message || 'Failed to load bins' },
      { status: 500 }
    )
  }
}
