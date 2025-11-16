package com.compostkaki.shared.data.repository

import com.compostkaki.shared.data.createSupabaseClient
import com.compostkaki.shared.data.models.BinLog
import io.github.jan.supabase.postgrest.postgrest
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.query.Columns
import kotlinx.serialization.Serializable

@Serializable
data class CreateLogRequest(
    val bin_id: String,
    val user_id: String,
    val content: String,
    val temperature: Double? = null,
    val moisture: String? = null,
    val type: String? = null,
    val image: String? = null
)

class LogRepository {
    private val supabase = createSupabaseClient()
    
    suspend fun getLogsForBin(binId: String): Result<List<BinLog>> {
        return try {
            val logs = supabase.from("bin_logs")
                .select(columns = Columns.ALL) {
                    filter {
                        eq("bin_id", binId)
                    }
                    order("created_at", ascending = false)
                }
                .decodeList<BinLog>()
            
            Result.success(logs)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    suspend fun createLog(
        binId: String,
        userId: String,
        content: String,
        temperature: Double? = null,
        moisture: String? = null,
        type: String? = null,
        image: String? = null
    ): Result<BinLog> {
        return try {
            val log = supabase.from("bin_logs")
                .insert(
                    CreateLogRequest(
                        bin_id = binId,
                        user_id = userId,
                        content = content,
                        temperature = temperature,
                        moisture = moisture,
                        type = type,
                        image = image
                    )
                ) {
                    select(columns = Columns.ALL)
                }
                .decodeSingle<BinLog>()
            
            Result.success(log)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}

