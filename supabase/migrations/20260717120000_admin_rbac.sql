-- Admin RBAC and audit logging for the CompostKaki admin portal.
-- These tables are managed exclusively through server-side API routes that
-- use the Supabase service role key. RLS is enabled with no policies so that
-- anon/authenticated clients (web app and mobile app) can neither read nor
-- write them; only the service role (which bypasses RLS) has access.

-- 1. Platform-wide roles. Absence of a row means the user is a regular user.
CREATE TABLE IF NOT EXISTS user_roles (
  user_id     UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role        TEXT NOT NULL CHECK (role IN ('admin', 'super_admin')),
  granted_by  UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  granted_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_user_roles_role ON user_roles(role);

ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;
-- No policies: locked to the service role only.

-- 2. Append-only audit trail of every privileged admin action.
CREATE TABLE IF NOT EXISTS admin_audit_logs (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id       UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  admin_email    TEXT,
  action         TEXT NOT NULL,
  resource_type  TEXT NOT NULL,
  resource_id    TEXT,
  details        JSONB,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_admin_audit_logs_created_at ON admin_audit_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_admin_audit_logs_admin_id ON admin_audit_logs(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_audit_logs_resource ON admin_audit_logs(resource_type, resource_id);

ALTER TABLE admin_audit_logs ENABLE ROW LEVEL SECURITY;
-- No policies: locked to the service role only.

-- 3. Bootstrap the first super admin (run once, replace the email).
-- INSERT INTO user_roles (user_id, role)
-- SELECT id, 'super_admin' FROM auth.users WHERE email = 'you@example.com'
-- ON CONFLICT (user_id) DO UPDATE SET role = 'super_admin';
