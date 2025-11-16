package com.compostkaki.shared.data.repository

import com.compostkaki.shared.data.createSupabaseClient
import com.compostkaki.shared.data.models.Task
import io.github.jan.supabase.postgrest.postgrest
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.query.Columns
import kotlinx.serialization.Serializable

@Serializable
data class CreateTaskRequest(
    val bin_id: String,
    val user_id: String,
    val urgency: String,
    val effort: String,
    val description: String,
    val is_time_sensitive: Boolean = false,
    val due_date: String? = null,
    val photo_url: String? = null
)

class TaskRepository {
    private val supabase = createSupabaseClient()
    
    suspend fun getTasksForBin(binId: String): Result<List<Task>> {
        return try {
            val tasks = supabase.from("tasks")
                .select(columns = Columns.ALL) {
                    filter {
                        eq("bin_id", binId)
                    }
                    order("created_at", ascending = false)
                }
                .decodeList<Task>()
            
            Result.success(tasks)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    suspend fun createTask(
        binId: String,
        userId: String,
        urgency: String,
        effort: String,
        description: String,
        isTimeSensitive: Boolean = false,
        dueDate: String? = null,
        photoUrl: String? = null
    ): Result<Task> {
        return try {
            val task = supabase.from("tasks")
                .insert(
                    CreateTaskRequest(
                        bin_id = binId,
                        user_id = userId,
                        urgency = urgency,
                        effort = effort,
                        description = description,
                        is_time_sensitive = isTimeSensitive,
                        due_date = dueDate,
                        photo_url = photoUrl
                    )
                ) {
                    select(columns = Columns.ALL)
                }
                .decodeSingle<Task>()
            
            Result.success(task)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    suspend fun acceptTask(taskId: String, userId: String): Result<Task> {
        return try {
            val task = supabase.from("tasks")
                .update(mapOf(
                    "accepted_by" to userId,
                    "status" to "accepted"
                )) {
                    filter {
                        eq("id", taskId)
                    }
                }
                .decodeSingle<Task>()
            
            Result.success(task)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    suspend fun completeTask(taskId: String): Result<Task> {
        return try {
            val task = supabase.from("tasks")
                .update(mapOf(
                    "status" to "completed",
                    "completed_at" to kotlinx.datetime.Clock.System.now().toString()
                )) {
                    filter {
                        eq("id", taskId)
                    }
                }
                .decodeSingle<Task>()
            
            Result.success(task)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    suspend fun deleteTask(taskId: String, userId: String): Result<Unit> {
        return try {
            // Verify user owns the task
            val task = supabase.from("tasks")
                .select(columns = Columns.ALL) {
                    filter {
                        eq("id", taskId)
                    }
                }
                .decodeSingle<Task>()
            
            if (task.user_id != userId) {
                return Result.failure(Exception("Forbidden: You can only delete your own tasks"))
            }
            
            supabase.from("tasks")
                .delete {
                    filter {
                        eq("id", taskId)
                    }
                }
            
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}

