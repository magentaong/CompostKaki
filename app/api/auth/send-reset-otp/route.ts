import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@supabase/supabase-js'

// Custom API to send OTP code for password reset
// This generates a 6-digit OTP, stores it, and sends it via email
export async function POST(request: NextRequest) {
  try {
    const { email } = await request.json()

    if (!email || !email.includes('@')) {
      return NextResponse.json(
        { error: 'Valid email is required' },
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

    // Check if user exists (list all users and find by email)
    const { data: usersData, error: usersError } = await supabase.auth.admin.listUsers()
    
    const userExists = usersData?.users?.some(user => user.email === email) ?? false

    if (!userExists) {
      // Don't reveal if user exists (security)
      return NextResponse.json({
        success: true,
        message: 'If an account exists, an OTP code has been sent to your email.'
      })
    }

    // Generate 6-digit OTP code
    const otpCode = Math.floor(100000 + Math.random() * 900000).toString()

    // Store OTP in database (with expiration - 10 minutes)
    const expiresAt = new Date()
    expiresAt.setMinutes(expiresAt.getMinutes() + 10)

    // Create or update password_reset_otps table
    const { error: dbError } = await supabase
      .from('password_reset_otps')
      .upsert({
        email: email,
        otp_code: otpCode,
        expires_at: expiresAt.toISOString(),
        created_at: new Date().toISOString(),
      }, {
        onConflict: 'email'
      })

    if (dbError) {
      console.error('Database error:', dbError)
      // Table might not exist - we'll create it via migration or handle gracefully
      // For now, continue and try to send email
    }

    // Send email with OTP code using SendGrid
    const sendGridApiKey = process.env.SENDGRID_API_KEY
    if (!sendGridApiKey) {
      console.error('SENDGRID_API_KEY not configured')
      // Fallback: Still store OTP, but log error
      return NextResponse.json({
        success: true,
        message: 'OTP code generated. Email sending not configured.',
        // In development, return OTP for testing
        ...(process.env.NODE_ENV === 'development' && { otp: otpCode })
      })
    }

    const emailSubject = 'CompostKaki - Password Reset Code'
    const emailHtml = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
      </head>
      <body style="font-family: Arial, sans-serif; background-color: #f5f5f5; padding: 20px;">
        <div style="max-width: 600px; margin: 0 auto; background-color: white; border-radius: 12px; padding: 40px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
          <h1 style="color: #00796B; text-align: center; margin-bottom: 30px;">CompostKaki</h1>
          <h2 style="color: #333; text-align: center; margin-bottom: 20px;">Password Reset Code</h2>
          <p style="color: #666; text-align: center; margin-bottom: 30px;">Your password reset code is:</p>
          <div style="text-align: center; margin: 30px 0;">
            <div style="display: inline-block; font-size: 36px; letter-spacing: 12px; color: #00796B; font-weight: bold; padding: 20px 40px; background-color: #E6FFF3; border-radius: 8px; border: 2px solid #00796B;">
              ${otpCode}
            </div>
          </div>
          <p style="color: #666; text-align: center; margin-top: 30px;">Enter this code in the app to reset your password.</p>
          <p style="color: #999; text-align: center; font-size: 14px; margin-top: 20px;">This code will expire in 10 minutes.</p>
          <p style="color: #999; text-align: center; font-size: 12px; margin-top: 30px;">If you didn't request this, please ignore this email.</p>
        </div>
      </body>
      </html>
    `

    const emailText = `CompostKaki - Password Reset Code

Your password reset code is: ${otpCode}

Enter this code in the app to reset your password.
This code will expire in 10 minutes.

If you didn't request this, please ignore this email.`

    // Send email via SendGrid
    const sendGridResponse = await fetch('https://api.sendgrid.com/v3/mail/send', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${sendGridApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        personalizations: [{
          to: [{ email: email }],
          subject: emailSubject,
        }],
        from: { email: 'compostkaki@gmail.com', name: 'CompostKaki' },
        content: [
          {
            type: 'text/plain',
            value: emailText,
          },
          {
            type: 'text/html',
            value: emailHtml,
          },
        ],
      }),
    })

    if (!sendGridResponse.ok) {
      const errorText = await sendGridResponse.text()
      console.error('SendGrid error:', sendGridResponse.status, errorText)
      // Still return success (OTP is stored) but log error
      // In development, return OTP for testing
      return NextResponse.json({
        success: true,
        message: 'OTP code generated. Email sending failed.',
        // In development, return OTP for testing
        ...(process.env.NODE_ENV === 'development' && { otp: otpCode })
      })
    }

    return NextResponse.json({
      success: true,
      message: 'OTP code sent to your email. Please check your inbox.',
      // In development, you might want to return the OTP for testing
      // Remove this in production!
      ...(process.env.NODE_ENV === 'development' && { otp: otpCode })
    })

  } catch (error: any) {
    console.error('Send reset OTP error:', error)
    return NextResponse.json(
      { error: error.message || 'Internal server error' },
      { status: 500 }
    )
  }
}

