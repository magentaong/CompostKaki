"use client"

import { useCallback, useEffect, useState } from "react"
import { apiFetch } from "@/lib/apiFetch"
import {
  PageHeader,
  CenteredSpinner,
  EmptyState,
  HealthBadge,
  Modal,
  Banner,
} from "@/components/admin/ui"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Search, ArrowRightLeft } from "lucide-react"

type AdminBin = {
  id: string
  name: string
  location: string
  ownerId: string
  ownerName: string
  healthStatus: string
  memberCount: number
  createdAt: string
}

const PAGE_SIZE = 20
const HEALTH_OPTIONS = ["Healthy", "Needs Attention", "Critical"]

function formatDate(iso: string) {
  if (!iso) return "—"
  return new Date(iso).toLocaleDateString(undefined, {
    year: "numeric",
    month: "short",
    day: "numeric",
  })
}

export default function AdminBinsPage() {
  const [items, setItems] = useState<AdminBin[]>([])
  const [total, setTotal] = useState(0)
  const [page, setPage] = useState(1)
  const [search, setSearch] = useState("")
  const [query, setQuery] = useState("")
  const [health, setHealth] = useState("")
  const [loading, setLoading] = useState(true)
  const [busyId, setBusyId] = useState<string | null>(null)
  const [banner, setBanner] = useState<
    { kind: "success" | "error"; message: string } | null
  >(null)

  const [transferBin, setTransferBin] = useState<AdminBin | null>(null)
  const [transferEmail, setTransferEmail] = useState("")
  const [transferBusy, setTransferBusy] = useState(false)

  const load = useCallback(async () => {
    setLoading(true)
    const params = new URLSearchParams({
      page: String(page),
      pageSize: String(PAGE_SIZE),
    })
    if (query) params.set("search", query)
    if (health) params.set("health", health)
    const res = await apiFetch(`/api/admin/bins?${params.toString()}`)
    if (res.ok) {
      const data = await res.json()
      setItems(data.items)
      setTotal(data.total)
    } else {
      const data = await res.json().catch(() => ({}))
      setBanner({ kind: "error", message: data.error || "Failed to load bins" })
    }
    setLoading(false)
  }, [page, query, health])

  useEffect(() => {
    load()
  }, [load])

  const onSearch = (e: React.FormEvent) => {
    e.preventDefault()
    setPage(1)
    setQuery(search.trim())
  }

  const changeHealth = async (bin: AdminBin, newStatus: string) => {
    if (newStatus === bin.healthStatus) return
    setBusyId(bin.id)
    const res = await apiFetch(`/api/admin/bins/${bin.id}`, {
      method: "PATCH",
      body: JSON.stringify({ healthStatus: newStatus }),
    })
    setBusyId(null)
    if (res.ok) {
      setBanner({ kind: "success", message: `Updated "${bin.name}".` })
      load()
    } else {
      const data = await res.json().catch(() => ({}))
      setBanner({ kind: "error", message: data.error || "Failed to update bin" })
    }
  }

  const submitTransfer = async () => {
    if (!transferBin || !transferEmail.trim()) return
    setTransferBusy(true)
    const res = await apiFetch(`/api/admin/bins/${transferBin.id}`, {
      method: "PATCH",
      body: JSON.stringify({ newOwnerEmail: transferEmail.trim() }),
    })
    setTransferBusy(false)
    if (res.ok) {
      setTransferBin(null)
      setTransferEmail("")
      setBanner({ kind: "success", message: "Ownership transferred." })
      load()
    } else {
      const data = await res.json().catch(() => ({}))
      setBanner({
        kind: "error",
        message: data.error || "Failed to transfer ownership",
      })
    }
  }

  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE))

  return (
    <div>
      <PageHeader
        title="Bins"
        description="Review compost bins, update health status, and transfer ownership."
      />

      {banner && (
        <Banner
          kind={banner.kind}
          message={banner.message}
          onDismiss={() => setBanner(null)}
        />
      )}

      <form onSubmit={onSearch} className="mb-4 flex flex-wrap gap-2">
        <div className="relative flex-1 min-w-[200px] max-w-sm">
          <Search className="absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground" />
          <Input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search by name, location, or owner"
            className="pl-9"
          />
        </div>
        <select
          value={health}
          onChange={(e) => {
            setHealth(e.target.value)
            setPage(1)
          }}
          className="h-9 rounded-md border border-input bg-background px-3 text-sm outline-none focus-visible:ring-2 focus-visible:ring-ring/50"
        >
          <option value="">All health</option>
          {HEALTH_OPTIONS.map((h) => (
            <option key={h} value={h}>
              {h}
            </option>
          ))}
        </select>
        <Button type="submit" variant="outline">
          Search
        </Button>
      </form>

      {loading ? (
        <CenteredSpinner />
      ) : items.length === 0 ? (
        <EmptyState message="No bins found." />
      ) : (
        <div className="overflow-hidden rounded-xl border bg-card">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b bg-muted/50 text-left text-xs uppercase tracking-wide text-muted-foreground">
                  <th className="px-4 py-3 font-medium">Bin</th>
                  <th className="px-4 py-3 font-medium">Owner</th>
                  <th className="px-4 py-3 font-medium">Members</th>
                  <th className="px-4 py-3 font-medium">Health</th>
                  <th className="px-4 py-3 font-medium">Created</th>
                  <th className="px-4 py-3 font-medium text-right">Actions</th>
                </tr>
              </thead>
              <tbody>
                {items.map((bin) => (
                  <tr key={bin.id} className="border-b last:border-0">
                    <td className="px-4 py-3">
                      <div className="font-medium text-foreground">
                        {bin.name}
                      </div>
                      {bin.location && (
                        <div className="text-xs text-muted-foreground">
                          {bin.location}
                        </div>
                      )}
                    </td>
                    <td className="px-4 py-3 text-muted-foreground">
                      {bin.ownerName}
                    </td>
                    <td className="px-4 py-3 text-muted-foreground">
                      {bin.memberCount}
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-2">
                        <HealthBadge status={bin.healthStatus} />
                        <select
                          value={
                            HEALTH_OPTIONS.includes(bin.healthStatus)
                              ? bin.healthStatus
                              : ""
                          }
                          disabled={busyId === bin.id}
                          onChange={(e) => changeHealth(bin, e.target.value)}
                          className="h-8 rounded-md border border-input bg-background px-2 text-xs outline-none focus-visible:ring-2 focus-visible:ring-ring/50 disabled:opacity-50"
                        >
                          <option value="" disabled>
                            Set…
                          </option>
                          {HEALTH_OPTIONS.map((h) => (
                            <option key={h} value={h}>
                              {h}
                            </option>
                          ))}
                        </select>
                      </div>
                    </td>
                    <td className="px-4 py-3 text-muted-foreground">
                      {formatDate(bin.createdAt)}
                    </td>
                    <td className="px-4 py-3 text-right">
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => {
                          setTransferBin(bin)
                          setTransferEmail("")
                        }}
                      >
                        <ArrowRightLeft className="size-4" />
                        Transfer
                      </Button>
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
            {total} bin{total === 1 ? "" : "s"} · Page {page} of {totalPages}
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
        open={!!transferBin}
        onClose={() => setTransferBin(null)}
        title="Transfer bin ownership"
      >
        <div className="space-y-4">
          <p className="text-sm text-muted-foreground">
            Transfer <span className="font-medium text-foreground">{transferBin?.name}</span>{" "}
            to another registered user by email.
          </p>
          <div>
            <label className="mb-1 block text-sm font-medium">
              New owner email
            </label>
            <Input
              type="email"
              value={transferEmail}
              onChange={(e) => setTransferEmail(e.target.value)}
              placeholder="person@example.com"
            />
          </div>
          <div className="flex justify-end gap-2 pt-2">
            <Button variant="outline" onClick={() => setTransferBin(null)}>
              Cancel
            </Button>
            <Button onClick={submitTransfer} disabled={transferBusy}>
              {transferBusy ? "Transferring…" : "Transfer"}
            </Button>
          </div>
        </div>
      </Modal>
    </div>
  )
}
