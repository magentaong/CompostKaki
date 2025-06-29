import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL as string;
const supabaseServiceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY as string;
const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

export async function POST(req: NextRequest) {
  const authHeader = req.headers.get('authorization');
  const jwt = authHeader?.replace('Bearer ', '');
  if (!jwt) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const { data: { user }, error: userError } = await supabase.auth.getUser(jwt);
  if (userError || !user) return NextResponse.json({ error: 'Invalid user' }, { status: 401 });

  const body = await req.json();
  const { binId } = body;
  if (!binId) return NextResponse.json({ error: 'Missing binId' }, { status: 400 });

  // Check if already joined
  const { data: existing } = await supabase
    .from('bin_members')
    .select('*')
    .eq('user_id', user.id)
    .eq('bin_id', binId)
    .single();
  if (existing) return NextResponse.json({ success: true, alreadyJoined: true });

  // Insert join
  const { error: joinError } = await supabase
    .from('bin_members')
    .insert([{ user_id: user.id, bin_id: binId, role: 'member', joined_at: new Date().toISOString() }]);
  if (joinError) return NextResponse.json({ error: joinError.message }, { status: 500 });

  return NextResponse.json({ success: true });
} 