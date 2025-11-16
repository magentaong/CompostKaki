# PowerShell script to download Gradle Wrapper JAR
$wrapperDir = "gradle\wrapper"
$jarPath = "$wrapperDir\gradle-wrapper.jar"
$jarUrl = "https://raw.githubusercontent.com/gradle/gradle/v8.9.0/gradle/wrapper/gradle-wrapper.jar"

if (-not (Test-Path $wrapperDir)) {
    New-Item -ItemType Directory -Path $wrapperDir -Force | Out-Null
}

Write-Host "Downloading Gradle Wrapper JAR..."
try {
    Invoke-WebRequest -Uri $jarUrl -OutFile $jarPath
    Write-Host "Gradle Wrapper JAR downloaded successfully!"
    Write-Host "You can now run: .\gradlew.bat build"
} catch {
    Write-Host "Error downloading wrapper JAR. Please download manually from:"
    Write-Host "https://raw.githubusercontent.com/gradle/gradle/v8.9.0/gradle/wrapper/gradle-wrapper.jar"
    Write-Host "And place it in: $jarPath"
}

