"use client"

import { useEffect, useState } from "react"
import { apiFetch } from "@/lib/apiFetch"
import { useAdmin } from "@/components/admin/AdminShell"
import { PageHeader, CenteredSpinner } from "@/components/admin/ui"
import { Card } from "@/components/ui/card"
import { Users, Sprout, ClipboardList, ListChecks, ShieldCheck } from "lucide-react"

type Stats = {
  totalUsers: number
  totalBins: number
  totalLogs: number
  totalTasks: number
  totalAdmins: number
  binsByHealth: { healthy: number; needsAttention: number; critical: number }
}

const HEALTH_META = [
  { key: "healthy", label: "Healthy", color: "bg-[#CBE7B5]" },
  { key: "needsAttention", label: "Needs Attention", color: "bg-[#F0E1A6]" },
  { key: "critical", label: "Critical", color: "bg-[#E8B5B5]" },
] as const

function StatCard({
  icon: Icon,
  label,
  value,
}: {
  icon: React.ComponentType<{ className?: string }>
  label: string
  value: number | string
}) {
  return (
    <Card className="gap-0 py-5">
      <div className="flex items-center gap-4 px-5">
        <div className="flex size-11 items-center justify-center rounded-xl bg-primary/10">
          <Icon className="size-5 text-primary" />
        </div>
        <div>
          <div className="text-2xl font-semibold text-foreground">{value}</div>
          <div className="text-sm text-muted-foreground">{label}</div>
        </div>
      </div>
    </Card>
  )
}

export default function AdminOverviewPage() {
  const me = useAdmin()
  const [stats, setStats] = useState<Stats | null>(null)
  const [error, setError] = useState("")

  useEffect(() => {
    ;(async () => {
      const res = await apiFetch("/api/admin/stats")
      if (res.ok) {
        setStats(await res.json())
      } else {
        const data = await res.json().catch(() => ({}))
        setError(data.error || "Failed to load statistics")
      }
    })()
  }, [])

  const firstName = me.email.split("@")[0]

  return (
    <div>
      <PageHeader
        title={`Welcome back, ${firstName}`}
        description="A snapshot of the CompostKaki community."
      />

      {error && (
        <div className="mb-4 rounded-lg bg-destructive/40 px-4 py-3 text-sm text-[#6D2222]">
          {error}
        </div>
      )}

      {!stats && !error ? (
        <CenteredSpinner />
      ) : stats ? (
        <div className="space-y-6">
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
            <StatCard icon={Users} label="Total users" value={stats.totalUsers} />
            <StatCard icon={Sprout} label="Compost bins" value={stats.totalBins} />
            <StatCard
              icon={ClipboardList}
              label="Activities logged"
              value={stats.totalLogs}
            />
            <StatCard
              icon={ListChecks}
              label="Tasks created"
              value={stats.totalTasks}
            />
            <StatCard
              icon={ShieldCheck}
              label="Administrators"
              value={stats.totalAdmins}
            />
          </div>

          <Card className="py-6">
            <div className="px-6">
              <h2 className="text-base font-semibold text-foreground">
                Bin health overview
              </h2>
              <p className="mt-1 text-sm text-muted-foreground">
                Distribution of bins by current health status.
              </p>
              <div className="mt-5 space-y-4">
                {HEALTH_META.map((h) => {
                  const value = stats.binsByHealth[h.key]
                  const pct =
                    stats.totalBins > 0
                      ? Math.round((value / stats.totalBins) * 100)
                      : 0
                  return (
                    <div key={h.key}>
                      <div className="mb-1 flex items-center justify-between text-sm">
                        <span className="text-foreground">{h.label}</span>
                        <span className="text-muted-foreground">
                          {value} ({pct}%)
                        </span>
                      </div>
                      <div className="h-2 w-full overflow-hidden rounded-full bg-muted">
                        <div
                          className={`h-full rounded-full ${h.color}`}
                          style={{ width: `${pct}%` }}
                        />
                      </div>
                    </div>
                  )
                })}
              </div>
            </div>
          </Card>
        </div>
      ) : null}
    </div>
  )
}
