@echo off
REM Run ODX8 Operating System in QEMU

echo Starting ODX8 Operating System...
echo.

where qemu-system-x86_64 >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: QEMU not found!
    exit /b 1
)

if exist odx8.iso (
    echo Running from ISO...
    qemu-system-x86_64 -cdrom odx8.iso -m 512M -serial stdio
) else if exist build\odx8.bin (
    echo Running kernel directly...
    qemu-system-x86_64 -kernel build\odx8.bin -m 512M -serial stdio
) else (
    echo ERROR: No bootable image found!
    echo Please run build-odx8.bat first.
    exit /b 1
)
