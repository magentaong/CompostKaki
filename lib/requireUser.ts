import { createClient } from '@supabase/supabase-js';
import { NextRequest, NextResponse } from 'next/server';

export async function requireUser(req: NextRequest) {
  const authHeader = req.headers.get('authorization');
  const jwt = authHeader?.replace('Bearer ', '');
  if (!jwt) return null;
  const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    { global: { headers: { Authorization: `Bearer ${jwt}` } } }
  );
  const { data: { user } } = await supabase.auth.getUser();
  return user;
}
