"use client"

import { createContext, useCallback, useContext, useEffect, useState } from "react"
import { usePathname, useRouter } from "next/navigation"
import Link from "next/link"
import { supabase } from "@/lib/supabaseClient"
import { apiFetch } from "@/lib/apiFetch"
import {
  LayoutDashboard,
  Users,
  Sprout,
  ScrollText,
  LogOut,
  Leaf,
  ShieldCheck,
  ArrowLeft,
} from "lucide-react"
import { cn } from "@/lib/utils"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"

type AdminMe = { id: string; email: string; role: "admin" | "super_admin" }

const AdminContext = createContext<AdminMe | null>(null)

export function useAdmin(): AdminMe {
  const ctx = useContext(AdminContext)
  if (!ctx) throw new Error("useAdmin must be used within AdminShell")
  return ctx
}

const NAV = [
  { href: "/admin", label: "Overview", icon: LayoutDashboard },
  { href: "/admin/users", label: "Users", icon: Users },
  { href: "/admin/bins", label: "Bins", icon: Sprout },
  { href: "/admin/audit", label: "Activity Log", icon: ScrollText },
]

export function AdminShell({ children }: { children: React.ReactNode }) {
  const router = useRouter()
  const pathname = usePathname()
  const [state, setState] = useState<
    | { status: "loading" }
    | { status: "login" }
    | { status: "denied" }
    | { status: "ready"; me: AdminMe }
  >({ status: "loading" })

  const runCheck = useCallback(async () => {
    setState({ status: "loading" })
    const {
      data: { session },
    } = await supabase.auth.getSession()
    if (!session) {
      setState({ status: "login" })
      return
    }
    const res = await apiFetch("/api/admin/me")
    if (res.ok) {
      const me = await res.json()
      setState({ status: "ready", me })
    } else {
      setState({ status: "denied" })
    }
  }, [])

  useEffect(() => {
    runCheck()
  }, [runCheck])

  const signOut = async () => {
    await supabase.auth.signOut()
    setState({ status: "login" })
  }

  if (state.status === "login") {
    return <AdminLogin onSuccess={runCheck} />
  }

  if (state.status === "loading") {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background">
        <div className="flex flex-col items-center gap-3 text-muted-foreground">
          <Leaf className="size-7 text-primary animate-pulse" />
          <span className="text-sm">Loading admin portal…</span>
        </div>
      </div>
    )
  }

  if (state.status === "denied") {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background px-4">
        <div className="w-full max-w-sm bg-card rounded-xl border p-8 text-center">
          <div className="mx-auto mb-4 flex size-12 items-center justify-center rounded-full bg-destructive/40">
            <ShieldCheck className="size-6 text-[#6D2222]" />
          </div>
          <h1 className="text-lg font-semibold text-foreground">
            Admin access only
          </h1>
          <p className="mt-2 text-sm text-muted-foreground">
            Your account does not have permission to view the CompostKaki admin
            portal.
          </p>
          <div className="mt-6 flex flex-col gap-2">
            <Link
              href="/main"
              className="inline-flex h-9 items-center justify-center rounded-md bg-primary px-4 text-sm font-medium text-primary-foreground hover:bg-primary/90"
            >
              Go to app
            </Link>
            <button
              onClick={signOut}
              className="inline-flex h-9 items-center justify-center rounded-md px-4 text-sm font-medium text-muted-foreground hover:bg-muted"
            >
              Sign out
            </button>
          </div>
        </div>
      </div>
    )
  }

  const { me } = state
  const initials = me.email ? me.email[0].toUpperCase() : "A"

  return (
    <AdminContext.Provider value={me}>
      <div className="min-h-screen bg-background md:flex">
        {/* Sidebar (desktop) */}
        <aside className="hidden md:flex md:w-64 md:flex-col md:fixed md:inset-y-0 border-r bg-sidebar">
          <div className="flex items-center gap-2 px-6 h-16 border-b">
            <div className="flex size-8 items-center justify-center rounded-lg bg-primary">
              <Leaf className="size-4 text-primary-foreground" />
            </div>
            <div className="leading-tight">
              <div className="text-sm font-semibold text-foreground">
                CompostKaki
              </div>
              <div className="text-[11px] font-medium text-primary">
                Admin Portal
              </div>
            </div>
          </div>
          <nav className="flex-1 px-3 py-4 space-y-1">
            {NAV.map((item) => {
              const active =
                item.href === "/admin"
                  ? pathname === "/admin"
                  : pathname.startsWith(item.href)
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  className={cn(
                    "flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-colors",
                    active
                      ? "bg-primary text-primary-foreground"
                      : "text-foreground hover:bg-accent"
                  )}
                >
                  <item.icon className="size-4" />
                  {item.label}
                </Link>
              )
            })}
          </nav>
          <div className="border-t p-3">
            <div className="flex items-center gap-3 px-2 py-2">
              <div className="flex size-9 items-center justify-center rounded-full bg-secondary text-secondary-foreground text-sm font-semibold">
                {initials}
              </div>
              <div className="min-w-0 flex-1">
                <div className="truncate text-sm font-medium text-foreground">
                  {me.email}
                </div>
                <div className="text-[11px] font-medium text-primary">
                  {me.role === "super_admin" ? "Super Admin" : "Admin"}
                </div>
              </div>
            </div>
            <button
              onClick={signOut}
              className="mt-1 flex w-full items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium text-muted-foreground hover:bg-muted"
            >
              <LogOut className="size-4" />
              Sign out
            </button>
          </div>
        </aside>

        {/* Mobile top bar */}
        <header className="md:hidden sticky top-0 z-10 border-b bg-sidebar">
          <div className="flex items-center justify-between px-4 h-14">
            <div className="flex items-center gap-2">
              <div className="flex size-7 items-center justify-center rounded-lg bg-primary">
                <Leaf className="size-4 text-primary-foreground" />
              </div>
              <span className="text-sm font-semibold">CompostKaki Admin</span>
            </div>
            <button
              onClick={signOut}
              className="text-muted-foreground hover:text-foreground"
              aria-label="Sign out"
            >
              <LogOut className="size-5" />
            </button>
          </div>
          <nav className="flex gap-1 overflow-x-auto px-2 pb-2">
            {NAV.map((item) => {
              const active =
                item.href === "/admin"
                  ? pathname === "/admin"
                  : pathname.startsWith(item.href)
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  className={cn(
                    "flex items-center gap-2 rounded-lg px-3 py-1.5 text-sm font-medium whitespace-nowrap",
                    active
                      ? "bg-primary text-primary-foreground"
                      : "text-foreground hover:bg-accent"
                  )}
                >
                  <item.icon className="size-4" />
                  {item.label}
                </Link>
              )
            })}
          </nav>
        </header>

        <main className="flex-1 md:pl-64">
          <div className="mx-auto max-w-6xl px-4 py-6 md:px-8 md:py-8">
            {children}
          </div>
        </main>
      </div>
    </AdminContext.Provider>
  )
}

