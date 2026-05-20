# Auto-installer for Ultra-Fast Bootloader tools
# Run with: PowerShell -ExecutionPolicy Bypass -File auto-install.ps1

Write-Host "Ultra-Fast Bootloader - Automatic Tool Installer" -ForegroundColor Cyan
Write-Host "=" * 60
Write-Host ""

$ErrorActionPreference = "Stop"
$ProgressPreference = 'SilentlyContinue'

# Create temp directory
$tempDir = Join-Path $env:TEMP "fastboot-tools"
if (!(Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir | Out-Null
}

Write-Host "Installing to: C:\fastboot-tools" -ForegroundColor Yellow
$installDir = "C:\fastboot-tools"
if (!(Test-Path $installDir)) {
    New-Item -ItemType Directory -Path $installDir | Out-Null
}

# Function to add to PATH
function Add-ToPath {
    param([string]$PathToAdd)
    
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($currentPath -notlike "*$PathToAdd*") {
        [Environment]::SetEnvironmentVariable(
            "Path",
            "$currentPath;$PathToAdd",
            "User"
        )
        Write-Host "  Added to PATH: $PathToAdd" -ForegroundColor Green
    }
}

# Install NASM
Write-Host "[1/4] Installing NASM Assembler..." -ForegroundColor Cyan
try {
    $nasmUrl = "https://www.nasm.us/pub/nasm/releasebuilds/2.16.03/win64/nasm-2.16.03-win64.zip"
    $nasmZip = Join-Path $tempDir "nasm.zip"
    $nasmDir = Join-Path $installDir "nasm"
    
    Write-Host "  Downloading NASM..."
    Invoke-WebRequest -Uri $nasmUrl -OutFile $nasmZip -UseBasicParsing
    
    Write-Host "  Extracting..."
    Expand-Archive -Path $nasmZip -DestinationPath $tempDir -Force
    
    if (Test-Path $nasmDir) { Remove-Item $nasmDir -Recurse -Force }
    Move-Item (Join-Path $tempDir "nasm-2.16.03") $nasmDir
    
    Add-ToPath $nasmDir
    Write-Host "  NASM installed successfully!" -ForegroundColor Green
} catch {
    Write-Host "  Failed to install NASM: $_" -ForegroundColor Red
}

# Install QEMU
Write-Host "`n[2/4] Installing QEMU..." -ForegroundColor Cyan
try {
    Write-Host "  Downloading QEMU (this may take a while)..."
    $qemuUrl = "https://qemu.weilnetz.de/w64/2024/qemu-w64-setup-20240423.exe"
    $qemuInstaller = Join-Path $tempDir "qemu-installer.exe"
    
    Invoke-WebRequest -Uri $qemuUrl -OutFile $qemuInstaller -UseBasicParsing
    
    Write-Host "  Installing QEMU..."
    Start-Process -FilePath $qemuInstaller -ArgumentList "/S" -Wait
    
    Add-ToPath "C:\Program Files\qemu"
    Write-Host "  QEMU installed successfully!" -ForegroundColor Green
} catch {
    Write-Host "  Failed to install QEMU: $_" -ForegroundColor Red
    Write-Host "  Please install manually from: https://qemu.weilnetz.de/w64/" -ForegroundColor Yellow
}

# Install Python
Write-Host "`n[3/4] Checking Python..." -ForegroundColor Cyan
try {
    $pythonCheck = Get-Command python -ErrorAction SilentlyContinue
    if ($pythonCheck) {
        Write-Host "  Python already installed!" -ForegroundColor Green
    } else {
        Write-Host "  Please install Python manually from: https://www.python.org/downloads/" -ForegroundColor Yellow
        Write-Host "  Make sure to check 'Add Python to PATH' during installation" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  Python not found" -ForegroundColor Yellow
}

# Install MinGW-w64 (WinLibs)
Write-Host "`n[4/4] Installing MinGW-w64..." -ForegroundColor Cyan
try {
    Write-Host "  Downloading MinGW-w64 (this may take a while)..."
    $mingwUrl = "https://github.com/brechtsanders/winlibs_mingw/releases/download/13.2.0-16.0.6-11.0.0-ucrt-r1/winlibs-x86_64-posix-seh-gcc-13.2.0-mingw-w64ucrt-11.0.0-r1.zip"
    $mingwZip = Join-Path $tempDir "mingw.zip"
    $mingwDir = Join-Path $installDir "mingw64"
    
    Invoke-WebRequest -Uri $mingwUrl -OutFile $mingwZip -UseBasicParsing
    
    Write-Host "  Extracting..."
    Expand-Archive -Path $mingwZip -DestinationPath $installDir -Force
    
    Add-ToPath (Join-Path $mingwDir "bin")
    Write-Host "  MinGW-w64 installed successfully!" -ForegroundColor Green
} catch {
    Write-Host "  Failed to install MinGW-w64: $_" -ForegroundColor Red
    Write-Host "  You can use build-simple.bat which doesn't require MinGW" -ForegroundColor Yellow
}

# Cleanup
Write-Host "`nCleaning up..." -ForegroundColor Cyan
Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "`n" + "=" * 60
Write-Host "Installation Complete!" -ForegroundColor Green
Write-Host "=" * 60
Write-Host ""
Write-Host "IMPORTANT: Please restart your terminal for PATH changes to take effect!" -ForegroundColor Yellow
Write-Host ""
Write-Host "After restarting, run:" -ForegroundColor Cyan
Write-Host "  .\install-tools.bat    - to verify installation"
Write-Host "  .\build-simple.bat     - to build the bootloader"
Write-Host "  .\run-simple.bat       - to run in QEMU"
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
