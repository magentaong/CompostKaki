"use client"

import { useCallback, useEffect, useState } from "react"
import { apiFetch } from "@/lib/apiFetch"
import { useAdmin } from "@/components/admin/AdminShell"
import {
  PageHeader,
  CenteredSpinner,
  EmptyState,
  RoleBadge,
  StatusBadge,
  Modal,
  Banner,
} from "@/components/admin/ui"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Search, UserPlus } from "lucide-react"

type AdminUser = {
  id: string
  email: string
  name: string
  avatarUrl: string | null
  role: string
  isSuspended: boolean
  createdAt: string
}

const PAGE_SIZE = 20

function formatDate(iso: string) {
  if (!iso) return "—"
  return new Date(iso).toLocaleDateString(undefined, {
    year: "numeric",
    month: "short",
    day: "numeric",
  })
}

export default function AdminUsersPage() {
  const me = useAdmin()
  const isSuper = me.role === "super_admin"

  const [items, setItems] = useState<AdminUser[]>([])
  const [total, setTotal] = useState(0)
  const [page, setPage] = useState(1)
  const [search, setSearch] = useState("")
  const [query, setQuery] = useState("")
  const [loading, setLoading] = useState(true)
  const [banner, setBanner] = useState<
    { kind: "success" | "error"; message: string } | null
  >(null)
  const [busyId, setBusyId] = useState<string | null>(null)

  const [promoteOpen, setPromoteOpen] = useState(false)
  const [promoteEmail, setPromoteEmail] = useState("")
  const [promoteRole, setPromoteRole] = useState("admin")
  const [promoteBusy, setPromoteBusy] = useState(false)

  const load = useCallback(async () => {
    setLoading(true)
    const params = new URLSearchParams({
      page: String(page),
      pageSize: String(PAGE_SIZE),
    })
    if (query) params.set("search", query)
    const res = await apiFetch(`/api/admin/users?${params.toString()}`)
    if (res.ok) {
      const data = await res.json()
      setItems(data.items)
      setTotal(data.total)
    } else {
      const data = await res.json().catch(() => ({}))
      setBanner({ kind: "error", message: data.error || "Failed to load users" })
    }
    setLoading(false)
  }, [page, query])

  useEffect(() => {
    load()
  }, [load])

  const onSearch = (e: React.FormEvent) => {
    e.preventDefault()
    setPage(1)
    setQuery(search.trim())
  }

  const toggleSuspend = async (user: AdminUser) => {
    const action = user.isSuspended ? "reactivate" : "suspend"
    if (
      action === "suspend" &&
      !confirm(`Suspend ${user.email}? They will be signed out and blocked from signing in.`)
    ) {
      return
    }
    setBusyId(user.id)
    const res = await apiFetch(`/api/admin/users/${user.id}`, {
      method: "PATCH",
      body: JSON.stringify({ action }),
    })
    setBusyId(null)
    if (res.ok) {
      setBanner({
        kind: "success",
        message: `${user.email} ${action === "suspend" ? "suspended" : "reactivated"}.`,
      })
      load()
    } else {
      const data = await res.json().catch(() => ({}))
      setBanner({ kind: "error", message: data.error || "Action failed" })
    }
  }

  const changeRole = async (user: AdminUser, newRole: string) => {
    if (newRole === user.role) return
    if (!confirm(`Change role for ${user.email} to "${newRole}"?`)) return
    setBusyId(user.id)
    const res = await apiFetch(`/api/admin/roles`, {
      method: "POST",
      body: JSON.stringify({ email: user.email, role: newRole }),
    })
    setBusyId(null)
    if (res.ok) {
      setBanner({ kind: "success", message: `Role updated for ${user.email}.` })
      load()
    } else {
      const data = await res.json().catch(() => ({}))
      setBanner({ kind: "error", message: data.error || "Failed to update role" })
    }
  }

  const submitPromote = async () => {
    if (!promoteEmail.trim()) return
    setPromoteBusy(true)
    const res = await apiFetch(`/api/admin/roles`, {
      method: "POST",
      body: JSON.stringify({
        email: promoteEmail.trim(),
        role: promoteRole,
      }),
    })
    setPromoteBusy(false)
    if (res.ok) {
      setPromoteOpen(false)
      setPromoteEmail("")
      setPromoteRole("admin")
      setBanner({ kind: "success", message: "Role assigned successfully." })
      load()
    } else {
      const data = await res.json().catch(() => ({}))
      setBanner({ kind: "error", message: data.error || "Failed to assign role" })
    }
  }

  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE))

  return (
    <div>
      <PageHeader
        title="Users"
        description="View community members, manage access, and assign roles."
        action={
          isSuper ? (
            <Button onClick={() => setPromoteOpen(true)}>
              <UserPlus className="size-4" />
              Assign role
            </Button>
          ) : undefined
        }
      />

      {banner && (
        <Banner
          kind={banner.kind}
          message={banner.message}
          onDismiss={() => setBanner(null)}
        />
      )}

      <form onSubmit={onSearch} className="mb-4 flex gap-2">
        <div className="relative flex-1 max-w-sm">
          <Search className="absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground" />
          <Input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search by name or email"
            className="pl-9"
          />
        </div>
        <Button type="submit" variant="outline">
          Search
        </Button>
      </form>

      {loading ? (
        <CenteredSpinner />
      ) : items.length === 0 ? (
        <EmptyState message="No users found." />
      ) : (
        <div className="overflow-hidden rounded-xl border bg-card">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b bg-muted/50 text-left text-xs uppercase tracking-wide text-muted-foreground">
                  <th className="px-4 py-3 font-medium">User</th>
                  <th className="px-4 py-3 font-medium">Role</th>
                  <th className="px-4 py-3 font-medium">Status</th>
                  <th className="px-4 py-3 font-medium">Joined</th>
                  <th className="px-4 py-3 font-medium text-right">Actions</th>
                </tr>
              </thead>
              <tbody>
                {items.map((user) => {
                  const isSelf = user.id === me.id
                  return (
                    <tr key={user.id} className="border-b last:border-0">
                      <td className="px-4 py-3">
                        <div className="flex items-center gap-3">
                          <div className="flex size-9 shrink-0 items-center justify-center overflow-hidden rounded-full bg-secondary text-sm font-semibold text-secondary-foreground">
                            {user.avatarUrl ? (
                              // eslint-disable-next-line @next/next/no-img-element
                              <img
                                src={user.avatarUrl}
                                alt=""
                                className="size-full object-cover"
                              />
                            ) : (
                              (user.name || user.email)[0]?.toUpperCase()
                            )}
                          </div>
                          <div className="min-w-0">
                            <div className="truncate font-medium text-foreground">
                              {user.name || "—"}
                              {isSelf && (
                                <span className="ml-1 text-xs text-muted-foreground">
                                  (you)
                                </span>
                              )}
                            </div>
                            <div className="truncate text-xs text-muted-foreground">
                              {user.email}
                            </div>
                          </div>
                        </div>
                      </td>
                      <td className="px-4 py-3">
                        {isSuper && !isSelf ? (
                          <select
                            value={user.role}
                            disabled={busyId === user.id}
                            onChange={(e) => changeRole(user, e.target.value)}
                            className="h-8 rounded-md border border-input bg-background px-2 text-sm outline-none focus-visible:ring-2 focus-visible:ring-ring/50 disabled:opacity-50"
                          >
                            <option value="user">User</option>
                            <option value="admin">Admin</option>
                            <option value="super_admin">Super Admin</option>
                          </select>
                        ) : (
                          <RoleBadge role={user.role} />
                        )}
                      </td>
                      <td className="px-4 py-3">
                        <StatusBadge suspended={user.isSuspended} />
                      </td>
                      <td className="px-4 py-3 text-muted-foreground">
                        {formatDate(user.createdAt)}
                      </td>
                      <td className="px-4 py-3 text-right">
                        <Button
                          variant={user.isSuspended ? "outline" : "destructive"}
                          size="sm"
                          disabled={isSelf || busyId === user.id}
                          onClick={() => toggleSuspend(user)}
                        >
                          {user.isSuspended ? "Reactivate" : "Suspend"}
                        </Button>
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {!loading && items.length > 0 && (
        <div className="mt-4 flex items-center justify-between text-sm text-muted-foreground">
          <span>
            {total} user{total === 1 ? "" : "s"} · Page {page} of {totalPages}
          </span>
          <div className="flex gap-2">
            <Button
              variant="outline"
              size="sm"
              disabled={page <= 1}
              onClick={() => setPage((p) => Math.max(1, p - 1))}
            >
              Previous
            </Button>
            <Button
              variant="outline"
              size="sm"
              disabled={page >= totalPages}
              onClick={() => setPage((p) => p + 1)}
            >
              Next
            </Button>
          </div>
        </div>
      )}

      <Modal
        open={promoteOpen}
        onClose={() => setPromoteOpen(false)}
        title="Assign a role"
      >
        <div className="space-y-4">
          <p className="text-sm text-muted-foreground">
            Enter the email of an already registered user to grant them access.
          </p>
          <div>
            <label className="mb-1 block text-sm font-medium">Email</label>
            <Input
              type="email"
              value={promoteEmail}
              onChange={(e) => setPromoteEmail(e.target.value)}
              placeholder="person@example.com"
            />
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium">Role</label>
            <select
              value={promoteRole}
              onChange={(e) => setPromoteRole(e.target.value)}
              className="h-9 w-full rounded-md border border-input bg-background px-3 text-sm outline-none focus-visible:ring-2 focus-visible:ring-ring/50"
            >
              <option value="admin">Admin</option>
              <option value="super_admin">Super Admin</option>
            </select>
          </div>
          <div className="flex justify-end gap-2 pt-2">
            <Button variant="outline" onClick={() => setPromoteOpen(false)}>
              Cancel
            </Button>
            <Button onClick={submitPromote} disabled={promoteBusy}>
              {promoteBusy ? "Assigning…" : "Assign role"}
            </Button>
          </div>
        </div>
      </Modal>
    </div>
  )
}
