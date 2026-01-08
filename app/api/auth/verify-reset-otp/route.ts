import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@supabase/supabase-js'

// Verify OTP code and create recovery session
export async function POST(request: NextRequest) {
  try {
    const { email, otpCode } = await request.json()

    if (!email || !otpCode) {
      return NextResponse.json(
        { error: 'Email and OTP code are required' },
        { status: 400 }
      )
    }

    const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
    const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY

    if (!supabaseUrl || !supabaseServiceKey) {
      return NextResponse.json(
        { error: 'Server configuration error' },
        { status: 500 }
      )
    }

    // Create admin client
    const supabase = createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false
      }
    })

    // Verify OTP from database
    const { data: otpData, error: otpError } = await supabase
      .from('password_reset_otps')
      .select('*')
      .eq('email', email)
      .eq('otp_code', otpCode)
      .single()

    if (otpError || !otpData) {
      return NextResponse.json(
        { error: 'Invalid OTP code' },
        { status: 400 }
      )
    }

    // Check if OTP is expired
    const expiresAt = new Date(otpData.expires_at)
    if (expiresAt < new Date()) {
      return NextResponse.json(
        { error: 'OTP code has expired. Please request a new one.' },
        { status: 400 }
      )
    }

    // Generate recovery link using Supabase admin API
    const { data: linkData, error: linkError } = await supabase.auth.admin.generateLink({
      type: 'recovery',
      email: email,
    })

    if (linkError || !linkData) {
      return NextResponse.json(
        { error: 'Failed to create recovery session' },
        { status: 500 }
      )
    }

    // Extract token from the recovery link
    const recoveryUrl = new URL(linkData.properties.action_link)
    const recoveryToken = recoveryUrl.searchParams.get('token')

    if (!recoveryToken) {
      return NextResponse.json(
        { error: 'Failed to extract recovery token' },
        { status: 500 }
      )
    }

    // Verify the recovery token to get session
    const anonSupabase = createClient(supabaseUrl, process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!)
    const { data: verifyData, error: verifyError } = await anonSupabase.auth.verifyOtp({
      token: recoveryToken,
      type: 'recovery',
      email: email,
    } as any)

    if (verifyError || !verifyData.session) {
      return NextResponse.json(
        { error: 'Failed to verify recovery token' },
        { status: 500 }
      )
    }

    // Delete used OTP
    await supabase
      .from('password_reset_otps')
      .delete()
      .eq('email', email)

    // Return session tokens
    return NextResponse.json({
      success: true,
      access_token: verifyData.session.access_token,
      refresh_token: verifyData.session.refresh_token,
    })

  } catch (error: any) {
    console.error('Verify reset OTP error:', error)
    return NextResponse.json(
      { error: error.message || 'Internal server error' },
      { status: 500 }
    )
  }
}

