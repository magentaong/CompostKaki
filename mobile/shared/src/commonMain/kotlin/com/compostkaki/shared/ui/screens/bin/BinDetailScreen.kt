package com.compostkaki.shared.ui.screens.bin

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.compostkaki.shared.data.models.Bin
import com.compostkaki.shared.data.models.BinLog
import com.compostkaki.shared.data.models.Task
import com.compostkaki.shared.data.repository.BinRepository
import com.compostkaki.shared.data.repository.LogRepository
import com.compostkaki.shared.data.repository.TaskRepository
import com.compostkaki.shared.ui.theme.CompostKakiTheme

@Composable
fun BinDetailScreen(
    binId: String,
    onNavigateToLogActivity: () -> Unit,
    onNavigateToTaskDetail: (String) -> Unit,
    onNavigateBack: () -> Unit
) {
    var bin by remember { mutableStateOf<Bin?>(null) }
    var logs by remember { mutableStateOf<List<BinLog>>(emptyList()) }
    var tasks by remember { mutableStateOf<List<Task>>(emptyList()) }
    var isLoading by remember { mutableStateOf(true) }
    
    val binRepository = remember { BinRepository() }
    val logRepository = remember { LogRepository() }
    val taskRepository = remember { TaskRepository() }
    
    LaunchedEffect(binId) {
        isLoading = true
        binRepository.getBinById(binId).onSuccess {
            bin = it
        }
        logRepository.getLogsForBin(binId).onSuccess {
            logs = it
        }
        taskRepository.getTasksForBin(binId).onSuccess {
            tasks = it
        }
        isLoading = false
    }
    
    CompostKakiTheme {
        Scaffold(
            topBar = {
                TopAppBar(
                    title = { Text(bin?.name ?: "Bin Details") },
                    navigationIcon = {
                        IconButton(onClick = onNavigateBack) {
                            Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                        }
                    }
                )
            },
            floatingActionButton = {
                FloatingActionButton(onClick = onNavigateToLogActivity) {
                    Text("+ Log")
                }
            }
        ) { padding ->
            if (isLoading) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(padding),
                    contentAlignment = androidx.compose.ui.Alignment.Center
                ) {
                    CircularProgressIndicator()
                }
            } else {
                LazyColumn(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(padding),
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    item {
                        bin?.let {
                            BinInfoCard(bin = it)
                        }
                    }
                    
                    item {
                        Text(
                            text = "Recent Logs",
                            style = MaterialTheme.typography.titleMedium
                        )
                    }
                    
                    items(logs.take(5)) { log ->
                        LogCard(log = log)
                    }
                    
                    item {
                        Text(
                            text = "Tasks",
                            style = MaterialTheme.typography.titleMedium
                        )
                    }
                    
                    items(tasks) { task ->
                        TaskCard(
                            task = task,
                            onClick = { onNavigateToTaskDetail(task.id) }
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun BinInfoCard(bin: Bin) {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Text(
                text = bin.name,
                style = MaterialTheme.typography.headlineSmall
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "Health: ${bin.health_status}",
                style = MaterialTheme.typography.bodyLarge
            )
            Text(
                text = "Contributors: ${bin.contributors}",
                style = MaterialTheme.typography.bodyMedium
            )
            bin.latest_temperature?.let {
                Text(
                    text = "Temperature: ${it}°C",
                    style = MaterialTheme.typography.bodyMedium
                )
            }
            bin.latest_moisture?.let {
                Text(
                    text = "Moisture: $it",
                    style = MaterialTheme.typography.bodyMedium
                )
            }
        }
    }
}

@Composable
fun LogCard(log: BinLog) {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier.padding(12.dp)
        ) {
            Text(
                text = log.content,
                style = MaterialTheme.typography.bodyMedium
            )
            log.temperature?.let {
                Text(
                    text = "Temp: ${it}°C",
                    style = MaterialTheme.typography.bodySmall
                )
            }
            log.moisture?.let {
                Text(
                    text = "Moisture: $it",
                    style = MaterialTheme.typography.bodySmall
                )
            }
        }
    }
}

@Composable
fun TaskCard(
    task: Task,
    onClick: () -> Unit
) {
    Card(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier.padding(12.dp)
        ) {
            Text(
                text = task.description,
                style = MaterialTheme.typography.bodyMedium
            )
            Text(
                text = "Urgency: ${task.urgency} | Effort: ${task.effort}",
                style = MaterialTheme.typography.bodySmall
            )
            Text(
                text = "Status: ${task.status}",
                style = MaterialTheme.typography.bodySmall
            )
        }
    }
}

