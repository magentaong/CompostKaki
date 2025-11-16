package com.compostkaki.shared.ui.screens.task

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.compostkaki.shared.data.models.Task
import com.compostkaki.shared.data.repository.AuthRepository
import com.compostkaki.shared.data.repository.TaskRepository
import com.compostkaki.shared.ui.theme.CompostKakiTheme

@Composable
fun TaskDetailScreen(
    taskId: String,
    onNavigateBack: () -> Unit
) {
    var task by remember { mutableStateOf<Task?>(null) }
    var isLoading by remember { mutableStateOf(true) }
    
    val taskRepository = remember { TaskRepository() }
    val authRepository = remember { AuthRepository() }
    
    LaunchedEffect(taskId) {
        // Fetch task details
        // taskRepository.getTaskById(taskId).onSuccess {
        //     task = it
        // }
        isLoading = false
    }
    
    CompostKakiTheme {
        Scaffold(
            topBar = {
                TopAppBar(
                    title = { Text("Task Details") },
                    navigationIcon = {
                        IconButton(onClick = onNavigateBack) {
                            Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                        }
                    }
                )
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
                task?.let {
                    Column(
                        modifier = Modifier
                            .fillMaxSize()
                            .padding(padding)
                            .padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        Text(
                            text = it.description,
                            style = MaterialTheme.typography.headlineSmall
                        )
                        Text(
                            text = "Urgency: ${it.urgency}",
                            style = MaterialTheme.typography.bodyLarge
                        )
                        Text(
                            text = "Effort: ${it.effort}",
                            style = MaterialTheme.typography.bodyLarge
                        )
                        Text(
                            text = "Status: ${it.status}",
                            style = MaterialTheme.typography.bodyMedium
                        )
                        
                        if (it.status == "open") {
                            Button(
                                onClick = {
                                    // Accept task
                                    // val user = authRepository.getCurrentUser()
                                    // if (user != null) {
                                    //     taskRepository.acceptTask(taskId, user.id)
                                    // }
                                },
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Text("Accept Task")
                            }
                        }
                        
                        if (it.status == "accepted") {
                            Button(
                                onClick = {
                                    // Complete task
                                    // taskRepository.completeTask(taskId)
                                },
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Text("Mark as Complete")
                            }
                        }
                    }
                }
            }
        }
    }
}