function AdminLogin({ onSuccess }: { onSuccess: () => void }) {
  const [email, setEmail] = useState("")
  const [password, setPassword] = useState("")
  const [error, setError] = useState("")
  const [loading, setLoading] = useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setError("")
    const { error: authError } = await supabase.auth.signInWithPassword({
      email,
      password,
    })
    if (authError) {
      setError(authError.message)
      setLoading(false)
      return
    }
    onSuccess()
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-[#0F3D38] px-4 py-10">
      <div className="w-full max-w-md">
        <div className="rounded-2xl border border-white/10 bg-white p-8 shadow-2xl sm:p-10">
          <div className="flex flex-col items-center text-center">
            <div className="mb-4 flex size-14 items-center justify-center rounded-2xl bg-[#00796B] shadow-sm">
              <ShieldCheck className="size-7 text-white" />
            </div>
            <h1 className="text-2xl font-bold tracking-tight text-[#0F3D38]">
              Admin Portal
            </h1>
            <p className="mt-1 text-sm text-gray-500">
              Sign in to manage CompostKaki
            </p>
          </div>

          <form onSubmit={handleSubmit} className="mt-8 space-y-4">
            <div className="space-y-1.5">
              <Label htmlFor="admin-email">Email</Label>
              <Input
                id="admin-email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="admin@example.com"
                required
                autoFocus
                className="h-11"
              />
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="admin-password">Password</Label>
              <Input
                id="admin-password"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Enter your password"
                required
                className="h-11"
              />
            </div>

            {error && (
              <div className="rounded-lg bg-red-50 px-3 py-2 text-sm text-red-600">
                {error}
              </div>
            )}

            <Button
              type="submit"
              disabled={loading}
              className="h-11 w-full bg-[#00796B] text-base font-semibold text-white transition hover:bg-[#005A4B]"
            >
              {loading ? "Signing in…" : "Sign in to Admin Portal"}
            </Button>
          </form>

          <div className="mt-8 border-t border-gray-100 pt-5 text-center">
            <Link
              href="/"
              className="inline-flex items-center gap-1 text-xs font-medium text-gray-400 transition hover:text-[#00796B]"
            >
              <ArrowLeft className="size-3.5" />
              Back to app
            </Link>
          </div>
        </div>

        <p className="mt-6 text-center text-xs text-white/50">
          Restricted access · Authorized administrators only
        </p>
      </div>
    </div>
  )
}
