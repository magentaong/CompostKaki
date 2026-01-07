import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@supabase/supabase-js'

// SIMPLE SOLUTION: Extract token from email link and verify it directly
// This bypasses all redirect URL matching issues
export async function GET(request: NextRequest) {
  const searchParams = request.nextUrl.searchParams
  const token = searchParams.get('token') || searchParams.get('code')
  const type = searchParams.get('type') || 'recovery'

  console.log('🔐 [VERIFY TOKEN] Received token verification request')
  console.log('🔐 [VERIFY TOKEN] Token:', token ? 'present' : 'missing')
  console.log('🔐 [VERIFY TOKEN] Type:', type)

  if (!token) {
    return NextResponse.redirect(
      'https://compostkaki.vercel.app/reset-password?error=missing_token&error_description=No token provided'
    )
  }

  try {
    const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
    const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY

    if (!supabaseUrl || !supabaseAnonKey) {
      return NextResponse.redirect(
        'https://compostkaki.vercel.app/reset-password?error=configuration_error'
      )
    }

    // Create Supabase client
    const supabase = createClient(supabaseUrl, supabaseAnonKey)

    // For PKCE tokens, we need to use verifyOtp
    // But verifyOtp requires email for recovery type, so we'll try a different approach
    
    // Method 1: Try verifyOtp directly (might work for some token types)
    try {
      const { data, error } = await supabase.auth.verifyOtp({
        token: token,
        type: 'recovery'
      } as any)

      if (!error && data.session) {
        console.log('✅ [VERIFY TOKEN] Verification successful via verifyOtp')
        const hash = `#type=recovery&access_token=${encodeURIComponent(data.session.access_token)}&refresh_token=${encodeURIComponent(data.session.refresh_token)}`
        return NextResponse.redirect(`https://compostkaki.vercel.app/reset-password${hash}`)
      }
    } catch (e) {
      console.log('⚠️ [VERIFY TOKEN] verifyOtp failed, trying HTTP method:', e)
    }

    // Method 2: Call Supabase verify endpoint via HTTP
    // This is what Supabase does internally when you click the email link
    const verifyUrl = `${supabaseUrl}/auth/v1/verify?token=${encodeURIComponent(token)}&type=${type}`
    
    console.log('🔐 [VERIFY TOKEN] Calling Supabase verify endpoint:', verifyUrl)

    const verifyResponse = await fetch(verifyUrl, {
      method: 'GET',
      headers: {
        'apikey': supabaseAnonKey,
        'Content-Type': 'application/json',
      },
      redirect: 'manual'
    })

    console.log('🔐 [VERIFY TOKEN] Response status:', verifyResponse.status)

    // If Supabase returns a redirect, extract tokens from it
    if (verifyResponse.status >= 300 && verifyResponse.status < 400) {
      const location = verifyResponse.headers.get('location')
      if (location) {
        console.log('🔐 [VERIFY TOKEN] Supabase redirected to:', location)
        
        // Parse redirect URL to extract tokens
        try {
          const redirectUrl = new URL(location)
          const hash = redirectUrl.hash
          
          if (hash && hash.includes('access_token')) {
            // Extract tokens from hash
            const hashParams = new URLSearchParams(hash.substring(1))
            const accessToken = hashParams.get('access_token')
            const refreshToken = hashParams.get('refresh_token')
            
            if (accessToken && refreshToken) {
              console.log('✅ [VERIFY TOKEN] Extracted tokens from redirect hash')
              const finalHash = `#type=recovery&access_token=${encodeURIComponent(accessToken)}&refresh_token=${encodeURIComponent(refreshToken)}`
              return NextResponse.redirect(`https://compostkaki.vercel.app/reset-password${finalHash}`)
            }
          }
        } catch (e) {
          console.error('❌ [VERIFY TOKEN] Error parsing redirect URL:', e)
        }
      }
    }

    // If we get here, verification failed
    const errorText = await verifyResponse.text()
    console.error('❌ [VERIFY TOKEN] Verification failed:', verifyResponse.status, errorText)
    
    return NextResponse.redirect(
      `https://compostkaki.vercel.app/reset-password?error=verification_failed&error_code=${verifyResponse.status}&error_description=${encodeURIComponent(errorText.substring(0, 100))}`
    )

  } catch (error: any) {
    console.error('❌ [VERIFY TOKEN] Unexpected error:', error)
    return NextResponse.redirect(
      `https://compostkaki.vercel.app/reset-password?error=unexpected_error&error_description=${encodeURIComponent(error.message || 'Unknown error')}`
    )
  }
}

