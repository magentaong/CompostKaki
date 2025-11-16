package com.compostkaki.shared.data.models

import kotlinx.serialization.Serializable

@Serializable
data class BinLog(
    val id: String,
    val bin_id: String,
    val user_id: String,
    val content: String,
    val temperature: Double? = null,
    val moisture: String? = null,
    val type: String? = null,
    val image: String? = null,
    val created_at: String? = null,
    val profiles: Profile? = null
)

@Serializable
data class Profile(
    val first_name: String? = null,
    val last_name: String? = null,
    val avatar_url: String? = null
)

