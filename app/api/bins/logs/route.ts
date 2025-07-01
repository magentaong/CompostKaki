import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL as string
const supabaseServiceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY as string
const supabase = createClient(supabaseUrl, supabaseServiceRoleKey)

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url)
  const binId = searchParams.get('bin_id')
  if (!binId) return NextResponse.json({ error: 'Missing bin_id' }, { status: 400 })

  const { data, error } = await supabase
    .from('bin_logs')
    .select('*, profiles!bin_logs_user_id_fkey(first_name, last_name)')
    .eq('bin_id', binId)
    .order('created_at', { ascending: false })

  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json({ entries: data })
}

export async function POST(req: NextRequest) {
  const authHeader = req.headers.get('authorization')
  console.log("Auth header:", authHeader); // Add this line for debugging
  const jwt = authHeader?.replace('Bearer ', '')
  if (!jwt) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  const { data: { user }, error: userError } = await supabase.auth.getUser(jwt)
  if (userError || !user) return NextResponse.json({ error: 'Invalid user' }, { status: 401 })

  const body = await req.json()
  const { bin_id, content, temperature, moisture, type, image } = body
  if (!bin_id || !content) return NextResponse.json({ error: 'Missing required fields' }, { status: 400 })

  const tempValue = temperature !== undefined && temperature !== null && temperature !== "" ? Number(temperature) : null;
  const moistValue = moisture !== undefined && moisture !== null && moisture !== "" ? moisture : null;

  // Insert log (no filtering)
  const { data: log, error } = await supabase
    .from('bin_logs')
    .insert([{ bin_id, user_id: user.id, content, temperature: tempValue, moisture: moistValue, type, image }])
    .select()
    .single()

  if (error) return NextResponse.json({ error: error.message }, { status: 500 })

  // Get latest non-null temperature
  const { data: latestTempLog } = await supabase
    .from('bin_logs')
    .select('temperature')
    .eq('bin_id', bin_id)
    .not('temperature', 'is', null)
    .order('created_at', { ascending: false })
    .limit(1)
    .single();

  const latestTemperature = latestTempLog?.temperature !== undefined && latestTempLog?.temperature !== null
    ? Number(latestTempLog.temperature)
    : null;

  // Get latest non-null moisture
  const { data: latestMoistureLog } = await supabase
    .from('bin_logs')
    .select('moisture')
    .eq('bin_id', bin_id)
    .not('moisture', 'is', null)
    .order('created_at', { ascending: false })
    .limit(1)
    .single();

  const latestMoisture = latestMoistureLog?.moisture ?? null;

  // Health status logic using latest values
  let health_status = "Healthy";
  if (
    latestTemperature !== null && latestMoisture !== null &&
    latestTemperature >= 27 && latestTemperature <= 45 && latestMoisture === "Perfect"
  ) {
    health_status = "Healthy";
  } else if (
    (latestTemperature !== null && latestTemperature > 45 && latestTemperature <= 50) ||
    latestMoisture === "Wet" || latestMoisture === "Dry"
  ) {
    health_status = "Needs Attention";
  } else if (
    (latestTemperature !== null && latestTemperature > 50) ||
    latestMoisture === "Very Wet" || latestMoisture === "Very Dry"
  ) {
    health_status = "Critical";
  }

  const latestTemperatureNum = typeof latestTemperature === "number" ? latestTemperature : null;
  const latestMoistureStr = typeof latestMoisture === "string" ? latestMoisture : null;

  // If type is 'Turn Pile', increment latest_flips
  let binUpdateError = null;
  if (type && type.toLowerCase().includes('turn')) {
    const { error: flipError } = await supabase.rpc('increment_bin_flips', { bin_id_input: bin_id });
    if (flipError) binUpdateError = flipError;
  }
  const { error: updateError } = await supabase
    .from('bins')
    .update({
      latest_temperature: latestTemperatureNum,
      latest_moisture: latestMoistureStr,
      health_status
    })
    .eq('id', bin_id);
  if (updateError) binUpdateError = updateError;
  if (binUpdateError) {
    return NextResponse.json({ error: binUpdateError.message || String(binUpdateError) }, { status: 500 });
  }

  return NextResponse.json({ entry: log, latestTemperature, latestMoisture, health_status });
}