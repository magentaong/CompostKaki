# Admin & Super Admin Dashboard Plan

## Overview

Build a comprehensive admin dashboard integrated into the existing Next.js app at `https://compostkaki.vercel.app/` with role-based access control.

## Architecture Overview

```
/admin (protected route)
├── /dashboard (overview stats)
├── /users (user management)
├── /bins (bin management)
├── /notifications (notification management)
├── /analytics (platform analytics)
└── /settings (admin settings)

/super-admin (super admin only)
├── /admins (admin user management)
├── /system (system settings)
└── /audit-logs (audit trail)
```

## 1. Database Schema Changes

### Add Role System to Profiles

```sql
-- Add role column to profiles table
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'user' 
CHECK (role IN ('user', 'admin', 'super_admin'));

-- Create index for role lookups
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);

-- Update RLS policies to allow admins to view all profiles
CREATE POLICY "Admins can view all profiles"
  ON profiles
  FOR SELECT
  USING (
    auth.uid() = id OR
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('admin', 'super_admin')
    )
  );
```

### Create Admin Audit Logs Table

```sql
CREATE TABLE IF NOT EXISTS admin_audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  action TEXT NOT NULL, -- 'create', 'update', 'delete', 'approve', 'reject'
  resource_type TEXT NOT NULL, -- 'user', 'bin', 'notification', etc.
  resource_id UUID,
  details JSONB,
  ip_address TEXT,
  user_agent TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_admin_id ON admin_audit_logs(admin_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON admin_audit_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_resource ON admin_audit_logs(resource_type, resource_id);
```

## 2. Role-Based Access Control

### Role Definitions

- **User** (default): Regular app user, can manage own bins
- **Admin**: Can manage users, bins, view analytics, moderate content
- **Super Admin**: Full system access, can manage admins, system settings, audit logs

### Permission Matrix

| Feature | User | Admin | Super Admin |
|---------|------|-------|-------------|
| View own bins | ✅ | ✅ | ✅ |
| Create bins | ✅ | ✅ | ✅ |
| View all bins | ❌ | ✅ | ✅ |
| Delete any bin | ❌ | ✅ | ✅ |
| View users | ❌ | ✅ | ✅ |
| Delete users | ❌ | ✅ | ✅ |
| View analytics | ❌ | ✅ | ✅ |
| Manage admins | ❌ | ❌ | ✅ |
| System settings | ❌ | ❌ | ✅ |
| View audit logs | ❌ | ❌ | ✅ |

## 3. Implementation Structure

### File Structure

```
app/
├── admin/
│   ├── layout.tsx (admin layout with sidebar)
│   ├── page.tsx (dashboard overview)
│   ├── users/
│   │   ├── page.tsx (user list)
│   │   └── [id]/
│   │       └── page.tsx (user detail)
│   ├── bins/
│   │   ├── page.tsx (bin list)
│   │   └── [id]/
│   │       └── page.tsx (bin detail)
│   ├── notifications/
│   │   └── page.tsx (notification management)
│   ├── analytics/
│   │   └── page.tsx (platform analytics)
│   └── settings/
│       └── page.tsx (admin settings)
├── super-admin/
│   ├── layout.tsx (super admin layout)
│   ├── page.tsx (super admin dashboard)
│   ├── admins/
│   │   └── page.tsx (admin management)
│   ├── system/
│   │   └── page.tsx (system settings)
│   └── audit-logs/
│       └── page.tsx (audit trail)
├── api/
│   ├── admin/
│   │   ├── users/
│   │   │   ├── route.ts (list users)
│   │   │   └── [id]/
│   │   │       └── route.ts (user operations)
│   │   ├── bins/
│   │   │   └── route.ts (admin bin operations)
│   │   ├── stats/
│   │   │   └── route.ts (admin stats)
│   │   └── audit/
│   │       └── route.ts (audit logs)
│   └── super-admin/
│       ├── admins/
│       │   └── route.ts (admin management)
│       └── system/
│           └── route.ts (system settings)
lib/
├── middleware.ts (route protection)
├── adminAuth.ts (admin auth helpers)
└── auditLogger.ts (audit logging utility)
components/
└── admin/
    ├── AdminSidebar.tsx
    ├── AdminHeader.tsx
    ├── UserTable.tsx
    ├── BinTable.tsx
    ├── StatsCards.tsx
    └── AnalyticsChart.tsx
```

## 4. Key Features

### Admin Dashboard (`/admin`)

#### Dashboard Overview (`/admin`)
- **Key Metrics Cards:**
  - Total Users
  - Total Bins
  - Active Bins
  - Total Activities Logged
  - Total Messages Sent
  - Total Compost Weight (kg)
- **Recent Activity Feed:**
  - New users (last 7 days)
  - New bins created
  - Reported issues
- **Quick Actions:**
  - View pending bin requests
  - View flagged content
  - View system alerts

#### User Management (`/admin/users`)
- **User List Table:**
  - Search/filter by name, email, role
  - Sort by registration date, activity
  - Pagination
  - Columns: Name, Email, Role, Bins Owned, Joined Date, Status
- **User Actions:**
  - View user profile
  - View user's bins
  - Suspend/activate user
  - Delete user (with confirmation)
  - Change user role (admin only)
- **User Detail Page:**
  - User profile info
  - Bins owned/joined
  - Activity history
  - Messages sent
  - Tasks created/completed

