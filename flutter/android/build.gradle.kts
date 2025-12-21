allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
    
    // Fix for plugins that don't specify compileSdk (e.g., app_links)
    // This ensures all Android library projects have compileSdk set
    afterEvaluate {
        if (project.plugins.hasPlugin("com.android.library")) {
            extensions.findByType<com.android.build.gradle.LibraryExtension>()?.apply {
                if (compileSdk == null) {
                    // Get compileSdk from app module or use default
                    val appProject = rootProject.findProject(":app")
                    val defaultSdk = appProject?.let {
                        try {
                            it.extensions.findByType<com.android.build.gradle.AppExtension>()?.compileSdkVersion
                        } catch (e: Exception) {
                            null
                        }
                    } ?: 34
                    compileSdk = defaultSdk
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
