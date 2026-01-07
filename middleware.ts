import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

// Middleware to intercept password reset tokens BEFORE page loads
export function middleware(request: NextRequest) {
  const url = request.nextUrl.clone()
  const token = url.searchParams.get('token') || url.searchParams.get('code')
  const type = url.searchParams.get('type')
  
  // IMPORTANT: Check for token in URL (Supabase redirects with token in query params)
  // If we're on the home page and have a recovery token, redirect to reset-password
  if (url.pathname === '/' && token) {
    // Check if it's a recovery token (type=recovery or token starts with pkce_)
    const isRecoveryToken = type === 'recovery' || token.startsWith('pkce_')
    
    if (isRecoveryToken) {
      console.log('🔄 [MIDDLEWARE] Password reset token detected on home page, redirecting to reset-password')
      
      // Redirect to reset-password page with token
      url.pathname = '/reset-password'
      url.searchParams.set('token', token)
      if (type) {
        url.searchParams.set('type', type)
      }
      
      return NextResponse.redirect(url)
    }
  }

  // If we're on reset-password page with token but no hash, redirect to verify API
  if (url.pathname === '/reset-password' && token && !url.hash) {
    console.log('🔄 [MIDDLEWARE] Token found on reset-password page (no hash), redirecting to verify API')
    
    // Redirect to verify API
    url.pathname = '/api/auth/verify-token'
    // Keep token and type params
    
    return NextResponse.redirect(url)
  }

  return NextResponse.next()
}

export const config = {
  matcher: [
    '/',
    '/reset-password',
  ],
}

