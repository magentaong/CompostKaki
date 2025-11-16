// Android-only build file for Windows
// Use this instead of build.gradle.kts on Windows

plugins {
    alias(libs.plugins.kotlin.multiplatform)
    alias(libs.plugins.kotlin.serialization)
    id("org.jetbrains.compose")
    id("com.android.library")
}

kotlin {
    androidTarget {
        compilations.all {
            kotlinOptions {
                jvmTarget = "17"
            }
        }
    }
    
    // NO iOS targets on Windows
    
    sourceSets {
        val commonMain by getting {
            dependencies {
                implementation(compose.runtime)
                implementation(compose.foundation)
                implementation(compose.material3)
                implementation(compose.materialIconsExtended)
                implementation(compose.components.resources)
                implementation(compose.components.uiToolingPreview)
                
                implementation(libs.bundles.supabase)
                implementation(libs.bundles.ktor)
                implementation(libs.kotlinx.serialization.json)
                implementation(libs.kotlinx.coroutines.core)
                implementation(libs.koin.core)
                implementation(libs.koin.compose)
                implementation(libs.napier)
                implementation(libs.coil.compose)
            }
        }
        
        val androidMain by getting {
            dependencies {
                implementation(libs.ktor.client.android)
            }
        }
    }
}

android {
    namespace = "com.compostkaki.shared"
    compileSdk = 35
    
    defaultConfig {
        minSdk = 24
    }
    
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

