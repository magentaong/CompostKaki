import { createClient, SupabaseClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL as string
const supabaseServiceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY as string

let cached: SupabaseClient | null = null

/**
 * Server-only Supabase client using the service role key. Never import this
 * from client components. It bypasses RLS, so every caller must first verify
 * the requester's admin role via requireAdmin/requireSuperAdmin.
 */
export function getServiceClient(): SupabaseClient {
  if (!supabaseServiceRoleKey) {
    throw new Error('SUPABASE_SERVICE_ROLE_KEY is not configured')
  }
  if (!cached) {
    cached = createClient(supabaseUrl, supabaseServiceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    })
  }
  return cached
}

type AuditEntry = {
  adminId: string
  adminEmail?: string | null
  action: string
  resourceType: string
  resourceId?: string | null
  details?: Record<string, unknown>
}

/**
 * Record a privileged admin action. Audit failures are logged but never block
 * the underlying operation from returning a result to the caller.
 */
export async function writeAuditLog(entry: AuditEntry): Promise<void> {
  try {
    const supabase = getServiceClient()
    await supabase.from('admin_audit_logs').insert({
      admin_id: entry.adminId,
      admin_email: entry.adminEmail ?? null,
      action: entry.action,
      resource_type: entry.resourceType,
      resource_id: entry.resourceId ?? null,
      details: entry.details ?? {},
    })
  } catch (err) {
    console.error('[ADMIN_AUDIT] Failed to write audit log', err)
  }
}
