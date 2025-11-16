package com.compostkaki.shared.data.models

import kotlinx.serialization.Serializable

@Serializable
data class Task(
    val id: String,
    val bin_id: String,
    val user_id: String,
    val urgency: String,
    val effort: String,
    val description: String,
    val is_time_sensitive: Boolean = false,
    val due_date: String? = null,
    val photo_url: String? = null,
    val status: String = "open",
    val accepted_by: String? = null,
    val created_at: String? = null,
    val completed_at: String? = null
)

