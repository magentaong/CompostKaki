"use client"

import { cn } from "@/lib/utils"
import { Loader2, X } from "lucide-react"

export function Modal({
  open,
  onClose,
  title,
  children,
}: {
  open: boolean
  onClose: () => void
  title: string
  children: React.ReactNode
}) {
  if (!open) return null
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div
        className="absolute inset-0 bg-black/40"
        onClick={onClose}
        aria-hidden
      />
      <div className="relative z-10 w-full max-w-md rounded-xl border bg-card p-6 shadow-lg">
        <div className="mb-4 flex items-center justify-between">
          <h2 className="text-base font-semibold text-foreground">{title}</h2>
          <button
            onClick={onClose}
            className="text-muted-foreground hover:text-foreground"
            aria-label="Close"
          >
            <X className="size-5" />
          </button>
        </div>
        {children}
      </div>
    </div>
  )
}

export function Banner({
  kind,
  message,
  onDismiss,
}: {
  kind: "success" | "error"
  message: string
  onDismiss?: () => void
}) {
  return (
    <div
      className={cn(
        "mb-4 flex items-center justify-between rounded-lg px-4 py-3 text-sm",
        kind === "success"
          ? "bg-accent text-accent-foreground"
          : "bg-destructive/40 text-[#6D2222]"
      )}
    >
      <span>{message}</span>
      {onDismiss && (
        <button onClick={onDismiss} aria-label="Dismiss">
          <X className="size-4" />
        </button>
      )}
    </div>
  )
}

export function PageHeader({
  title,
  description,
  action,
}: {
  title: string
  description?: string
  action?: React.ReactNode
}) {
  return (
    <div className="mb-6 flex flex-wrap items-start justify-between gap-3">
      <div>
        <h1 className="text-2xl font-semibold tracking-tight text-foreground">
          {title}
        </h1>
        {description && (
          <p className="mt-1 text-sm text-muted-foreground">{description}</p>
        )}
      </div>
      {action}
    </div>
  )
}

export function Spinner({ className }: { className?: string }) {
  return (
    <Loader2 className={cn("size-5 animate-spin text-primary", className)} />
  )
}

export function CenteredSpinner() {
  return (
    <div className="flex items-center justify-center py-16">
      <Spinner />
    </div>
  )
}

export function EmptyState({ message }: { message: string }) {
  return (
    <div className="rounded-xl border border-dashed bg-card/50 py-14 text-center text-sm text-muted-foreground">
      {message}
    </div>
  )
}

export function HealthBadge({ status }: { status: string }) {
  const map: Record<string, string> = {
    Healthy: "bg-accent text-accent-foreground",
    "Needs Attention": "bg-secondary text-secondary-foreground",
    Critical: "bg-destructive text-[#6D2222]",
  }
  const cls = map[status] || "bg-muted text-muted-foreground"
  return (
    <span
      className={cn(
        "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium",
        cls
      )}
    >
      {status}
    </span>
  )
}

export function RoleBadge({ role }: { role: string }) {
  if (role === "super_admin") {
    return (
      <span className="inline-flex items-center rounded-full bg-primary px-2.5 py-0.5 text-xs font-medium text-primary-foreground">
        Super Admin
      </span>
    )
  }
  if (role === "admin") {
    return (
      <span className="inline-flex items-center rounded-full bg-primary/15 px-2.5 py-0.5 text-xs font-medium text-primary">
        Admin
      </span>
    )
  }
  return (
    <span className="inline-flex items-center rounded-full bg-muted px-2.5 py-0.5 text-xs font-medium text-muted-foreground">
      User
    </span>
  )
}

export function StatusBadge({ suspended }: { suspended: boolean }) {
  return suspended ? (
    <span className="inline-flex items-center rounded-full bg-destructive px-2.5 py-0.5 text-xs font-medium text-[#6D2222]">
      Suspended
    </span>
  ) : (
    <span className="inline-flex items-center rounded-full bg-accent px-2.5 py-0.5 text-xs font-medium text-accent-foreground">
      Active
    </span>
  )
}
