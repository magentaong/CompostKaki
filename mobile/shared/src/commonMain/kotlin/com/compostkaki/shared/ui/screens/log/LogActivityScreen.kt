package com.compostkaki.shared.ui.screens.log

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.compostkaki.shared.data.repository.AuthRepository
import com.compostkaki.shared.data.repository.LogRepository
import com.compostkaki.shared.ui.theme.CompostKakiTheme

@Composable
fun LogActivityScreen(
    binId: String,
    onLogCreated: () -> Unit,
    onNavigateBack: () -> Unit
) {
    var content by remember { mutableStateOf("") }
    var temperature by remember { mutableStateOf("") }
    var moisture by remember { mutableStateOf<String?>(null) }
    var type by remember { mutableStateOf("") }
    var isLoading by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    
    val authRepository = remember { AuthRepository() }
    val logRepository = remember { LogRepository() }
    
    CompostKakiTheme {
        Scaffold(
            topBar = {
                TopAppBar(
                    title = { Text("Log Activity") },
                    navigationIcon = {
                        IconButton(onClick = onNavigateBack) {
                            Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                        }
                    }
                )
            }
        ) { padding ->
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                OutlinedTextField(
                    value = content,
                    onValueChange = { content = it },
                    label = { Text("Content") },
                    modifier = Modifier.fillMaxWidth(),
                    minLines = 3
                )
                
                OutlinedTextField(
                    value = temperature,
                    onValueChange = { temperature = it },
                    label = { Text("Temperature (°C)") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true
                )
                
                // Moisture dropdown
                var expanded by remember { mutableStateOf(false) }
                ExposedDropdownMenuBox(
                    expanded = expanded,
                    onExpandedChange = { expanded = !expanded }
                ) {
                    OutlinedTextField(
                        value = moisture ?: "",
                        onValueChange = {},
                        readOnly = true,
                        label = { Text("Moisture") },
                        modifier = Modifier
                            .fillMaxWidth()
                            .menuAnchor(),
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) }
                    )
                    ExposedDropdownMenu(
                        expanded = expanded,
                        onDismissRequest = { expanded = false }
                    ) {
                        listOf("Perfect", "Wet", "Dry", "Very Wet", "Very Dry").forEach { option ->
                            DropdownMenuItem(
                                text = { Text(option) },
                                onClick = {
                                    moisture = option
                                    expanded = false
                                }
                            )
                        }
                    }
                }
                
                OutlinedTextField(
                    value = type,
                    onValueChange = { type = it },
                    label = { Text("Type (e.g., Add Materials, Turn Pile)") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true
                )
                
                if (errorMessage != null) {
                    Text(
                        text = errorMessage!!,
                        color = MaterialTheme.colorScheme.error
                    )
                }
                
                Button(
                    onClick = {
                        if (content.isBlank()) {
                            errorMessage = "Content is required"
                            return@Button
                        }
                        isLoading = true
                        errorMessage = null
                        
                        // Create log
                        // val user = authRepository.getCurrentUser()
                        // if (user != null) {
                        //     logRepository.createLog(
                        //         binId = binId,
                        //         userId = user.id,
                        //         content = content,
                        //         temperature = temperature.toDoubleOrNull(),
                        //         moisture = moisture,
                        //         type = type.ifBlank { null }
                        //     ).onSuccess {
                        //         onLogCreated()
                        //     }.onFailure {
                        //         errorMessage = it.message
                        //     }
                        // }
                        isLoading = false
                    },
                    modifier = Modifier.fillMaxWidth(),
                    enabled = !isLoading && content.isNotBlank()
                ) {
                    if (isLoading) {
                        CircularProgressIndicator(modifier = Modifier.size(16.dp))
                    } else {
                        Text("Create Log")
                    }
                }
            }
        }
    }
}

