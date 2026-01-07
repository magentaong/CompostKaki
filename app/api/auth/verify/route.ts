import { NextRequest, NextResponse } from 'next/server'

export async function GET(request: NextRequest) {
  const searchParams = request.nextUrl.searchParams
  const token = searchParams.get('token')
  const type = searchParams.get('type')
  const redirectTo = searchParams.get('redirect_to')

  console.log('🔐 [VERIFY API] Received verify request')
  console.log('🔐 [VERIFY API] Token:', token ? 'present' : 'missing')
  console.log('🔐 [VERIFY API] Type:', type)
  console.log('🔐 [VERIFY API] Redirect to:', redirectTo)

  // If we have a token and redirect_to, we need to verify with Supabase
  // and then redirect with tokens in hash
  if (token && redirectTo) {
    try {
      // Call Supabase verify endpoint to exchange token for session tokens
      const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
      const verifyUrl = `${supabaseUrl}/auth/v1/verify?token=${token}&type=${type || 'recovery'}&redirect_to=${encodeURIComponent(redirectTo)}`

      console.log('🔐 [VERIFY API] Calling Supabase verify:', verifyUrl)

      // Fetch from Supabase verify endpoint
      const response = await fetch(verifyUrl, {
        method: 'GET',
        redirect: 'manual', // Don't follow redirects automatically
      })

      // Supabase will return a redirect with tokens in hash
      // We need to extract the hash and redirect to our app
      const location = response.headers.get('location')
      
      if (location) {
        console.log('🔐 [VERIFY API] Supabase redirect location:', location)
        
        // Extract hash from location if present
        const url = new URL(location)
        const hash = url.hash
        
        if (hash) {
          // Redirect to redirect_to with hash
          const finalUrl = `${redirectTo}${hash}`
          console.log('🔐 [VERIFY API] Redirecting to:', finalUrl)
          return NextResponse.redirect(finalUrl)
        } else {
          // No hash - redirect anyway and let the page handle it
          console.log('🔐 [VERIFY API] No hash in redirect, redirecting to:', redirectTo)
          return NextResponse.redirect(redirectTo)
        }
      }

      // If no location header, redirect to redirect_to
      return NextResponse.redirect(redirectTo)
    } catch (error) {
      console.error('🔐 [VERIFY API] Error:', error)
      // On error, redirect to reset-password page
      return NextResponse.redirect(redirectTo || 'https://compostkaki.vercel.app/reset-password')
    }
  }

  // No token or redirect_to - redirect to home
  return NextResponse.redirect('https://compostkaki.vercel.app/')
}

