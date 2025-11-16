package com.compostkaki.shared.ui.screens.scanner

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.compostkaki.shared.ui.theme.CompostKakiTheme

@Composable
fun ScannerScreen(
    onBinScanned: (String) -> Unit,
    onNavigateBack: () -> Unit
) {
    CompostKakiTheme {
        Scaffold(
            topBar = {
                TopAppBar(
                    title = { Text("Scan QR Code") },
                    navigationIcon = {
                        IconButton(onClick = onNavigateBack) {
                            Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                        }
                    }
                )
            }
        ) { padding ->
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding),
                contentAlignment = Alignment.Center
            ) {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    Text(
                        text = "QR Scanner",
                        style = MaterialTheme.typography.headlineMedium
                    )
                    Text(
                        text = "Point your camera at a bin QR code to join",
                        style = MaterialTheme.typography.bodyMedium
                    )
                    // TODO: Integrate QR code scanner library
                    // For now, placeholder
                    Button(
                        onClick = {
                            // Simulate scan for demo
                            // In real app, use a QR scanner library
                        }
                    ) {
                        Text("Scan QR Code")
                    }
                }
            }
        }
    }
}

