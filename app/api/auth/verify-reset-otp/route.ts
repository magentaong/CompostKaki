import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@supabase/supabase-js'

// Verify OTP code and create recovery session
export const runtime = 'nodejs' // Ensure Node.js runtime, not Edge

export async function POST(request: NextRequest) {
  try {
    // Version log to confirm deployment
    console.log('[VERIFY_OTP_VERSION] v4-2026-01-08-debug')
    
    const { email, otpCode } = await request.json()

    if (!email || !otpCode) {
      return NextResponse.json(
        { error: 'Email and OTP code are required' },
        { status: 400 }
      )
    }

    const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
    const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY

    // Debug: Check Supabase configuration
    console.log('[SUPABASE_URL]', supabaseUrl)
    console.log('[ENV_HAS_SERVICE_KEY]', !!supabaseServiceKey)
    console.log('[SUPABASE_PROJECT_ID]', supabaseUrl?.match(/https:\/\/([^.]+)\.supabase\.co/)?.[1])

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

    // Normalize inputs - remove all non-digits from OTP, trim email
    const emailNorm = email.trim().toLowerCase()
    const otpNorm = String(otpCode).replace(/\D/g, '') // digits only, removes spaces/special chars
    
    // Debug: Log raw and normalized inputs
    console.log('[INPUT]', {
      emailRaw: email,
      emailNorm,
      otpRaw: otpCode,
      otpNorm,
      otpRawLen: String(otpCode).length,
      otpNormLen: otpNorm.length,
      otpRawType: typeof otpCode,
    })
    
    console.log('🔐 [VERIFY OTP] Verifying OTP for email:', emailNorm, 'OTP:', otpNorm)

    // PROBE: Check if API can read the table at all
    const TABLE_NAME = 'password_reset_otps'
    console.log('[TABLE_CHECK] Querying table:', TABLE_NAME)
    
    const { data: probeData, error: probeError } = await supabase
      .from(TABLE_NAME)
      .select('id,email,otp_code,expires_at,created_at,used_at')
      .eq('email', emailNorm)
      .order('created_at', { ascending: false })
      .limit(5)

    console.log('[PROBE]', {
      emailNorm,
      otpNorm,
      rows: probeData?.length || 0,
      err: probeError,
      data: probeData?.map(otp => ({
        id: otp.id,
        email: otp.email,
        otp_code: otp.otp_code,
        otp_code_type: typeof otp.otp_code,
        otp_code_len: String(otp.otp_code).length,
        expires_at: otp.expires_at,
        used_at: otp.used_at,
        created_at: otp.created_at,
        matches_otp: otp.otp_code === otpNorm,
        matches_otp_string: String(otp.otp_code) === String(otpNorm),
      }))
    })

    if (probeError) {
      console.error('🔐 [VERIFY OTP] PROBE Error:', probeError)
      return NextResponse.json(
        { error: 'Database error while checking OTPs', details: probeError.message },
        { status: 500 }
      )
    }

    if (!probeData || probeData.length === 0) {
      console.error('🔐 [VERIFY OTP] PROBE: No OTPs found for email - API may be hitting different database!')
      return NextResponse.json(
        { error: 'No OTP found for this email. Please request a new OTP code.' },
        { status: 400 }
      )
    }

    // Verify OTP from database - find the most recent unused, non-expired OTP
    // Use UTC time to avoid timezone issues
    const now = new Date()
    const nowISO = now.toISOString()
    console.log('🔐 [VERIFY OTP] Current time (UTC):', nowISO)
    console.log('🔐 [VERIFY OTP] Current time (local):', now.toString())
    
    // Main verification query - use normalized values
    console.log('[VERIFY_QUERY] Executing query on table:', TABLE_NAME, {
      emailNorm,
      otpNorm,
      nowISO,
      filters: {
        email: emailNorm,
        otp_code: otpNorm,
        used_at: 'IS NULL',
        expires_at: `> ${nowISO}`
      }
    })
    
    const { data: otpDataList, error: otpError } = await supabase
      .from(TABLE_NAME)
      .select('*')
      .eq('email', emailNorm)
      .eq('otp_code', otpNorm) // Use normalized OTP (digits only)
      .is('used_at', null) // Not used yet
      .gt('expires_at', nowISO) // Not expired - compare with UTC ISO string
      .order('created_at', { ascending: false }) // Most recent first
      .limit(1)
    
    console.log('[VERIFY_QUERY_RESULT]', {
      table: TABLE_NAME,
      emailNorm,
      otpNorm,
      nowISO,
      queryResult: otpDataList?.length || 0,
      error: otpError,
      resultData: otpDataList?.[0] ? {
        id: otpDataList[0].id,
        email: otpDataList[0].email,
        otp_code: otpDataList[0].otp_code,
        otp_code_type: typeof otpDataList[0].otp_code,
        expires_at: otpDataList[0].expires_at,
        used_at: otpDataList[0].used_at,
      } : null
    })

    if (otpError) {
      console.error('🔐 [VERIFY OTP] Database error:', otpError)
      return NextResponse.json(
        { error: 'Database error while verifying OTP', details: otpError.message },
        { status: 500 }
      )
    }

    if (!otpDataList || otpDataList.length === 0) {
      console.log('🔐 [VERIFY OTP] No matching OTP found')
      // Check if OTP exists but is expired or used (use normalized values)
      console.log('[FALLBACK_QUERY] Checking if OTP exists (ignoring used_at and expires_at) on table:', TABLE_NAME)
      const { data: expiredOtps } = await supabase
        .from(TABLE_NAME)
        .select('*')
        .eq('email', emailNorm)
        .eq('otp_code', otpNorm)
        .limit(1)
      
      console.log('[FALLBACK_QUERY_RESULT]', {
        found: expiredOtps?.length || 0,
        data: expiredOtps?.[0] ? {
          id: expiredOtps[0].id,
          email: expiredOtps[0].email,
          otp_code: expiredOtps[0].otp_code,
          expires_at: expiredOtps[0].expires_at,
          used_at: expiredOtps[0].used_at,
        } : null
      })
      
      if (expiredOtps && expiredOtps.length > 0) {
        const otp = expiredOtps[0]
        console.log('🔐 [VERIFY OTP] Found OTP but filtered out:', {
          code: otp.otp_code,
          expires_at: otp.expires_at,
          used_at: otp.used_at,
          expires_at_parsed: new Date(otp.expires_at).toISOString(),
          current_time: nowISO,
          is_expired: new Date(otp.expires_at) < now,
          is_used: otp.used_at !== null
        })
        
        if (otp.used_at) {
          console.log('🔐 [VERIFY OTP] OTP already used at:', otp.used_at)
          return NextResponse.json(
            { error: 'This OTP code has already been used. Please request a new one.' },
            { status: 400 }
          )
        }
        const expiresAtDate = new Date(otp.expires_at)
        if (expiresAtDate < now) {
          console.log('🔐 [VERIFY OTP] OTP expired. Expires:', expiresAtDate.toISOString(), 'Now:', nowISO)
          return NextResponse.json(
            { error: 'OTP code has expired. Please request a new one.' },
            { status: 400 }
          )
        }
      }
      
      return NextResponse.json(
        { error: 'Invalid OTP code. Please check and try again.' },
        { status: 400 }
      )
    }

    const otpData = otpDataList[0]
    console.log('🔐 [VERIFY OTP] Found matching OTP:', {
      id: otpData.id,
      email: otpData.email,
      code: otpData.otp_code,
      expires_at: otpData.expires_at,
      created_at: otpData.created_at
    })

    // Now check if user actually exists before creating recovery session
    // This prevents creating sessions for non-existent users
    const { data: usersData, error: usersError } = await supabase.auth.admin.listUsers()
    const userExists = usersData?.users?.some(user => 
      user.email?.toLowerCase().trim() === emailNorm
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
      email: emailNorm,
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
      email: emailNorm,
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

