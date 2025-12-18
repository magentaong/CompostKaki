"use client"

import { useState, useEffect } from "react"
import { useRouter, useSearchParams } from "next/navigation"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { supabase } from "@/lib/supabaseClient"

export default function ResetPasswordPage() {
  const router = useRouter()
  const searchParams = useSearchParams()
  const [password, setPassword] = useState("")
  const [confirmPassword, setConfirmPassword] = useState("")
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState("")
  const [success, setSuccess] = useState(false)
  const [isValidToken, setIsValidToken] = useState<boolean | null>(null)

  useEffect(() => {
    // Check if we have a valid recovery session
    const checkRecoverySession = async () => {
      try {
        // Check if URL has recovery token in hash (Supabase adds this to the URL hash)
        const hashParams = new URLSearchParams(window.location.hash.substring(1))
        const type = hashParams.get('type')
        const accessToken = hashParams.get('access_token')
        const refreshToken = hashParams.get('refresh_token')
        
        if (type === 'recovery' && accessToken && refreshToken) {
          // Exchange the recovery token for a session
          const { data: { session }, error: exchangeError } = await supabase.auth.setSession({
            access_token: accessToken,
            refresh_token: refreshToken,
          })
          
          if (exchangeError || !session) {
            setIsValidToken(false)
            setError("Invalid or expired reset link. Please request a new one.")
          } else {
            setIsValidToken(true)
            // Clear the hash from URL for security
            window.history.replaceState(null, '', window.location.pathname)
          }
        } else {
          // Check if we already have a valid session
          const { data: { session } } = await supabase.auth.getSession()
          if (session) {
            setIsValidToken(true)
          } else {
            setIsValidToken(false)
            setError("No valid reset token found. Please request a new password reset.")
          }
        }
      } catch (e) {
        setIsValidToken(false)
        setError("Error validating reset link. Please try again.")
      }
    }

    checkRecoverySession()
  }, [])

  const handleResetPassword = async (e: React.FormEvent) => {
    e.preventDefault()
    setError("")

    // Validation
    if (!password) {
      setError("Please enter a new password")
      return
    }

    if (password.length < 6) {
      setError("Password must be at least 6 characters long")
      return
    }

    if (password !== confirmPassword) {
      setError("Passwords do not match")
      return
    }

    setIsLoading(true)

    try {
      // Update password
      const { error: updateError } = await supabase.auth.updateUser({
        password: password,
      })

      if (updateError) {
        setError(updateError.message || "Failed to update password. Please try again.")
        setIsLoading(false)
        return
      }

      // Success!
      setSuccess(true)
      setIsLoading(false)

      // Redirect to login after 2 seconds
      setTimeout(() => {
        router.push("/")
      }, 2000)
    } catch (e: any) {
      setError(e.message || "An unexpected error occurred. Please try again.")
      setIsLoading(false)
    }
  }

  if (isValidToken === null) {
    // Still checking token validity
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-[#E6FFF3] to-[#F3F3F3]">
        <div className="w-full max-w-md bg-white rounded-xl shadow-lg p-8 flex flex-col items-center">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-[#00796B] mb-4"></div>
          <p className="text-[#00796B]">Validating reset link...</p>
        </div>
      </div>
    )
  }

  if (isValidToken === false) {
    // Invalid token
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-[#E6FFF3] to-[#F3F3F3]">
        <div className="w-full max-w-md bg-white rounded-xl shadow-lg p-8 flex flex-col items-center">
          <img src="/favicon.ico" alt="Logo" className="w-8 h-8 mb-2" />
          <h1 className="text-3xl font-bold text-[#00796B] mb-2">CompostKaki</h1>
          
          <div className="w-full mt-6">
            <div className="text-sm text-red-600 bg-red-50 px-4 py-3 rounded mb-4">
              {error || "Invalid or expired reset link"}
            </div>
            
            <Button
              onClick={() => router.push("/")}
              className="w-full bg-[#00796B] text-white hover:bg-[#005A4B] transition font-semibold"
            >
              Back to Login
            </Button>
          </div>
        </div>
      </div>
    )
  }

  if (success) {
    // Success state
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-[#E6FFF3] to-[#F3F3F3]">
        <div className="w-full max-w-md bg-white rounded-xl shadow-lg p-8 flex flex-col items-center">
          <img src="/favicon.ico" alt="Logo" className="w-8 h-8 mb-2" />
          <h1 className="text-3xl font-bold text-[#00796B] mb-2">CompostKaki</h1>
          
          <div className="w-full mt-6 text-center">
            <div className="text-green-600 bg-green-50 px-4 py-3 rounded mb-4">
              ✓ Password reset successfully! Redirecting to login...
            </div>
          </div>
        </div>
      </div>
    )
  }

  // Show password reset form
  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-[#E6FFF3] to-[#F3F3F3]">
      <div className="w-full max-w-md bg-white rounded-xl shadow-lg p-8 flex flex-col items-center">
        <img src="/favicon.ico" alt="Logo" className="w-8 h-8 mb-2" />
        <h1 className="text-3xl font-bold text-[#00796B] mb-2">CompostKaki</h1>
        <div className="text-[#00796B] text-base mb-6 font-medium">Reset your password</div>

        <form onSubmit={handleResetPassword} className="w-full space-y-4">
          <div>
            <Label htmlFor="password">New Password</Label>
            <Input
              id="password"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              minLength={6}
              autoFocus
              placeholder="Enter your new password"
            />
            <p className="text-xs text-gray-500 mt-1">Must be at least 6 characters</p>
          </div>

          <div>
            <Label htmlFor="confirmPassword">Confirm New Password</Label>
            <Input
              id="confirmPassword"
              type="password"
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              required
              minLength={6}
              placeholder="Confirm your new password"
            />
          </div>

          {error && (
            <div className="text-sm text-red-600 bg-red-50 px-4 py-3 rounded">
              {error}
            </div>
          )}

          <Button
            type="submit"
            className="w-full bg-[#00796B] text-white hover:bg-[#005A4B] transition font-semibold"
            disabled={isLoading}
          >
            {isLoading ? "Resetting Password..." : "Reset Password"}
          </Button>

          <Button
            type="button"
            variant="outline"
            onClick={() => router.push("/")}
            className="w-full"
            disabled={isLoading}
          >
            Back to Login
          </Button>
        </form>
      </div>
    </div>
  )
}

