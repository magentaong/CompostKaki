package com.compostkaki.shared.data.models

import kotlinx.serialization.Serializable

@Serializable
data class Bin(
    val id: String,
    val name: String,
    val location: String? = null,
    val user_id: String,
    val contributors: Int = 0,
    val progress: Int = 0,
    val health_status: String = "Healthy",
    val qr_code: String? = null,
    val latest_temperature: Double? = null,
    val latest_moisture: String? = null,
    val latest_flips: Int = 0,
    val created_at: String? = null,
    val contributors_list: List<String>? = null
)

