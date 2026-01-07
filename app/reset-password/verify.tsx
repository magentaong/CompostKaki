"use client"

import { useEffect } from "react"
import { useSearchParams } from "next/navigation"

// This page handles Supabase verify endpoint redirects
// When Supabase redirects here, it should have tokens in hash or query params
export default function VerifyPage() {
  const searchParams = useSearchParams()

  useEffect(() => {
    const hash = window.location.hash
    const urlParams = new URLSearchParams(window.location.search)
    const fullUrl = window.location.href

    console.log('🔐 [VERIFY PAGE] Page loaded')
    console.log('🔐 [VERIFY PAGE] Full URL:', fullUrl)
    console.log('🔐 [VERIFY PAGE] Hash:', hash)
    console.log('🔐 [VERIFY PAGE] Search params:', urlParams.toString())

    // Extract token from query params (Supabase verify endpoint)
    const token = urlParams.get('token') || urlParams.get('code')
    const type = urlParams.get('type') || 'recovery'
    const redirectTo = urlParams.get('redirect_to') || 'https://compostkaki.vercel.app/reset-password'

    // Check for tokens already in hash (Supabase redirected with tokens)
    if (hash && hash.includes('access_token')) {
      const hashParams = new URLSearchParams(hash.substring(1))
      const accessToken = hashParams.get('access_token')
      const refreshToken = hashParams.get('refresh_token')

      if (accessToken && refreshToken) {
        console.log('✅ [VERIFY PAGE] Found tokens in hash, redirecting to reset-password')
        const resetUrl = `${redirectTo}#type=recovery&access_token=${encodeURIComponent(accessToken)}&refresh_token=${encodeURIComponent(refreshToken)}`
        window.location.href = resetUrl
        return
      }
    }

    // Check for tokens in query params
    const accessToken = urlParams.get('access_token')
    const refreshToken = urlParams.get('refresh_token')
    if (accessToken && refreshToken) {
      console.log('✅ [VERIFY PAGE] Found tokens in query params, redirecting to reset-password')
      const resetUrl = `${redirectTo}#type=recovery&access_token=${encodeURIComponent(accessToken)}&refresh_token=${encodeURIComponent(refreshToken)}`
      window.location.href = resetUrl
      return
    }

    // If we have a token but no tokens yet, we need to call Supabase verify endpoint
    // This happens when user lands directly on Supabase's verify endpoint
    if (token) {
      console.log('🔐 [VERIFY PAGE] Token found, calling Supabase verify endpoint...')
      
      const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://tqpjrlwdgoctacfrbanf.supabase.co'
      const verifyUrl = `${supabaseUrl}/auth/v1/verify?token=${encodeURIComponent(token)}&type=${type}&redirect_to=${encodeURIComponent(redirectTo)}`

      console.log('🔐 [VERIFY PAGE] Calling:', verifyUrl)

      // Call Supabase verify endpoint - it should redirect
      window.location.href = verifyUrl
      return
    }

    // No token found - redirect to reset-password with error
    console.error('❌ [VERIFY PAGE] No token found')
    window.location.href = `${redirectTo}?error=missing_token&error_description=No verification token provided`
  }, [searchParams])

  return (
    <div style={{ 
      display: 'flex', 
      alignItems: 'center', 
      justifyContent: 'center', 
      minHeight: '100vh',
      backgroundColor: '#E6FFF3',
      padding: '20px'
    }}>
      <div style={{ 
        textAlign: 'center',
        backgroundColor: 'white',
        padding: '40px',
        borderRadius: '12px',
        boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
        maxWidth: '400px',
        width: '100%'
      }}>
        <div style={{ fontSize: '48px', marginBottom: '20px' }}>⏳</div>
        <h1 style={{ color: '#00796B', fontSize: '24px', marginBottom: '16px', fontWeight: 'bold' }}>CompostKaki</h1>
        <p style={{ color: '#00796B' }}>Verifying reset link...</p>
      </div>
    </div>
  )
}