#### Bin Management (`/admin/bins`)
- **Bin List Table:**
  - Search/filter by name, location, status
  - Sort by creation date, member count
  - Columns: Name, Location, Owner, Members, Status, Created Date
- **Bin Actions:**
  - View bin details
  - Edit bin info
  - Delete bin (with confirmation)
  - View bin members
  - View bin activities/logs
  - View bin messages

#### Notification Management (`/admin/notifications`)
- View all notifications
- Filter by type, user, date
- Send manual notifications
- View notification stats

#### Analytics (`/admin/analytics`)
- **Charts:**
  - User growth over time
  - Bin creation trends
  - Activity frequency
  - Geographic distribution (if location data available)
  - Peak usage times
- **Export Options:**
  - Export data as CSV/JSON

### Super Admin Dashboard (`/super-admin`)

#### Admin Management (`/super-admin/admins`)
- List all admins
- Create new admin (promote user)
- Remove admin privileges
- View admin activity

#### System Settings (`/super-admin/system`)
- Platform-wide settings
- Feature flags
- Email templates
- Notification settings
- Maintenance mode toggle

#### Audit Logs (`/super-admin/audit-logs`)
- View all admin actions
- Filter by admin, action type, date
- Export audit trail
- Search functionality

## 5. Authentication & Authorization

### Middleware (`lib/middleware.ts`)

```typescript
// Check if user is admin
export async function requireAdmin(req: NextRequest) {
  const user = await requireUser(req);
  if (!user) return null;
  
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single();
  
  if (profile?.role !== 'admin' && profile?.role !== 'super_admin') {
    return null;
  }
  
  return { user, role: profile.role };
}

// Check if user is super admin
export async function requireSuperAdmin(req: NextRequest) {
  const user = await requireUser(req);
  if (!user) return null;
  
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single();
  
  if (profile?.role !== 'super_admin') {
    return null;
  }
  
  return { user, role: profile.role };
}
```

### Route Protection

Use Next.js middleware or layout-level checks:

```typescript
// app/admin/layout.tsx
export default async function AdminLayout({ children }) {
  const user = await requireAdmin();
  if (!user) {
    redirect('/');
  }
  // ... render admin layout
}
```

## 6. UI Components

### Design System
- Use existing Tailwind CSS + Radix UI components
- Match current app design (green theme: #00796B)
- Responsive design (mobile-friendly)
- Dark mode support (optional)

### Key Components

1. **AdminSidebar**: Navigation sidebar with role-based menu items
2. **AdminHeader**: Top bar with user info, notifications, logout
3. **StatsCards**: Reusable metric cards
4. **DataTable**: Reusable table component with sorting/filtering
5. **UserCard**: User summary card
6. **BinCard**: Bin summary card
7. **AnalyticsChart**: Chart component (using a charting library)

## 7. API Routes

### Admin API Routes

- `GET /api/admin/users` - List users (with pagination, filters)
- `GET /api/admin/users/[id]` - Get user details
- `DELETE /api/admin/users/[id]` - Delete user
- `PATCH /api/admin/users/[id]` - Update user (role, status)
- `GET /api/admin/bins` - List bins (admin view)
- `DELETE /api/admin/bins/[id]` - Delete bin
- `GET /api/admin/stats` - Get admin dashboard stats
- `GET /api/admin/analytics` - Get analytics data

### Super Admin API Routes

- `GET /api/super-admin/admins` - List admins
- `POST /api/super-admin/admins` - Create admin
- `DELETE /api/super-admin/admins/[id]` - Remove admin
- `GET /api/super-admin/audit-logs` - Get audit logs
- `GET /api/super-admin/system` - Get system settings
- `PATCH /api/super-admin/system` - Update system settings

## 8. Security Considerations

1. **RLS Policies**: Ensure proper Row Level Security on all tables
2. **API Validation**: Validate all admin actions server-side
3. **Audit Logging**: Log all admin actions
4. **Rate Limiting**: Prevent abuse of admin endpoints
5. **CSRF Protection**: Protect admin forms
6. **Input Sanitization**: Sanitize all user inputs

## 9. Implementation Phases

### Phase 1: Foundation (Week 1)
- [ ] Add role column to profiles table
- [ ] Create admin audit logs table
- [ ] Implement admin auth helpers
- [ ] Create admin layout structure
- [ ] Set up route protection

### Phase 2: Admin Dashboard (Week 2)
- [ ] Dashboard overview page
- [ ] User management page
- [ ] Bin management page
- [ ] Basic stats API

### Phase 3: Advanced Features (Week 3)
- [ ] Analytics page
- [ ] Notification management
- [ ] Search and filtering
- [ ] Export functionality

### Phase 4: Super Admin (Week 4)
- [ ] Super admin routes
- [ ] Admin management
- [ ] System settings
- [ ] Audit logs viewer

## 10. Tech Stack Decisions

- **UI Framework**: Next.js 15 (App Router) ✅ Already using
- **Styling**: Tailwind CSS ✅ Already using
- **Components**: Radix UI ✅ Already using
- **Charts**: Recharts or Chart.js (lightweight, React-friendly)
- **Tables**: Custom with Radix UI or TanStack Table
- **Icons**: Lucide React ✅ Already using

## 11. Next Steps

1. **Create database migrations** for role system
2. **Set up first super admin** user manually in database
3. **Build admin layout** with sidebar navigation
4. **Implement dashboard overview** with stats
5. **Build user management** page
6. **Add audit logging** to all admin actions

Would you like me to start implementing any specific part of this plan?

