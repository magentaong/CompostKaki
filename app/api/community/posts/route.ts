import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL as string
const supabaseServiceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY as string
const supabase = createClient(supabaseUrl, supabaseServiceRoleKey)

export async function GET(req: NextRequest) {
  const { data, error } = await supabase
    .from('forum_posts')
    .select('*')
    .order('created_at', { ascending: false })
  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json({ posts: data })
}

export async function POST(req: NextRequest) {
  const authHeader = req.headers.get('authorization')
  const jwt = authHeader?.replace('Bearer ', '')
  if (!jwt) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  const { data: { user }, error: userError } = await supabase.auth.getUser(jwt)
  if (userError || !user) return NextResponse.json({ error: 'Invalid user' }, { status: 401 })
  const body = await req.json()
  const { title, content, category, tags, image } = body
  if (!title || !content) return NextResponse.json({ error: 'Missing required fields' }, { status: 400 })
  const { data, error } = await supabase
    .from('forum_posts')
    .insert([{ user_id: user.id, title, content, category, tags, image }])
    .select()
    .single()
  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json({ post: data })
} 