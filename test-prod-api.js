const fs = require('fs');
const env = Object.fromEntries(
  fs.readFileSync('.env.local', 'utf8')
    .split(/\r?\n/)
    .filter(Boolean)
    .map((l) => [l.slice(0, l.indexOf('=')), l.slice(l.indexOf('=') + 1)])
);
const { createClient } = require('@supabase/supabase-js');
const email = 'sumitsanjayshinde0702@gmail.com';
const otpCode = String(Math.floor(100000 + Math.random() * 900000));

const supabase = createClient(env.NEXT_PUBLIC_SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false },
});

(async () => {
  const expiresAt = new Date(Date.now() + 10 * 60 * 1000).toISOString();
  const { error: insErr } = await supabase.from('password_reset_otps').insert({
    email,
    otp_code: otpCode,
    expires_at: expiresAt,
    created_at: new Date().toISOString(),
  });
  if (insErr) {
    console.log('insert ERROR:', JSON.stringify(insErr));
    return;
  }
  console.log('Inserted test OTP:', otpCode);

  const res = await fetch('https://compostkaki.vercel.app/api/auth/verify-reset-otp', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, otpCode }),
  });
  const body = await res.text();
  console.log('Prod API status:', res.status);
  console.log('Prod API body (truncated):', body.slice(0, 200));

  await supabase.from('password_reset_otps').delete().eq('email', email).eq('otp_code', otpCode);
  console.log('Cleaned up test OTP');
})().catch((e) => console.log('THROWN:', e));
