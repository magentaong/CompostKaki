// This init script runs BEFORE plugins are loaded
// It prevents iOS target initialization on Windows

val osName = System.getProperty("os.name").lowercase()
val isMacOS = osName.contains("mac")

if (!isMacOS) {
    // Set system properties to prevent iOS initialization
    System.setProperty("kotlin.mpp.skipIosTargets", "true")
    System.setProperty("kotlin.native.ignoreDisabledTargets", "true")
    
    // Try to prevent KonanTarget initialization
    try {
        // This might help prevent the class from being loaded
        System.setProperty("kotlin.native.home", "")
    } catch (e: Exception) {
        // Ignore
    }
}

