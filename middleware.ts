import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

// Middleware to intercept password reset tokens BEFORE page loads
export function middleware(request: NextRequest) {
  const url = request.nextUrl.clone()
  const token = url.searchParams.get('token') || url.searchParams.get('code')
  const type = url.searchParams.get('type')
  
  // Check for errors in hash (Supabase redirects with errors in hash)
  const hash = url.hash
  if (hash) {
    const hashParams = new URLSearchParams(hash.substring(1))
    const error = hashParams.get('error')
    const errorCode = hashParams.get('error_code')
    
    // If we have an error in hash, redirect to reset-password page to show error
    if (error && url.pathname === '/') {
      console.log('🔄 [MIDDLEWARE] Error detected in hash, redirecting to reset-password')
      url.pathname = '/reset-password'
      // Preserve hash with error
      return NextResponse.redirect(url)
    }
  }
  
  // IMPORTANT: Check for token in URL (Supabase redirects with token in query params)
  // If we're on the home page and have ANY token, redirect to reset-password
  // This catches all password reset links
  if (url.pathname === '/' && token) {
    // Check if it's a recovery token (type=recovery or token starts with pkce_)
    // Also check if token looks like a Supabase token (has underscore or is long)
    const isRecoveryToken = type === 'recovery' || 
                            token.startsWith('pkce_') || 
                            token.includes('_') ||
                            token.length > 20
    
    if (isRecoveryToken) {
      console.log('🔄 [MIDDLEWARE] Password reset token detected on home page, redirecting to reset-password')
      console.log('🔄 [MIDDLEWARE] Token:', token.substring(0, 20) + '...')
      console.log('🔄 [MIDDLEWARE] Type:', type)
      
      // Redirect to reset-password page with token
      url.pathname = '/reset-password'
      url.searchParams.set('token', token)
      if (type) {
        url.searchParams.set('type', type)
      } else {
        // Assume recovery if no type specified
        url.searchParams.set('type', 'recovery')
      }
      
      return NextResponse.redirect(url)
    }
  }

  // If we're on reset-password page with token but no hash, that's OK
  // Supabase might redirect here with token, and the page will handle it
  // Don't redirect to verify API - Supabase already verified when user clicked email link

  return NextResponse.next()
}

export const config = {
  matcher: [
    '/',
    '/reset-password',
  ],
}

