import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@supabase/supabase-js'
import { requireUser } from '@/lib/requireUser';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL as string
const supabaseServiceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY as string
const supabase = createClient(supabaseUrl, supabaseServiceRoleKey)

function extractIdFromUrl(req: NextRequest): string | null {
  const url = new URL(req.url)
  const match = url.pathname.match(/\/api\/bins\/([^\/]+)/)
  return match ? match[1] : null
}

export async function GET(req: NextRequest) {
  const user = await requireUser(req);
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  const id = extractIdFromUrl(req)
  if (!id) return NextResponse.json({ error: 'Missing bin ID' }, { status: 400 })

  const { data, error } = await supabase.from('bins').select('*').eq('id', id).single()
  if (error) return NextResponse.json({ error: error.message }, { status: 500 })

  // Fetch bin members
  const { data: members, error: membersError } = await supabase
    .from('bin_members')
    .select('user_id')
    .eq('bin_id', id);

  const contributors_list = members ? members.map((m: any) => m.user_id) : [];

  return NextResponse.json({ bin: { ...data, contributors_list } })
}

export async function POST(req: NextRequest) {
  const user = await requireUser(req);
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  const id = extractIdFromUrl(req)
  if (!id) return NextResponse.json({ error: 'Missing bin ID' }, { status: 400 })

  const { health_status } = await req.json()
  const { error } = await supabase
    .from('bins')
    .update({ health_status })
    .eq('id', id)

  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json({ success: true })
}

export async function DELETE(req: NextRequest) {
  const user = await requireUser(req);
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  const id = extractIdFromUrl(req);
  if (!id) return NextResponse.json({ error: 'Missing bin ID' }, { status: 400 });

  // Check if the user is the creator of the bin
  const { data: bin, error: binError } = await supabase.from('bins').select('user_id').eq('id', id).single();
  if (binError || !bin) return NextResponse.json({ error: 'Bin not found' }, { status: 404 });
  if (bin.user_id !== user.id) return NextResponse.json({ error: 'Forbidden: Only the creator can delete this bin' }, { status: 403 });

  // Optionally: delete related data (bin_members, bin_logs, etc.)
  await supabase.from('bin_members').delete().eq('bin_id', id);
  await supabase.from('bin_logs').delete().eq('bin_id', id);

  // Delete the bin
  const { error: deleteError } = await supabase.from('bins').delete().eq('id', id);
  if (deleteError) return NextResponse.json({ error: deleteError.message }, { status: 500 });

  return NextResponse.json({ success: true });
}
