@echo off
REM Wrapper script that prevents iOS initialization on Windows
REM Sets JVM properties BEFORE Gradle loads plugins

set GRADLE_OPTS=-Dkotlin.mpp.skipIosTargets=true -Dkotlin.native.ignoreDisabledTargets=true -Dkotlin.native.binary.memoryModel=experimental

REM Also set as environment variable
set KOTLIN_MPP_SKIP_IOS_TARGETS=true
set KOTLIN_NATIVE_IGNORE_DISABLED_TARGETS=true

call gradlew.bat %* --no-daemon

