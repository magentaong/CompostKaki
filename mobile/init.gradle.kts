// Init script to prevent iOS target initialization on Windows
val osName = System.getProperty("os.name").lowercase()
val isMacOS = osName.contains("mac")

if (!isMacOS) {
    // Set system property to skip iOS targets
    System.setProperty("kotlin.mpp.skipIosTargets", "true")
}

