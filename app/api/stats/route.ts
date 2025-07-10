import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@supabase/supabase-js'
import { requireUser } from '@/lib/requireUser';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL as string
const supabaseServiceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY as string
const supabase = createClient(supabaseUrl, supabaseServiceRoleKey)

export async function GET(req: NextRequest) {
  const user = await requireUser(req);
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  // Active piles
  const { count: activePiles } = await supabase
    .from('piles')
    .select('id', { count: 'exact', head: true })
    .eq('status', 'active')

  // Volunteers (unique users who created piles or entries)
  const { data: pileUsers } = await supabase
    .from('piles')
    .select('user_id')
  const { data: entryUsers } = await supabase
    .from('pile_entries')
    .select('user_id')
  const userSet = new Set([
    ...(pileUsers?.map((p: any) => p.user_id) || []),
    ...(entryUsers?.map((e: any) => e.user_id) || []),
  ])
  const volunteers = userSet.size

  // Composted (sum of weight in pile_entries, if exists)
  let composted = 0
  const { data: entries } = await supabase
    .from('pile_entries')
    .select('weight')
  if (entries) {
    composted = entries.reduce((sum: number, e: any) => sum + (e.weight || 0), 0)
  }

  return NextResponse.json({
    activePiles: activePiles || 0,
    volunteers,
    composted,
  })
}
