import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL as string
const supabaseServiceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY as string
const supabase = createClient(supabaseUrl, supabaseServiceRoleKey)

export async function GET(req: NextRequest, contextPromise: Promise<{ params: { id: string } }>) {
  const { params } = await contextPromise;
  const { id } = params;
  const { data, error } = await supabase.from('bins').select('*').eq('id', id).single()
  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  // Fetch contributors
  const { data: contributors } = await supabase
    .from('bin_members')
    .select('user_id')
    .eq('bin_id', id)
  const contributors_list = contributors ? contributors.map((c: any) => c.user_id) : []
  return NextResponse.json({ bin: { ...data, contributors_list } })
} 

export async function POST(req: NextRequest, contextPromise: Promise<{ params: { id: string } }>) {
  const { params } = await contextPromise;
  const { id } = params;
  const { health_status } = await req.json();
  const { error } = await supabase
    .from('bins')
    .update({ health_status })
    .eq('id', id);
  if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  return NextResponse.json({ success: true });
}