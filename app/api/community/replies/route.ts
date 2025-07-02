import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL as string
const supabaseServiceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY as string
const supabase = createClient(supabaseUrl, supabaseServiceRoleKey)

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url)
  const postId = searchParams.get('post_id')
  if (!postId) return NextResponse.json({ error: 'Missing post_id' }, { status: 400 })
  const { data, error } = await supabase
    .from('forum_replies')
    .select('*')
    .eq('post_id', postId)
    .order('created_at', { ascending: false })
  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json({ replies: data })
}

export async function POST(req: NextRequest) {
  const authHeader = req.headers.get('authorization')
  const jwt = authHeader?.replace('Bearer ', '')
  if (!jwt) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  const { data: { user }, error: userError } = await supabase.auth.getUser(jwt)
  if (userError || !user) return NextResponse.json({ error: 'Invalid user' }, { status: 401 })
  const body = await req.json()
  const { post_id, content, image } = body
  if (!post_id || !content) return NextResponse.json({ error: 'Missing required fields' }, { status: 400 })
  const { data, error } = await supabase
    .from('forum_replies')
    .insert([{ post_id, user_id: user.id, content, image }])
    .select()
    .single()
  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json({ reply: data })
} 