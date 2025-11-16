package com.compostkaki.shared.ui.screens.bin

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.compostkaki.shared.data.repository.AuthRepository
import com.compostkaki.shared.data.repository.BinRepository
import com.compostkaki.shared.ui.theme.CompostKakiTheme

@Composable
fun AddBinScreen(
    onBinCreated: (String) -> Unit,
    onNavigateBack: () -> Unit
) {
    var binName by remember { mutableStateOf("") }
    var isLoading by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    
    val authRepository = remember { AuthRepository() }
    val binRepository = remember { BinRepository() }
    
    CompostKakiTheme {
        Scaffold(
            topBar = {
                TopAppBar(
                    title = { Text("Add New Bin") },
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
                Text(
                    text = "Tip: Name your bin after its location, e.g., Dakota Crescent",
                    style = MaterialTheme.typography.bodyMedium
                )
                
                OutlinedTextField(
                    value = binName,
                    onValueChange = { binName = it },
                    label = { Text("Bin Name") },
                    placeholder = { Text("e.g. Dakota Crescent") },
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
                        if (binName.isBlank()) {
                            errorMessage = "Bin name is required"
                            return@Button
                        }
                        isLoading = true
                        errorMessage = null
                        
                        // Create bin
                        // val user = authRepository.getCurrentUser()
                        // if (user != null) {
                        //     binRepository.createBin(binName, user.id).onSuccess {
                        //         onBinCreated(it.id)
                        //     }.onFailure {
                        //         errorMessage = it.message
                        //     }
                        // }
                        isLoading = false
                    },
                    modifier = Modifier.fillMaxWidth(),
                    enabled = !isLoading && binName.isNotBlank()
                ) {
                    if (isLoading) {
                        CircularProgressIndicator(modifier = Modifier.size(16.dp))
                    } else {
                        Text("Create Bin")
                    }
                }
            }
        }
    }
}

