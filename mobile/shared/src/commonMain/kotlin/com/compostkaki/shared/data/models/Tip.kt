package com.compostkaki.shared.data.models

import kotlinx.serialization.Serializable

@Serializable
data class Tip(
    val id: String,
    val title: String,
    val content: String,
    val category: String? = null
)

