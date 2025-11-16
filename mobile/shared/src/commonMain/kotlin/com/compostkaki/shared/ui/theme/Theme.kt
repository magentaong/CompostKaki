package com.compostkaki.shared.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable

private val LightColorScheme = lightColorScheme(
    primary = androidx.compose.ui.graphics.Color(0xFF00796B),
    secondary = androidx.compose.ui.graphics.Color(0xFF005A4B),
    tertiary = androidx.compose.ui.graphics.Color(0xFFE6FFF3),
    background = androidx.compose.ui.graphics.Color(0xFFF3F3F3),
    surface = androidx.compose.ui.graphics.Color.White
)

@Composable
fun CompostKakiTheme(
    content: @Composable () -> Unit
) {
    MaterialTheme(
        colorScheme = LightColorScheme,
        content = content
    )
}

