"use client"

import { useEffect, useState } from "react"
import { useRouter, useSearchParams } from "next/navigation"

export default function ResetPasswordPage() {
  const router = useRouter()
  const searchParams = useSearchParams()
  const [error, setError] = useState<string | null>(null)
  const [tokensReady, setTokensReady] = useState(false)
  const [deepLink, setDeepLink] = useState<string | null>(null)
  const [showFallback, setShowFallback] = useState(false)
  const [triedAutoOpen, setTriedAutoOpen] = useState(false)
  
  // Detect iOS and in-app browsers
  const [isIOS, setIsIOS] = useState(false)
  const [isInAppBrowser, setIsInAppBrowser] = useState(false)
  
  useEffect(() => {
    if (typeof window !== 'undefined') {
      const ua = navigator.userAgent || ''
      const ios = /iPhone|iPad|iPod/i.test(ua)
      const inApp = /GSA|FBAN|FBAV|Instagram|Line|Twitter|Snapchat|MicroMessenger|wv/i.test(ua)
      setIsIOS(ios)
      setIsInAppBrowser(inApp)
    }
  }, [])

  useEffect(() => {
    const hash = window.location.hash
    const fullUrl = window.location.href
    const urlParams = new URLSearchParams(window.location.search)
    
    console.log('🔄 [RESET PASSWORD PAGE] Page loaded')
    console.log('🔄 [RESET PASSWORD PAGE] Full URL:', fullUrl)
    console.log('🔄 [RESET PASSWORD PAGE] Hash:', hash)
    console.log('🔄 [RESET PASSWORD PAGE] Search params:', urlParams.toString())
    
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
    
    // Check if we have a token but no hash - need to verify it
    const token = urlParams.get('token') || urlParams.get('code')
    if (token && !hash) {
      console.log('🔐 [RESET PASSWORD PAGE] Token found but no hash - calling verify API...')
      const type = urlParams.get('type') || 'recovery'
      
      // Redirect to verify API - it will redirect back with tokens in hash
      const verifyApiUrl = `https://compostkaki.vercel.app/api/auth/verify-token?token=${encodeURIComponent(token)}&type=${type}`
      window.location.href = verifyApiUrl
      return
    }
    
    // Check if tokens are in hash (ready to use)
    if (hash && hash.length > 1) {
      const hashParams = new URLSearchParams(hash.substring(1))
      const accessToken = hashParams.get('access_token')
      const refreshToken = hashParams.get('refresh_token')
      
      if (accessToken && refreshToken) {
        // Tokens ready! Create deep link but don't auto-redirect immediately
        const link = `compostkaki://reset-password#type=recovery&access_token=${encodeURIComponent(accessToken)}&refresh_token=${encodeURIComponent(refreshToken)}`
        setDeepLink(link)
        setTokensReady(true)
        
        // For iOS in-app browsers, don't auto-try (iOS blocks it)
        // Show button immediately instead
        if (isIOS && isInAppBrowser) {
          console.log('📱 [RESET PASSWORD PAGE] iOS in-app browser detected - showing button immediately')
          setShowFallback(true)
          return
        }
        
        // For other browsers, try auto-opening after a short delay
        // iOS Safari sometimes blocks immediate redirects
        const timeoutId = setTimeout(() => {
          setTriedAutoOpen(true)
          try {
            console.log('🔄 [RESET PASSWORD PAGE] Attempting auto-open...')
            window.location.href = link
          } catch (e) {
            console.error('❌ [RESET PASSWORD PAGE] Error opening app:', e)
            setShowFallback(true)
          }
        }, 300) // Small delay helps with iOS Safari
        
        // Show fallback after 2 seconds if app doesn't open
        setTimeout(() => {
          setShowFallback(true)
        }, 2000)
        
        return () => clearTimeout(timeoutId)
      }
    }
    
    // Check query params for tokens
    const accessTokenParam = urlParams.get('access_token')
    const refreshTokenParam = urlParams.get('refresh_token')
    if (accessTokenParam && refreshTokenParam) {
      const link = `compostkaki://reset-password#type=recovery&access_token=${encodeURIComponent(accessTokenParam)}&refresh_token=${encodeURIComponent(refreshTokenParam)}`
      setDeepLink(link)
      setTokensReady(true)
      setShowFallback(true) // Show button immediately for query params
      return
    }
    
    // No tokens found
    console.log('⚠️ [RESET PASSWORD PAGE] No tokens found')
    setError('No valid reset token found. Please request a new password reset.')
  }, [searchParams])

  const handleOpenApp = () => {
    if (deepLink) {
      console.log('🔗 [RESET PASSWORD PAGE] User tapped to open app')
      window.location.href = deepLink
      
      // Show fallback after a delay if app doesn't open
      setTimeout(() => {
        setShowFallback(true)
      }, 1500)
    }
  }

  const handleOpenInSafari = () => {
    // Open the deep link in Safari (iOS) or default browser
    if (deepLink) {
      window.open(deepLink, '_blank')
    }
  }

  const handleContinueOnWeb = () => {
    // For now, redirect to home page
    // In future, could implement web-based password reset
    router.push('/')
  }

  // Show error state
  if (error) {
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
              fontWeight: 'bold',
              width: '100%'
            }}
          >
            Back to Login
          </button>
        </div>
      </div>
    )
  }

  // Show loading state while verifying token
  if (!tokensReady) {
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

  // Show main page with button
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
        <div style={{ fontSize: '64px', marginBottom: '20px' }}>🔐</div>
        <h1 style={{ 
          color: '#00796B', 
          fontSize: '28px',
          marginBottom: '12px',
          fontWeight: 'bold'
        }}>Reset Your Password</h1>
        <p style={{ 
          color: '#666',
          fontSize: '16px',
          marginBottom: '32px',
          lineHeight: '1.5'
        }}>
          {isIOS && isInAppBrowser 
            ? "You're in an in-app browser. Tap the button below to open the CompostKaki app and reset your password."
            : triedAutoOpen
            ? "If the app didn't open automatically, tap the button below:"
            : "Tap the button below to open the CompostKaki app and reset your password."
          }
        </p>
        
        {isIOS && isInAppBrowser && (
          <div style={{
            backgroundColor: '#fff3cd',
            border: '1px solid #ffc107',
            borderRadius: '8px',
            padding: '12px',
            marginBottom: '24px',
            fontSize: '14px',
            color: '#856404'
          }}>
            <strong>💡 Tip:</strong> For best results, tap <strong>⋯</strong> → <strong>Open in Safari</strong>, then tap the button below.
          </div>
        )}

        {/* Main button - Open App */}
        <button
          onClick={handleOpenApp}
          style={{
            backgroundColor: '#00796B',
            color: 'white',
            border: 'none',
            borderRadius: '12px',
            padding: '16px 32px',
            fontSize: '18px',
            cursor: 'pointer',
            fontWeight: 'bold',
            width: '100%',
            marginBottom: '16px',
            boxShadow: '0 4px 6px rgba(0,0,0,0.1)',
            transition: 'all 0.2s'
          }}
          onMouseOver={(e) => {
            e.currentTarget.style.backgroundColor = '#005A4B'
            e.currentTarget.style.transform = 'translateY(-2px)'
          }}
          onMouseOut={(e) => {
            e.currentTarget.style.backgroundColor = '#00796B'
            e.currentTarget.style.transform = 'translateY(0)'
          }}
        >
          📱 Tap to Open App
        </button>

        {/* Fallback options - shown after delay or immediately for query params */}
        {showFallback && (
          <div style={{
            marginTop: '24px',
            paddingTop: '24px',
            borderTop: '1px solid #e0e0e0'
          }}>
            <p style={{
              color: '#666',
              fontSize: '14px',
              marginBottom: '16px'
            }}>
              {triedAutoOpen 
                ? "App didn't open? Try these options:"
                : "Other options:"
              }
            </p>
            
            <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
              {/* Open in Safari */}
              <button
                onClick={handleOpenInSafari}
                style={{
                  backgroundColor: '#f5f5f5',
                  color: '#00796B',
                  border: '1px solid #e0e0e0',
                  borderRadius: '8px',
                  padding: '12px 24px',
                  fontSize: '16px',
                  cursor: 'pointer',
                  fontWeight: '500',
                  width: '100%'
                }}
              >
                🌐 Open in Safari
              </button>

              {/* Continue on Web */}
              <button
                onClick={handleContinueOnWeb}
                style={{
                  backgroundColor: '#f5f5f5',
                  color: '#00796B',
                  border: '1px solid #e0e0e0',
                  borderRadius: '8px',
                  padding: '12px 24px',
                  fontSize: '16px',
                  cursor: 'pointer',
                  fontWeight: '500',
                  width: '100%'
                }}
              >
                💻 Continue on Web
              </button>
            </div>
          </div>
        )}

        {/* Help text */}
        <p style={{
          color: '#999',
          fontSize: '12px',
          marginTop: '24px',
          lineHeight: '1.4'
        }}>
          Don't have the app? <a href="#" style={{ color: '#00796B', textDecoration: 'underline' }}>Download it here</a>
        </p>
      </div>
    </div>
  )
}
