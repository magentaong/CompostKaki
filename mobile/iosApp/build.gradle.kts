plugins {
    alias(libs.plugins.kotlin.multiplatform)
}

kotlin {
    iosX64()
    iosArm64()
    iosSimulatorArm64()
    
    sourceSets {
        val iosMain by creating {
            dependencies {
                implementation(project(":shared"))
            }
        }
        
        val iosX64Main by getting {
            dependsOn(iosMain)
        }
        
        val iosArm64Main by getting {
            dependsOn(iosMain)
        }
        
        val iosSimulatorArm64Main by getting {
            dependsOn(iosMain)
        }
    }
}

