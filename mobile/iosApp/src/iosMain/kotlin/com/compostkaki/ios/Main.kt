package com.compostkaki.ios

import androidx.compose.ui.window.ComposeUIViewController
import com.compostkaki.shared.ui.navigation.NavGraph
import platform.UIKit.UIViewController

fun MainViewController(): UIViewController =
    ComposeUIViewController { NavGraph() }

