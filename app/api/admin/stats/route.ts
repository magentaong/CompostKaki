import { NextRequest, NextResponse } from 'next/server'
import { requireAdmin, isErrorResponse } from '@/lib/adminAuth'
import { getServiceClient } from '@/lib/adminClient'

export const dynamic = 'force-dynamic'
export const runtime = 'nodejs'

async function count(table: string, filter?: (q: any) => any): Promise<number> {
  const supabase = getServiceClient()
  let query = supabase.from(table).select('id', { count: 'exact', head: true })
  if (filter) query = filter(query)
  const { count: c } = await query
  return c ?? 0
}

export async function GET(req: NextRequest) {
  const ctx = await requireAdmin(req)
  if (isErrorResponse(ctx)) return ctx

  try {
    const [
      totalUsers,
      totalBins,
      healthyBins,
      attentionBins,
      criticalBins,
      totalLogs,
      totalTasks,
      totalAdmins,
    ] = await Promise.all([
      count('profiles'),
      count('bins'),
      count('bins', (q) => q.eq('health_status', 'Healthy')),
      count('bins', (q) => q.eq('health_status', 'Needs Attention')),
      count('bins', (q) => q.eq('health_status', 'Critical')),
      count('bin_logs'),
      count('tasks'),
      count('user_roles'),
    ])

    return NextResponse.json({
      totalUsers,
      totalBins,
      totalLogs,
      totalTasks,
      totalAdmins,
      binsByHealth: {
        healthy: healthyBins,
        needsAttention: attentionBins,
        critical: criticalBins,
      },
    })
  } catch (err: any) {
    console.error('[ADMIN_STATS]', err)
    return NextResponse.json(
      { error: err?.message || 'Failed to load statistics' },
      { status: 500 }
    )
  }
}
