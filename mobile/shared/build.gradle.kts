// Check OS FIRST - before anything else
val osName = System.getProperty("os.name").lowercase()
val isMacOS = osName.contains("mac")

// On Windows, use Android library plugin instead of multiplatform
// This prevents iOS class initialization errors
if (isMacOS) {
    plugins {
        alias(libs.plugins.kotlin.multiplatform)
        alias(libs.plugins.kotlin.serialization)
        id("org.jetbrains.compose")
    }
    
    kotlin {
        androidTarget {
            compilations.all {
                kotlinOptions {
                    jvmTarget = "17"
                }
            }
        }
        
        val skipIosProp = project.findProperty("kotlin.mpp.skipIosTargets")?.toString()?.toBoolean() == true
        if (!skipIosProp) {
            iosX64()
            iosArm64()
            iosSimulatorArm64()
        }
        
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
            
            if (!skipIosProp) {
                val iosMain by creating {
                    dependsOn(commonMain)
                    dependencies {
                        implementation(libs.ktor.client.darwin)
                    }
                }
                
                val iosX64Main by getting { dependsOn(iosMain) }
                val iosArm64Main by getting { dependsOn(iosMain) }
                val iosSimulatorArm64Main by getting { dependsOn(iosMain) }
            }
        }
    }
} else {
    // Windows: Use Android library only (no multiplatform)
    plugins {
        alias(libs.plugins.kotlin.multiplatform)
        alias(libs.plugins.kotlin.serialization)
        id("org.jetbrains.compose")
        id("com.android.library")
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
}
