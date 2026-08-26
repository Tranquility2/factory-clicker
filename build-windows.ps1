<#
.SYNOPSIS
    Builds the native Windows desktop release binary for Factory Clicker.
.DESCRIPTION
    Prerequisites on Windows host:
      1. Flutter SDK on PATH (https://docs.flutter.dev/get-started/install/windows)
      2. Visual Studio 2022 (or Build Tools) with "Desktop development with C++" workload
.EXAMPLE
    .\build-windows.ps1
    .\build-windows.ps1 -Clean -Run
#>

param(
    [switch]$Clean,
    [switch]$Run
)

$ErrorActionPreference = "Stop"

Write-Host "==> Checking Flutter SDK on Windows host..." -ForegroundColor Cyan
if (-not (Get-Command "flutter" -ErrorAction SilentlyContinue)) {
    Write-Error "Flutter CLI not found on PATH. Please install Flutter for Windows and add it to your PATH."
    exit 1
}

if ($Clean) {
    Write-Host "==> Cleaning previous build artifacts..." -ForegroundColor Yellow
    flutter clean
}

Write-Host "==> Resolving dependencies..." -ForegroundColor Cyan
flutter pub get

Write-Host "==> Building Factory Clicker for Windows (x64 Release)..." -ForegroundColor Green
flutter build windows --release

$outputDir = "build\windows\x64\runner\Release"
$exePath = "$outputDir\factory_clicker.exe"

if (Test-Path $exePath) {
    Write-Host "`n✔ Build successful!" -ForegroundColor Green
    Write-Host "Executable location: $exePath" -ForegroundColor Cyan
    Write-Host "Full release bundle: $outputDir" -ForegroundColor Cyan

    if ($Run) {
        Write-Host "==> Launching $exePath..." -ForegroundColor Green
        Start-Process -FilePath $exePath
    }
} else {
    Write-Error "Build finished but $exePath was not found."
    exit 1
}
