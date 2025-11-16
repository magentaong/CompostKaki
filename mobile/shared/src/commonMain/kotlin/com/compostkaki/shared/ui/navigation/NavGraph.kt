package com.compostkaki.shared.ui.navigation

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import com.compostkaki.shared.ui.screens.auth.AuthScreen
import com.compostkaki.shared.ui.screens.home.HomeScreen
import com.compostkaki.shared.ui.screens.bin.BinDetailScreen
import com.compostkaki.shared.ui.screens.bin.AddBinScreen
import com.compostkaki.shared.ui.screens.log.LogActivityScreen
import com.compostkaki.shared.ui.screens.task.TaskDetailScreen
import com.compostkaki.shared.ui.screens.scanner.ScannerScreen

sealed class Screen {
    object Auth : Screen()
    object Home : Screen()
    object AddBin : Screen()
    data class BinDetail(val binId: String) : Screen()
    data class LogActivity(val binId: String) : Screen()
    data class TaskDetail(val taskId: String) : Screen()
    object Scanner : Screen()
}

@Composable
fun NavGraph(
    modifier: Modifier = Modifier,
    startScreen: Screen = Screen.Auth
) {
    var currentScreen by remember { mutableStateOf<Screen>(startScreen) }
    
    when (val screen = currentScreen) {
        is Screen.Auth -> {
            AuthScreen(
                onSignInSuccess = {
                    currentScreen = Screen.Home
                }
            )
        }
        
        is Screen.Home -> {
            HomeScreen(
                onNavigateToBinDetail = { binId ->
                    currentScreen = Screen.BinDetail(binId)
                },
                onNavigateToAddBin = {
                    currentScreen = Screen.AddBin
                },
                onNavigateToScanner = {
                    currentScreen = Screen.Scanner
                },
                onSignOut = {
                    currentScreen = Screen.Auth
                }
            )
        }
        
        is Screen.AddBin -> {
            AddBinScreen(
                onBinCreated = { binId ->
                    currentScreen = Screen.BinDetail(binId)
                },
                onNavigateBack = {
                    currentScreen = Screen.Home
                }
            )
        }
        
        is Screen.BinDetail -> {
            BinDetailScreen(
                binId = screen.binId,
                onNavigateToLogActivity = {
                    currentScreen = Screen.LogActivity(screen.binId)
                },
                onNavigateToTaskDetail = { taskId ->
                    currentScreen = Screen.TaskDetail(taskId)
                },
                onNavigateBack = {
                    currentScreen = Screen.Home
                }
            )
        }
        
        is Screen.LogActivity -> {
            LogActivityScreen(
                binId = screen.binId,
                onLogCreated = {
                    currentScreen = Screen.BinDetail(screen.binId)
                },
                onNavigateBack = {
                    currentScreen = Screen.BinDetail(screen.binId)
                }
            )
        }
        
        is Screen.TaskDetail -> {
            TaskDetailScreen(
                taskId = screen.taskId,
                onNavigateBack = {
                    // Navigate back to previous screen (could be improved with a back stack)
                    currentScreen = Screen.Home
                }
            )
        }
        
        is Screen.Scanner -> {
            ScannerScreen(
                onBinScanned = { binId ->
                    currentScreen = Screen.BinDetail(binId)
                },
                onNavigateBack = {
                    currentScreen = Screen.Home
                }
            )
        }
    }
}

