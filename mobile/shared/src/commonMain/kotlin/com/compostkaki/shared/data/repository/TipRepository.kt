package com.compostkaki.shared.data.repository

import com.compostkaki.shared.data.createSupabaseClient
import com.compostkaki.shared.data.models.Tip
import io.github.jan.supabase.postgrest.postgrest
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.query.Columns

class TipRepository {
    private val supabase = createSupabaseClient()
    
    suspend fun getTips(): Result<List<Tip>> {
        return try {
            val tips = supabase.from("tips")
                .select(columns = Columns.ALL)
                .decodeList<Tip>()
            
            Result.success(tips)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}

