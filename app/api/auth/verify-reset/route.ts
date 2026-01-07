import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@supabase/supabase-js'

export async function GET(request: NextRequest) {
  const searchParams = request.nextUrl.searchParams
  const token = searchParams.get('token') || searchParams.get('code')
  const type = searchParams.get('type') || 'recovery'
  const redirectTo = searchParams.get('redirect_to') || 'https://compostkaki.vercel.app/reset-password'

  console.log('🔐 [VERIFY API] Received request')
  console.log('🔐 [VERIFY API] Token:', token ? 'present' : 'missing')
  console.log('🔐 [VERIFY API] Type:', type)

  // Check if Supabase already redirected with tokens in query params
  const accessToken = searchParams.get('access_token')
  const refreshToken = searchParams.get('refresh_token')
  const recoveryType = searchParams.get('type')
  
  // If we already have tokens from Supabase redirect, use them directly
  if (accessToken && refreshToken && recoveryType === 'recovery') {
    console.log('🔐 [VERIFY API] Already have tokens from Supabase redirect')
    const hash = `#type=recovery&access_token=${encodeURIComponent(accessToken)}&refresh_token=${encodeURIComponent(refreshToken)}`
    return NextResponse.redirect(`${redirectTo}${hash}`)
  }
  
  if (!token) {
    // Check for error parameters from Supabase
    const error = searchParams.get('error')
    const errorCode = searchParams.get('error_code')
    const errorDescription = searchParams.get('error_description')
    
    if (error) {
      console.error('🔐 [VERIFY API] Error from Supabase:', error, errorCode, errorDescription)
      return NextResponse.redirect(
        `${redirectTo}?error=${encodeURIComponent(error)}&error_code=${encodeURIComponent(errorCode || '')}&error_description=${encodeURIComponent(errorDescription || '')}`
      )
    }
    
    return NextResponse.redirect(`${redirectTo}?error=missing_token&error_description=No verification token provided`)
  }

  try {
    // Create Supabase client
    const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
    const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY

    if (!supabaseUrl || !supabaseAnonKey) {
      console.error('🔐 [VERIFY API] Missing Supabase credentials')
      return NextResponse.redirect(`${redirectTo}?error=configuration_error`)
    }

    // For recovery type, call Supabase's verify endpoint directly via HTTP
    // because verifyOtp client method requires email for email types
    console.log('🔐 [VERIFY API] Calling Supabase verify endpoint directly...')
    
    const verifyUrl = `${supabaseUrl}/auth/v1/verify?token=${encodeURIComponent(token)}&type=${type}&redirect_to=${encodeURIComponent(redirectTo)}`
    
    const verifyResponse = await fetch(verifyUrl, {
      method: 'GET',
      headers: {
        'apikey': supabaseAnonKey,
        'Content-Type': 'application/json',
      },
      redirect: 'manual' // Don't follow redirects automatically
    })

    // Supabase verify endpoint returns a redirect with tokens in hash
    if (verifyResponse.status >= 300 && verifyResponse.status < 400) {
      const location = verifyResponse.headers.get('location')
      if (location) {
        console.log('🔐 [VERIFY API] Supabase redirected to:', location)
        
        // Parse the redirect URL to extract tokens from hash
        try {
          const redirectUrl = new URL(location)
          const hash = redirectUrl.hash
          
          if (hash && hash.includes('access_token')) {
            // Extract tokens from hash
            const hashParams = new URLSearchParams(hash.substring(1))
            const accessToken = hashParams.get('access_token')
            const refreshToken = hashParams.get('refresh_token')
            
            if (accessToken && refreshToken) {
              console.log('🔐 [VERIFY API] Extracted tokens from redirect hash')
              const finalHash = `#type=recovery&access_token=${encodeURIComponent(accessToken)}&refresh_token=${encodeURIComponent(refreshToken)}`
              return NextResponse.redirect(`${redirectTo}${finalHash}`)
            }
          }
          
          // If hash doesn't have tokens, redirect as-is (Supabase might have handled it)
          return NextResponse.redirect(location)
        } catch (e) {
          console.error('🔐 [VERIFY API] Error parsing redirect URL:', e)
          // Fall through to error handling
        }
      }
    }

    // If redirect didn't work or no tokens found, try using Supabase client
    // For recovery type, we can use verifyOtp without email (some versions allow this)
    const supabase = createClient(supabaseUrl, supabaseAnonKey)
    
    try {
      // Use type assertion to bypass TypeScript check for recovery type
      const { data, error } = await supabase.auth.verifyOtp({
        token: token,
        type: 'recovery'
      } as any)

      if (error) {
        console.error('🔐 [VERIFY API] Verification error:', error)
        return NextResponse.redirect(
          `${redirectTo}?error=${encodeURIComponent(error.message)}&error_code=${encodeURIComponent(error.status?.toString() || 'unknown')}`
        )
      }

      if (!data.session) {
        console.error('🔐 [VERIFY API] No session returned')
        return NextResponse.redirect(`${redirectTo}?error=no_session&error_description=Failed to create session`)
      }

      // Success! Redirect with tokens in hash
      const hash = `#type=recovery&access_token=${encodeURIComponent(data.session.access_token)}&refresh_token=${encodeURIComponent(data.session.refresh_token)}`
      const finalUrl = `${redirectTo}${hash}`

      console.log('🔐 [VERIFY API] Verification successful, redirecting with tokens')
      return NextResponse.redirect(finalUrl)
    } catch (clientError: any) {
      console.error('🔐 [VERIFY API] Client verification error:', clientError)
      return NextResponse.redirect(`${redirectTo}?error=verification_failed&error_description=${encodeURIComponent(clientError.message || 'Verification failed')}`)
    }
  } catch (error: any) {
    console.error('🔐 [VERIFY API] Unexpected error:', error)
    return NextResponse.redirect(`${redirectTo}?error=unexpected_error&error_description=${encodeURIComponent(error.message || 'Unknown error')}`)
  }
}

