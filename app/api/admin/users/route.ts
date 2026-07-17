import { NextRequest, NextResponse } from 'next/server'
import type { User } from '@supabase/supabase-js'
import { requireAdmin, isErrorResponse } from '@/lib/adminAuth'
import { getServiceClient } from '@/lib/adminClient'

export const dynamic = 'force-dynamic'
export const runtime = 'nodejs'

async function listAllAuthUsers(): Promise<User[]> {
  const supabase = getServiceClient()
  const all: User[] = []
  let page = 1
  const perPage = 1000
  while (true) {
    const { data, error } = await supabase.auth.admin.listUsers({ page, perPage })
    if (error) throw error
    all.push(...data.users)
    if (data.users.length < perPage) break
    page++
  }
  return all
}

export async function GET(req: NextRequest) {
  const ctx = await requireAdmin(req)
  if (isErrorResponse(ctx)) return ctx

  const url = new URL(req.url)
  const search = (url.searchParams.get('search') || '').trim().toLowerCase()
  const page = Math.max(1, parseInt(url.searchParams.get('page') || '1', 10))
  const pageSize = Math.min(
    100,
    Math.max(1, parseInt(url.searchParams.get('pageSize') || '20', 10))
  )

  try {
    const supabase = getServiceClient()
    const [authUsers, profilesRes, rolesRes] = await Promise.all([
      listAllAuthUsers(),
      supabase.from('profiles').select('id, first_name, last_name, avatar_url'),
      supabase.from('user_roles').select('user_id, role'),
    ])

    const profileMap = new Map(
      (profilesRes.data || []).map((p: any) => [p.id, p])
    )
    const roleMap = new Map(
      (rolesRes.data || []).map((r: any) => [r.user_id, r.role])
    )

    let rows = authUsers.map((u) => {
      const profile = profileMap.get(u.id) || {}
      const firstName = profile.first_name || ''
      const lastName = profile.last_name || ''
      const name = `${firstName} ${lastName}`.trim()
      const bannedUntil = (u as any).banned_until as string | undefined
      const isSuspended = !!bannedUntil && new Date(bannedUntil) > new Date()
      return {
        id: u.id,
        email: u.email || '',
        name,
        avatarUrl: profile.avatar_url || null,
        role: (roleMap.get(u.id) as string) || 'user',
        isSuspended,
        createdAt: u.created_at,
      }
    })

    if (search) {
      rows = rows.filter(
        (r) =>
          r.email.toLowerCase().includes(search) ||
          r.name.toLowerCase().includes(search)
      )
    }

    rows.sort(
      (a, b) =>
        new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
    )

    const total = rows.length
    const start = (page - 1) * pageSize
    const items = rows.slice(start, start + pageSize)

    return NextResponse.json({ items, total, page, pageSize })
  } catch (err: any) {
    console.error('[ADMIN_USERS]', err)
    return NextResponse.json(
      { error: err?.message || 'Failed to load users' },
      { status: 500 }
    )
  }
}
