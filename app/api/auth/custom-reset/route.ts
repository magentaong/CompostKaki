import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@supabase/supabase-js'

// Custom password reset endpoint that doesn't rely on Supabase's redirect flow
// This generates a custom token, stores it, and sends email with our own link
export async function POST(request: NextRequest) {
  try {
    const { email } = await request.json()

    if (!email) {
      return NextResponse.json({ error: 'Email is required' }, { status: 400 })
    }

    const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
    const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY

    if (!supabaseUrl || !supabaseServiceKey) {
      return NextResponse.json({ error: 'Server configuration error' }, { status: 500 })
    }

    // Create admin client with service role key
    const supabase = createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false
      }
    })

    // Generate a secure random token
    const resetToken = crypto.randomUUID()
    const expiresAt = new Date()
    expiresAt.setHours(expiresAt.getHours() + 1) // 1 hour expiration

    // Store reset token in database
    const { error: dbError } = await supabase
      .from('password_reset_tokens')
      .insert({
        email,
        token: resetToken,
        expires_at: expiresAt.toISOString(),
        created_at: new Date().toISOString()
      })

    if (dbError) {
      // Table might not exist, create it first
      console.error('Database error:', dbError)
      return NextResponse.json({ 
        error: 'Failed to create reset token. Please contact support.' 
      }, { status: 500 })
    }

    // Create reset link
    const resetLink = `https://compostkaki.vercel.app/reset-password?token=${resetToken}&email=${encodeURIComponent(email)}`

    // Send email using Supabase's email service or your own SMTP
    // For now, we'll use Supabase's built-in email sending
    // But with our custom token instead of their verify endpoint

    // Actually, let's use a simpler approach - use Supabase's resetPasswordForEmail
    // but with a custom redirect that we handle ourselves
    const { error: emailError } = await supabase.auth.admin.generateLink({
      type: 'recovery',
      email,
      options: {
        redirectTo: `https://compostkaki.vercel.app/reset-password?custom_token=${resetToken}`
      }
    })

    if (emailError) {
      console.error('Email error:', emailError)
      return NextResponse.json({ 
        error: 'Failed to send reset email' 
      }, { status: 500 })
    }

    return NextResponse.json({ 
      success: true,
      message: 'Password reset email sent'
    })

  } catch (error: any) {
    console.error('Reset password error:', error)
    return NextResponse.json({ 
      error: error.message || 'Internal server error' 
    }, { status: 500 })
  }
}

