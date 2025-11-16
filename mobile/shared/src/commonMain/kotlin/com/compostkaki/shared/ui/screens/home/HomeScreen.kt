package com.compostkaki.shared.ui.screens.home

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.QrCodeScanner
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.compostkaki.shared.data.models.Bin
import com.compostkaki.shared.data.repository.AuthRepository
import com.compostkaki.shared.data.repository.BinRepository
import com.compostkaki.shared.ui.theme.CompostKakiTheme

@Composable
fun HomeScreen(
    onNavigateToBinDetail: (String) -> Unit,
    onNavigateToAddBin: () -> Unit,
    onNavigateToScanner: () -> Unit,
    onSignOut: () -> Unit
) {
    var bins by remember { mutableStateOf<List<Bin>>(emptyList()) }
    var isLoading by remember { mutableStateOf(false) }
    
    val authRepository = remember { AuthRepository() }
    val binRepository = remember { BinRepository() }
    
    LaunchedEffect(Unit) {
        isLoading = true
        val user = authRepository.getCurrentUser()
        if (user != null) {
            binRepository.getBinsForUser(user.id).onSuccess {
                bins = it
            }
        }
        isLoading = false
    }
    
    CompostKakiTheme {
        Scaffold(
            topBar = {
                TopAppBar(
                    title = { Text("CompostKaki") },
                    actions = {
                        IconButton(onClick = onNavigateToScanner) {
                            Icon(Icons.Default.QrCodeScanner, contentDescription = "Scan QR")
                        }
                        IconButton(onClick = onSignOut) {
                            Text("Sign Out")
                        }
                    }
                )
            },
            floatingActionButton = {
                FloatingActionButton(onClick = onNavigateToAddBin) {
                    Icon(Icons.Default.Add, contentDescription = "Add Bin")
                }
            }
        ) { padding ->
            if (isLoading) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(padding),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator()
                }
            } else if (bins.isEmpty()) {
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
                        Text("No bins yet")
                        Button(onClick = onNavigateToAddBin) {
                            Text("Create Your First Bin")
                        }
                    }
                }
            } else {
                LazyColumn(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(padding),
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(bins) { bin ->
                        BinCard(
                            bin = bin,
                            onClick = { onNavigateToBinDetail(bin.id) }
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun BinCard(
    bin: Bin,
    onClick: () -> Unit
) {
    Card(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Text(
                text = bin.name,
                style = MaterialTheme.typography.titleLarge
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = bin.location ?: "",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(modifier = Modifier.height(8.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = "Health: ${bin.health_status}",
                    style = MaterialTheme.typography.bodySmall
                )
                Text(
                    text = "${bin.contributors} contributors",
                    style = MaterialTheme.typography.bodySmall
                )
            }
        }
    }
}

