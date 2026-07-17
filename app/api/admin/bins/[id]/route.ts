import { NextRequest, NextResponse } from 'next/server'
import { requireAdmin, isErrorResponse } from '@/lib/adminAuth'
import { getServiceClient, writeAuditLog } from '@/lib/adminClient'
import { getUserByEmail } from '@/lib/getUserByEmail'

export const dynamic = 'force-dynamic'
export const runtime = 'nodejs'

const HEALTH_VALUES = ['Healthy', 'Needs Attention', 'Critical']

function extractId(req: NextRequest): string | null {
  const match = new URL(req.url).pathname.match(/\/api\/admin\/bins\/([^\/]+)/)
  return match ? match[1] : null
}

export async function PATCH(req: NextRequest) {
  const ctx = await requireAdmin(req)
  if (isErrorResponse(ctx)) return ctx

  const binId = extractId(req)
  if (!binId) {
    return NextResponse.json({ error: 'Missing bin id' }, { status: 400 })
  }

  let body: { healthStatus?: string; newOwnerEmail?: string }
  try {
    body = await req.json()
  } catch {
    return NextResponse.json({ error: 'Invalid request body' }, { status: 400 })
  }

  const supabase = getServiceClient()

  const { data: bin, error: binError } = await supabase
    .from('bins')
    .select('*')
    .eq('id', binId)
    .single()
  if (binError || !bin) {
    return NextResponse.json({ error: 'Bin not found' }, { status: 404 })
  }

  const updates: Record<string, unknown> = {}
  const auditDetails: Record<string, unknown> = {}

  if (body.healthStatus !== undefined) {
    if (!HEALTH_VALUES.includes(body.healthStatus)) {
      return NextResponse.json(
        { error: `healthStatus must be one of: ${HEALTH_VALUES.join(', ')}` },
        { status: 400 }
      )
    }
    updates.health_status = body.healthStatus
    auditDetails.healthStatus = {
      from: bin.health_status,
      to: body.healthStatus,
    }
  }

  if (body.newOwnerEmail !== undefined) {
    const email = body.newOwnerEmail.trim().toLowerCase()
    const newOwner = await getUserByEmail(supabase, email)
    if (!newOwner) {
      return NextResponse.json(
        { error: 'No registered user found with that email' },
        { status: 404 }
      )
    }
    updates.user_id = newOwner.id
    auditDetails.owner = { from: bin.user_id, to: newOwner.id, email }
  }

  if (Object.keys(updates).length === 0) {
    return NextResponse.json(
      { error: 'No valid fields to update' },
      { status: 400 }
    )
  }

  const { error: updateError } = await supabase
    .from('bins')
    .update(updates)
    .eq('id', binId)
  if (updateError) {
    return NextResponse.json({ error: updateError.message }, { status: 500 })
  }

  await writeAuditLog({
    adminId: ctx.user.id,
    adminEmail: ctx.user.email,
    action: 'bin.update',
    resourceType: 'bin',
    resourceId: binId,
    details: auditDetails,
  })

  return NextResponse.json({ success: true })
}
