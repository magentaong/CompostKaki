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

    // Normalize email to lowercase for consistency
    const normalizedEmail = email.toLowerCase().trim()

    // Verify OTP from database - find the most recent unused, non-expired OTP
    const { data: otpDataList, error: otpError } = await supabase
      .from('password_reset_otps')
      .select('*')
      .eq('email', normalizedEmail)
      .eq('otp_code', otpCode)
      .is('used_at', null) // Not used yet
      .gt('expires_at', new Date().toISOString()) // Not expired
      .order('created_at', { ascending: false }) // Most recent first
      .limit(1)

    if (otpError || !otpDataList || otpDataList.length === 0) {
      return NextResponse.json(
        { error: 'Invalid OTP code' },
        { status: 400 }
      )
    }

    const otpData = otpDataList[0]

    // Now check if user actually exists before creating recovery session
    // This prevents creating sessions for non-existent users
    const { data: usersData, error: usersError } = await supabase.auth.admin.listUsers()
    const userExists = usersData?.users?.some(user => 
      user.email?.toLowerCase().trim() === normalizedEmail
    ) ?? false

    if (!userExists) {
      // User doesn't exist - mark the OTP as used and return error
      await supabase
        .from('password_reset_otps')
        .update({ used_at: new Date().toISOString() })
        .eq('id', otpData.id)
      
      return NextResponse.json(
        { error: 'Invalid OTP code' }, // Generic error for security
        { status: 400 }
      )
    }

    // OTP expiration is already checked in the query above
    // But double-check just in case
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
      email: normalizedEmail,
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
      email: normalizedEmail,
    } as any)

    if (verifyError || !verifyData.session) {
      return NextResponse.json(
        { error: 'Failed to verify recovery token' },
        { status: 500 }
      )
    }

    // Mark OTP as used (don't delete, keep for audit trail)
    await supabase
      .from('password_reset_otps')
      .update({ used_at: new Date().toISOString() })
      .eq('id', otpData.id)

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

