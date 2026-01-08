import { NextRequest, NextResponse } from 'next/server'

// DEPRECATED: This route should NOT be used anymore
// We removed double verification to prevent otp_expired errors
// If token has no hash, it means it was already consumed (likely by iOS Gmail prefetch)
// Instead of verifying again, show helpful UI to user

export async function GET(request: NextRequest) {
  const redirectTo = 'https://compostkaki.vercel.app/reset-password'
  
  console.warn('⚠️ [VERIFY RECOVERY] This route should not be called anymore')
  console.warn('⚠️ [VERIFY RECOVERY] Token verification should happen only once via email link')
  
  // Redirect back with error message explaining the issue
  return NextResponse.redirect(
    `${redirectTo}?error=token_already_used&error_description=This password reset link may have been opened automatically by your email app. Please request a new password reset email, or try opening the link directly in Safari (not Gmail's in-app browser).`
  )
}
