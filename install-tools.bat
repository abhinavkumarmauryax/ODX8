@echo off
REM Script to help install required tools on Windows

echo Ultra-Fast Bootloader - Tool Installation Guide
echo ================================================
echo.

echo This script will guide you through installing the required tools.
echo.

REM Check what's already installed
echo Checking installed tools...
echo.

set MISSING=0

where nasm >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [OK] NASM assembler found
) else (
    echo [MISSING] NASM assembler
    set MISSING=1
)

where ld >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [OK] ld linker found
) else (
    echo [MISSING] ld linker ^(MinGW-w64^)
    set MISSING=1
)

where qemu-system-x86_64 >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [OK] QEMU found
) else (
    echo [MISSING] QEMU
    set MISSING=1
)

where python >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [OK] Python found
) else (
    echo [MISSING] Python
    set MISSING=1
)

echo.

if %MISSING% EQU 0 (
    echo All required tools are installed!
    echo You can now run: build.bat
    exit /b 0
)

echo.
echo ================================================
echo Installation Instructions
echo ================================================
echo.

where nasm >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo 1. NASM Assembler
    echo    Download: https://www.nasm.us/pub/nasm/releasebuilds/
    echo    - Get the latest win64 installer
    echo    - Run installer and add to PATH
    echo.
)

where ld >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo 2. MinGW-w64 ^(for ld linker^)
    echo    Option A - WinLibs standalone build ^(RECOMMENDED^):
    echo    Download: https://winlibs.com/
    echo    - Get "UCRT runtime" version
    echo    - Extract to C:\mingw64
    echo    - Add C:\mingw64\bin to PATH
    echo.
    echo    Option B - MSYS2:
    echo    Download: https://www.msys2.org/
    echo    - Install MSYS2
    echo    - Run: pacman -S mingw-w64-x86_64-gcc
    echo    - Add C:\msys64\mingw64\bin to PATH
    echo.
)

where qemu-system-x86_64 >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo 3. QEMU
    echo    Download: https://qemu.weilnetz.de/w64/
    echo    - Get the latest installer
    echo    - Run installer and add to PATH
    echo.
)

where python >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo 4. Python 3
    echo    Download: https://www.python.org/downloads/
    echo    - Get latest Python 3.x
    echo    - Check "Add Python to PATH" during installation
    echo.
)

echo ================================================
echo Quick Install with Chocolatey ^(Optional^)
echo ================================================
echo.
echo If you have Chocolatey package manager:
echo   choco install nasm qemu python mingw
echo.
echo Or with Scoop:
echo   scoop install nasm mingw qemu python
echo.

echo After installing, restart your terminal and run this script again.
pause
