import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL as string
const supabaseServiceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY as string
const supabase = createClient(supabaseUrl, supabaseServiceRoleKey)

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url)
  const binId = searchParams.get('bin_id')
  if (!binId) return NextResponse.json({ error: 'Missing bin_id' }, { status: 400 })

  const { data, error } = await supabase
    .from('bin_logs')
    .select('*')
    .eq('bin_id', binId)
    .order('created_at', { ascending: false })

  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json({ entries: data })
}

export async function POST(req: NextRequest) {
  const authHeader = req.headers.get('authorization')
  const jwt = authHeader?.replace('Bearer ', '')
  if (!jwt) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  const { data: { user }, error: userError } = await supabase.auth.getUser(jwt)
  if (userError || !user) return NextResponse.json({ error: 'Invalid user' }, { status: 401 })

  const body = await req.json()
  const { bin_id, content, temperature, moisture, type, images } = body
  if (!bin_id || !content) return NextResponse.json({ error: 'Missing required fields' }, { status: 400 })

  const { data: log, error } = await supabase
    .from('bin_logs')
    .insert([{ bin_id, user_id: user.id, content, temperature, moisture, type, images }])
    .select()
    .single()

  if (error) return NextResponse.json({ error: error.message }, { status: 500 })

  // Health status logic
  let health_status = 'Healthy';
  let tempNum = parseFloat(temperature);
  if (
    (isNaN(tempNum) || tempNum < 35 || tempNum > 65) ||
    (moisture && (moisture.toLowerCase() === 'dry' || moisture.toLowerCase() === 'wet'))
  ) {
    health_status = 'Needs Attention';
  }
  if (
    (isNaN(tempNum) || tempNum < 30 || tempNum > 70) &&
    (moisture && (moisture.toLowerCase() === 'dry' || moisture.toLowerCase() === 'wet'))
  ) {
    health_status = 'Critical';
  }
  // If both temp and moisture are optimal
  if (
    !isNaN(tempNum) && tempNum >= 40 && tempNum <= 60 &&
    (moisture && moisture.toLowerCase() === 'good')
  ) {
    health_status = 'Healthy';
  }

  // Update bin health_status
  await supabase.from('bins').update({ health_status }).eq('id', bin_id);

  return NextResponse.json({ entry: log })
}