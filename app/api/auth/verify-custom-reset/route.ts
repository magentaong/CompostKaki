import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@supabase/supabase-js'

// Verify custom reset token and exchange for Supabase session
export async function GET(request: NextRequest) {
  const searchParams = request.nextUrl.searchParams
  const token = searchParams.get('token')
  const email = searchParams.get('email')

  if (!token || !email) {
    return NextResponse.redirect(
      'https://compostkaki.vercel.app/reset-password?error=invalid_token&error_description=Missing token or email'
    )
  }

  try {
    const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
    const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY

    if (!supabaseUrl || !supabaseServiceKey) {
      return NextResponse.redirect(
        'https://compostkaki.vercel.app/reset-password?error=configuration_error'
      )
    }

    // Create admin client
    const supabase = createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false
      }
    })

    // Verify token exists and is not expired
    const { data: tokenData, error: tokenError } = await supabase
      .from('password_reset_tokens')
      .select('*')
      .eq('token', token)
      .eq('email', email)
      .single()

    if (tokenError || !tokenData) {
      return NextResponse.redirect(
        'https://compostkaki.vercel.app/reset-password?error=invalid_token&error_description=Token not found'
      )
    }

    // Check if token is expired
    const expiresAt = new Date(tokenData.expires_at)
    if (expiresAt < new Date()) {
      return NextResponse.redirect(
        'https://compostkaki.vercel.app/reset-password?error=token_expired&error_description=Token has expired'
      )
    }

    // Create a recovery session for this user
    // We'll use Supabase's admin API to generate a recovery link
    const { data: linkData, error: linkError } = await supabase.auth.admin.generateLink({
      type: 'recovery',
      email: email,
    })

    if (linkError || !linkData) {
      console.error('Error generating recovery link:', linkError)
      return NextResponse.redirect(
        'https://compostkaki.vercel.app/reset-password?error=verification_failed&error_description=Failed to create recovery session'
      )
    }

    // Extract tokens from the recovery link
    // The link format is: https://...?token=...&type=recovery&redirect_to=...
    // We need to call Supabase verify endpoint to get actual session tokens
    const recoveryUrl = new URL(linkData.properties.action_link)
    const recoveryToken = recoveryUrl.searchParams.get('token')

    if (!recoveryToken) {
      return NextResponse.redirect(
        'https://compostkaki.vercel.app/reset-password?error=token_extraction_failed'
      )
    }

    // Call Supabase verify endpoint to get session tokens
    const verifyUrl = `${supabaseUrl}/auth/v1/verify?token=${encodeURIComponent(recoveryToken)}&type=recovery&redirect_to=${encodeURIComponent('https://compostkaki.vercel.app/reset-password')}`
    
    const verifyResponse = await fetch(verifyUrl, {
      method: 'GET',
      headers: {
        'apikey': process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
      },
      redirect: 'manual'
    })

    if (verifyResponse.status >= 300 && verifyResponse.status < 400) {
      const location = verifyResponse.headers.get('location')
      if (location) {
        // Extract tokens from redirect location hash
        const redirectUrl = new URL(location)
        const hash = redirectUrl.hash
        
        if (hash && hash.includes('access_token')) {
          // Redirect to reset-password page with tokens in hash
          return NextResponse.redirect(`https://compostkaki.vercel.app/reset-password${hash}`)
        }
      }
    }

    // If that didn't work, try using Supabase client to verify
    const anonSupabase = createClient(supabaseUrl, process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!)
    const { data: verifyData, error: verifyError } = await anonSupabase.auth.verifyOtp({
      token: recoveryToken,
      type: 'recovery'
    } as any)

    if (verifyError || !verifyData.session) {
      return NextResponse.redirect(
        'https://compostkaki.vercel.app/reset-password?error=verification_failed&error_description=' + encodeURIComponent(verifyError?.message || 'Failed to verify token')
      )
    }

    // Success! Redirect with tokens
    const hash = `#type=recovery&access_token=${encodeURIComponent(verifyData.session.access_token)}&refresh_token=${encodeURIComponent(verifyData.session.refresh_token)}`
    return NextResponse.redirect(`https://compostkaki.vercel.app/reset-password${hash}`)

  } catch (error: any) {
    console.error('Verify custom reset error:', error)
    return NextResponse.redirect(
      'https://compostkaki.vercel.app/reset-password?error=unexpected_error&error_description=' + encodeURIComponent(error.message || 'Unknown error')
    )
  }
}

