import { NextRequest, NextResponse } from 'next/server'
import { requireAdmin, isErrorResponse } from '@/lib/adminAuth'

export const dynamic = 'force-dynamic'
export const runtime = 'nodejs'

export async function GET(req: NextRequest) {
  const ctx = await requireAdmin(req)
  if (isErrorResponse(ctx)) return ctx
  return NextResponse.json({
    id: ctx.user.id,
    email: ctx.user.email,
    role: ctx.role,
  })
}
