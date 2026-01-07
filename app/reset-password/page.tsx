"use client"

import { useEffect, useState } from "react"
import { useRouter, useSearchParams } from "next/navigation"

export default function ResetPasswordPage() {
  const router = useRouter()
  const searchParams = useSearchParams()
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    // This page receives tokens in hash from Supabase verify endpoint
    // It immediately redirects to the app
    
    const hash = window.location.hash
    const fullUrl = window.location.href
    const urlParams = new URLSearchParams(window.location.search)
    
    console.log('🔄 [REDIRECT PAGE] Page loaded')
    console.log('🔄 [REDIRECT PAGE] Full URL:', fullUrl)
    console.log('🔄 [REDIRECT PAGE] Hash:', hash)
    console.log('🔄 [REDIRECT PAGE] Search params:', urlParams.toString())
    
    // Check if we're being called from Supabase verify endpoint (has token param)
    const token = urlParams.get('token') || urlParams.get('code')
    if (token && !hash) {
      // Supabase verify endpoint redirected here but didn't include tokens in hash
      // This means Supabase's redirect didn't work properly
      // Let's manually call Supabase verify endpoint
      console.log('🔐 [REDIRECT PAGE] Token found but no hash - calling Supabase verify...')
      const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://tqpjrlwdgoctacfrbanf.supabase.co'
      const type = urlParams.get('type') || 'recovery'
      const verifyUrl = `${supabaseUrl}/auth/v1/verify?token=${encodeURIComponent(token)}&type=${type}&redirect_to=${encodeURIComponent(window.location.origin + window.location.pathname)}`
      
      // Use fetch to call verify endpoint and get the redirect location
      fetch(verifyUrl, { 
        method: 'GET',
        redirect: 'manual'
      })
      .then(response => {
        if (response.status >= 300 && response.status < 400) {
          const location = response.headers.get('location')
          if (location) {
            console.log('✅ [REDIRECT PAGE] Supabase redirected to:', location)
            window.location.href = location
            return
          }
        }
        // If no redirect, try direct redirect
        window.location.href = verifyUrl
      })
      .catch(err => {
        console.error('❌ [REDIRECT PAGE] Error calling verify:', err)
        // Fallback: try direct redirect
        window.location.href = verifyUrl
      })
      return
    }
    
    // Check for error responses first
    const errorParam = urlParams.get('error') || new URLSearchParams(hash.substring(1)).get('error')
    const errorCode = urlParams.get('error_code') || new URLSearchParams(hash.substring(1)).get('error_code')
    const errorDescription = urlParams.get('error_description') || new URLSearchParams(hash.substring(1)).get('error_description')
    
    if (errorParam) {
      console.error('❌ [ERROR] Error detected:', errorParam, errorCode, errorDescription)
      
      let errorMessage = 'Password reset link is invalid or has expired.'
      if (errorCode === 'otp_expired' || errorParam.includes('expired')) {
        errorMessage = 'This password reset link has expired. Please request a new password reset.'
      } else if (errorCode === 'access_denied' || errorParam.includes('denied')) {
        errorMessage = 'Access denied. The reset link may have expired or already been used.'
      } else if (errorDescription) {
        errorMessage = decodeURIComponent(errorDescription.replace(/\+/g, ' '))
      }
      
      setError(errorMessage)
      return
    }
    
    // Check if tokens are in hash (normal Supabase flow)
    // Supabase PKCE flow redirects with tokens in hash: #access_token=...&refresh_token=...
    if (hash && hash.length > 1) {
      // Check if hash contains access_token (Supabase tokens)
      const hashParams = new URLSearchParams(hash.substring(1))
      const accessToken = hashParams.get('access_token')
      const refreshToken = hashParams.get('refresh_token')
      
      if (accessToken && refreshToken) {
        // Supabase redirected with tokens in hash - redirect to app
        const deepLink = `compostkaki://reset-password#type=recovery&access_token=${encodeURIComponent(accessToken)}&refresh_token=${encodeURIComponent(refreshToken)}`
        
        console.log('🔄 [REDIRECT] Found Supabase tokens in hash, redirecting to app')
        console.log('🔄 [REDIRECT] Deep link:', deepLink)
        
        // Try immediate redirect
        try {
          window.location.href = deepLink
          console.log('✅ [REDIRECT] window.location.href executed')
          return
        } catch (e) {
          console.error('❌ [REDIRECT] Error with window.location.href:', e)
        }
      } else {
        // Hash exists but no tokens - might be our format or error
        const deepLink = `compostkaki://reset-password${hash}`
        console.log('🔄 [REDIRECT] Hash exists but no Supabase tokens, redirecting as-is:', deepLink)
        try {
          window.location.href = deepLink
          return
        } catch (e) {
          console.error('❌ [REDIRECT] Error:', e)
        }
      }
    }
    
    // Also check query params for tokens (some Supabase flows use query params)
    const accessTokenParam = urlParams.get('access_token')
    const refreshTokenParam = urlParams.get('refresh_token')
    if (accessTokenParam && refreshTokenParam) {
      const deepLink = `compostkaki://reset-password#type=recovery&access_token=${encodeURIComponent(accessTokenParam)}&refresh_token=${encodeURIComponent(refreshTokenParam)}`
      console.log('🔄 [REDIRECT] Found tokens in query params, redirecting to app')
      try {
        window.location.href = deepLink
        return
      } catch (e) {
        console.error('❌ [REDIRECT] Error:', e)
      }
    }
    
    // No hash or tokens found - show error
    console.log('⚠️ [REDIRECT PAGE] No hash or tokens found')
    setError('No valid reset token found. Please request a new password reset.')
    
    // Redirect to home after showing error
    setTimeout(() => {
      router.push('/')
    }, 3000)
  }, [router, searchParams])

  // Show loading state or error
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
        {error ? (
          <>
            <div style={{ 
              fontSize: '48px', 
              marginBottom: '20px',
              color: '#d32f2f'
            }}>⚠️</div>
            <h1 style={{ 
              color: '#00796B', 
              fontSize: '24px',
              marginBottom: '16px',
              fontWeight: 'bold'
            }}>CompostKaki</h1>
            <div style={{
              backgroundColor: '#ffebee',
              border: '1px solid #ef5350',
              borderRadius: '8px',
              padding: '16px',
              marginBottom: '24px'
            }}>
              <p style={{ color: '#d32f2f', margin: 0 }}>{error}</p>
            </div>
            <button
              onClick={() => router.push('/')}
              style={{
                backgroundColor: '#00796B',
                color: 'white',
                border: 'none',
                borderRadius: '8px',
                padding: '12px 24px',
                fontSize: '16px',
                cursor: 'pointer',
                fontWeight: 'bold'
              }}
            >
              Back to Login
            </button>
          </>
        ) : (
          <>
            <div style={{ fontSize: '48px', marginBottom: '20px' }}>🔗</div>
            <h1 style={{ color: '#00796B', fontSize: '24px', marginBottom: '16px', fontWeight: 'bold' }}>CompostKaki</h1>
            <p style={{ color: '#00796B' }}>Opening app...</p>
          </>
        )}
      </div>
    </div>
  )
}
