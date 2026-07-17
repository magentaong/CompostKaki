"use client"

import { useCallback, useEffect, useState } from "react"
import { apiFetch } from "@/lib/apiFetch"
import {
  PageHeader,
  CenteredSpinner,
  EmptyState,
  Banner,
} from "@/components/admin/ui"
import { Button } from "@/components/ui/button"

type AuditEntry = {
  id: string
  adminEmail: string | null
  action: string
  resourceType: string
  resourceId: string | null
  details: Record<string, unknown> | null
  createdAt: string
}

const PAGE_SIZE = 30

const ACTION_LABELS: Record<string, string> = {
  "user.suspend": "Suspended user",
  "user.reactivate": "Reactivated user",
  "user.role_change": "Changed user role",
  "bin.update": "Updated bin",
}

function formatWhen(iso: string) {
  if (!iso) return "—"
  return new Date(iso).toLocaleString(undefined, {
    year: "numeric",
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  })
}

function summarize(entry: AuditEntry): string {
  const d = entry.details || {}
  if (entry.action === "user.role_change" && d.newRole) {
    return `New role: ${d.newRole}${d.email ? ` (${d.email})` : ""}`
  }
  if (entry.action === "bin.update") {
    const parts: string[] = []
    const h = d.healthStatus as { from?: string; to?: string } | undefined
    if (h?.to) parts.push(`health → ${h.to}`)
    const o = d.owner as { email?: string } | undefined
    if (o?.email) parts.push(`owner → ${o.email}`)
    return parts.join(", ") || "—"
  }
  return entry.resourceId ? `Target: ${entry.resourceId.slice(0, 8)}…` : "—"
}

export default function AdminAuditPage() {
  const [items, setItems] = useState<AuditEntry[]>([])
  const [total, setTotal] = useState(0)
  const [page, setPage] = useState(1)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState("")

  const load = useCallback(async () => {
    setLoading(true)
    const params = new URLSearchParams({
      page: String(page),
      pageSize: String(PAGE_SIZE),
    })
    const res = await apiFetch(`/api/admin/audit?${params.toString()}`)
    if (res.ok) {
      const data = await res.json()
      setItems(data.items)
      setTotal(data.total)
    } else {
      const data = await res.json().catch(() => ({}))
      setError(data.error || "Failed to load activity log")
    }
    setLoading(false)
  }, [page])

  useEffect(() => {
    load()
  }, [load])

  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE))

  return (
    <div>
      <PageHeader
        title="Activity Log"
        description="An audit trail of every administrative action."
      />

      {error && <Banner kind="error" message={error} onDismiss={() => setError("")} />}

      {loading ? (
        <CenteredSpinner />
      ) : items.length === 0 ? (
        <EmptyState message="No administrative actions recorded yet." />
      ) : (
        <div className="overflow-hidden rounded-xl border bg-card">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b bg-muted/50 text-left text-xs uppercase tracking-wide text-muted-foreground">
                  <th className="px-4 py-3 font-medium">When</th>
                  <th className="px-4 py-3 font-medium">Admin</th>
                  <th className="px-4 py-3 font-medium">Action</th>
                  <th className="px-4 py-3 font-medium">Details</th>
                </tr>
              </thead>
              <tbody>
                {items.map((entry) => (
                  <tr key={entry.id} className="border-b last:border-0">
                    <td className="whitespace-nowrap px-4 py-3 text-muted-foreground">
                      {formatWhen(entry.createdAt)}
                    </td>
                    <td className="px-4 py-3 text-foreground">
                      {entry.adminEmail || "—"}
                    </td>
                    <td className="px-4 py-3">
                      <span className="font-medium text-foreground">
                        {ACTION_LABELS[entry.action] || entry.action}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-muted-foreground">
                      {summarize(entry)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {!loading && items.length > 0 && (
        <div className="mt-4 flex items-center justify-between text-sm text-muted-foreground">
          <span>
            {total} entr{total === 1 ? "y" : "ies"} · Page {page} of {totalPages}
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
    </div>
  )
}
