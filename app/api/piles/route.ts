import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL as string
const supabaseServiceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY as string
const supabase = createClient(supabaseUrl, supabaseServiceRoleKey)

export async function GET(req: NextRequest) {
  // Optionally filter by user or public piles
  const { searchParams } = new URL(req.url)
  const userId = searchParams.get('user_id')

  let query = supabase.from('piles').select('*').order('created_at', { ascending: false })
  if (userId) query = query.eq('user_id', userId)

  const { data, error } = await query
  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json({ piles: data })
}

export async function POST(req: NextRequest) {
  const authHeader = req.headers.get('authorization')
  const jwt = authHeader?.replace('Bearer ', '')
  if (!jwt) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  const { data: { user }, error: userError } = await supabase.auth.getUser(jwt)
  if (userError || !user) return NextResponse.json({ error: 'Invalid user' }, { status: 401 })

  const body = await req.json()
  const { name, location, image, description } = body
  if (!name) return NextResponse.json({ error: 'Missing pile name' }, { status: 400 })

  const { data, error } = await supabase
    .from('piles')
    .insert([{ user_id: user.id, name, location, image, description }])
    .select()
    .single()

  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json({ pile: data })
}
