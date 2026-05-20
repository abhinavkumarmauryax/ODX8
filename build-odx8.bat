@echo off
REM ODX8 Operating System Build Script

echo ========================================
echo   Building ODX8 Operating System
echo ========================================
echo.

REM Check for NASM
where nasm >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: NASM not found!
    exit /b 1
)

REM Check for ld
where ld >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: ld linker not found!
    exit /b 1
)

echo [1/8] Assembling Initrix bootloader...
nasm -f elf64 bootloader\initrix.asm -o build\initrix.o
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to assemble bootloader!
    exit /b 1
)

echo [2/8] Assembling Quasar kernel...
nasm -f elf64 kernel\quasar.asm -o build\quasar.o
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to assemble kernel!
    exit /b 1
)

echo [3/8] Assembling ODX Shell...
nasm -f elf64 shell\shell.asm -o build\shell.o
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to assemble shell!
    exit /b 1
)

echo [4/8] Assembling Filesystem...
nasm -f elf64 kernel\filesystem.asm -o build\filesystem.o
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to assemble filesystem!
    exit /b 1
)

echo [5/8] Assembling Disk Driver...
nasm -f elf64 kernel\disk.asm -o build\disk.o
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to assemble disk driver!
    exit /b 1
)

echo [6/8] Assembling Installer...
nasm -f elf64 shell\installer.asm -o build\installer.o
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to assemble installer!
    exit /b 1
)

echo [7/8] Linking ODX8...
ld -n -T linker-odx8.ld build\initrix.o build\quasar.o build\shell.o build\filesystem.o build\disk.o build\installer.o -o build\odx8.bin
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to link!
    exit /b 1
)

echo [8/8] Creating ISO image...
if not exist isodir\boot\grub mkdir isodir\boot\grub
copy build\odx8.bin isodir\boot\ >nul

REM Create GRUB config
(
echo set timeout=0
echo set default=0
echo menuentry "ODX8 Operating System" {
echo     multiboot2 /boot/odx8.bin
echo     boot
echo }
) > isodir\boot\grub\grub.cfg

REM Try to create ISO
where grub-mkrescue >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    grub-mkrescue -o odx8.iso isodir 2>nul
    if %ERRORLEVEL% EQU 0 (
        echo ISO created: odx8.iso
        goto :success
    )
)

where xorriso >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    xorriso -as mkisofs -R -J -c boot/grub/boot.cat -b boot/grub/i386-pc/eltorito.img -no-emul-boot -boot-load-size 4 -boot-info-table -o odx8.iso isodir 2>nul
    if %ERRORLEVEL% EQU 0 (
        echo ISO created: odx8.iso
        goto :success
    )
)

echo Warning: Could not create ISO (grub-mkrescue/xorriso not found)
echo       You can still run with: qemu-system-x86_64 -kernel build\odx8.bin

:success
echo.
echo ========================================
echo   Build Complete!
echo ========================================
echo.
echo To run: run-odx8.bat
echo To create USB: tools\mkusb.py
echo.
