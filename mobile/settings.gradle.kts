// Check OS before loading plugins to prevent iOS initialization on Windows
val osName = System.getProperty("os.name").lowercase()
val isMacOS = osName.contains("mac")

if (!isMacOS) {
    System.setProperty("kotlin.mpp.skipIosTargets", "true")
    System.setProperty("kotlin.native.ignoreDisabledTargets", "true")
}

pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "CompostKaki"
include(":shared")
include(":androidApp")

// CRITICAL: Only include iOS app on macOS
// On Windows, don't even include the module - it will cause initialization errors
if (isMacOS) {
    val skipIos = providers.gradleProperty("kotlin.mpp.skipIosTargets").orElse("true").get().toBoolean() == true
    if (!skipIos) {
        include(":iosApp")
    }
}
