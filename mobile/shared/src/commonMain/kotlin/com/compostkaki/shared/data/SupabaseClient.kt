package com.compostkaki.shared.data

import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.createSupabaseClient
import io.github.jan.supabase.gotrue.auth
import io.github.jan.supabase.postgrest.postgrest
import io.github.jan.supabase.storage.storage
import io.github.jan.supabase.realtime.realtime

object SupabaseConfig {
    // These should be set from environment or config
    const val SUPABASE_URL = "https://tqpjrlwdgoctacfrbanf.supabase.co"
    const val SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRxcGpybHdkZ29jdGFjZnJiYW5mIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEwMTU5NTIsImV4cCI6MjA2NjU5MTk1Mn0.x94UQ4jY3FhvxxTrRzuZsVgrAL3vmi3qJ_GolN9uHxQ"
}

fun createSupabaseClient(): SupabaseClient {
    return createSupabaseClient(
        supabaseUrl = SupabaseConfig.SUPABASE_URL,
        supabaseKey = SupabaseConfig.SUPABASE_ANON_KEY
    ) {
        install(io.github.jan.supabase.gotrue.Auth)
        install(io.github.jan.supabase.postgrest.Postgrest)
        install(io.github.jan.supabase.storage.Storage)
        install(io.github.jan.supabase.realtime.Realtime)
    }
}

