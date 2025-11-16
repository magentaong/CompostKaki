package com.compostkaki.shared.data.repository

import com.compostkaki.shared.data.SupabaseConfig
import com.compostkaki.shared.data.createSupabaseClient
import com.compostkaki.shared.data.models.AuthResponse
import com.compostkaki.shared.data.models.User
import io.github.jan.supabase.gotrue.auth
import io.github.jan.supabase.gotrue.providers.builtin.Email
import io.github.jan.supabase.postgrest.postgrest
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.query.Columns
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.serialization.Serializable

@Serializable
data class ProfileData(
    val id: String,
    val first_name: String? = null,
    val last_name: String? = null
)

class AuthRepository {
    private val supabase = createSupabaseClient()
    
    suspend fun signUp(email: String, password: String, firstName: String, lastName: String): Result<AuthResponse> {
        return try {
            val result = supabase.auth.signUpWith(Email) {
                this.email = email
                this.password = password
                data = mapOf(
                    "first_name" to firstName,
                    "last_name" to lastName
                )
            }
            
            // Insert into profiles table
            result.user?.id?.let { userId ->
                supabase.from("profiles").insert(
                    ProfileData(
                        id = userId,
                        first_name = firstName,
                        last_name = lastName
                    )
                )
            }
            
            Result.success(
                AuthResponse(
                    user = result.user?.let { 
                        User(
                            id = it.id,
                            email = it.email ?: "",
                            user_metadata = it.userMetadata?.let { meta ->
                                com.compostkaki.shared.data.models.UserMetadata(
                                    first_name = meta["first_name"] as? String,
                                    last_name = meta["last_name"] as? String
                                )
                            }
                        )
                    },
                    session = result.session?.let {
                        com.compostkaki.shared.data.models.Session(
                            access_token = it.accessToken,
                            refresh_token = it.refreshToken ?: "",
                            expires_at = it.expiresAt
                        )
                    }
                )
            )
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    suspend fun signIn(email: String, password: String): Result<AuthResponse> {
        return try {
            val result = supabase.auth.signInWith(Email) {
                this.email = email
                this.password = password
            }
            
            Result.success(
                AuthResponse(
                    user = result.user?.let { 
                        User(
                            id = it.id,
                            email = it.email ?: "",
                            user_metadata = it.userMetadata?.let { meta ->
                                com.compostkaki.shared.data.models.UserMetadata(
                                    first_name = meta["first_name"] as? String,
                                    last_name = meta["last_name"] as? String
                                )
                            }
                        )
                    },
                    session = result.session?.let {
                        com.compostkaki.shared.data.models.Session(
                            access_token = it.accessToken,
                            refresh_token = it.refreshToken ?: "",
                            expires_at = it.expiresAt
                        )
                    }
                )
            )
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    suspend fun signOut(): Result<Unit> {
        return try {
            supabase.auth.signOut()
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    suspend fun getCurrentUser(): User? {
        return try {
            val user = supabase.auth.currentUserOrNull()
            user?.let {
                User(
                    id = it.id,
                    email = it.email ?: "",
                    user_metadata = it.userMetadata?.let { meta ->
                        com.compostkaki.shared.data.models.UserMetadata(
                            first_name = meta["first_name"] as? String,
                            last_name = meta["last_name"] as? String
                        )
                    }
                )
            }
        } catch (e: Exception) {
            null
        }
    }
    
    suspend fun checkEmailExists(email: String): Result<Boolean> {
        return try {
            // This would typically call your API endpoint
            // For now, we'll try to sign in and catch the error
            val result = supabase.auth.signInWith(Email) {
                this.email = email
                this.password = "dummy" // This will fail but tell us if email exists
            }
            Result.success(true)
        } catch (e: Exception) {
            // Check error message to determine if email exists
            Result.success(e.message?.contains("Invalid login credentials") == true)
        }
    }
}

