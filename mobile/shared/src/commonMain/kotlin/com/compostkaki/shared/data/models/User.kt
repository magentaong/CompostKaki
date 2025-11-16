package com.compostkaki.shared.data.models

import kotlinx.serialization.Serializable

@Serializable
data class User(
    val id: String,
    val email: String,
    val user_metadata: UserMetadata? = null
)

@Serializable
data class UserMetadata(
    val first_name: String? = null,
    val last_name: String? = null,
    val avatar_url: String? = null
)

@Serializable
data class AuthResponse(
    val user: User? = null,
    val session: Session? = null,
    val error: String? = null
)

@Serializable
data class Session(
    val access_token: String,
    val refresh_token: String,
    val expires_at: Long? = null
)

