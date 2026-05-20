# ODX8 Build Instructions

## Prerequisites

You need to install these tools before building ODX8:

### 1. NASM Assembler
- **Download**: https://www.nasm.us/pub/nasm/releasebuilds/2.16.03/win64/
- **File**: `nasm-2.16.03-installer-x64.exe`
- **Install**: Run installer, check "Add to PATH"
- **Verify**: Open new terminal, run `nasm -v`

### 2. MinGW-w64 (for ld linker)
- **Download**: https://winlibs.com/
- **File**: Get "GCC 13.x + MinGW-w64 11.x (UCRT)" - win64 version
- **Install**: Extract to `C:\mingw64`
- **Add to PATH**: Add `C:\mingw64\bin` to system PATH
- **Verify**: Open new terminal, run `ld --version`

### 3. QEMU (for testing)
- **Download**: https://qemu.weilnetz.de/w64/
- **File**: Latest `qemu-w64-setup-*.exe`
- **Install**: Run installer
- **Verify**: Open new terminal, run `qemu-system-x86_64 --version`

## Quick Install (if you have Chocolatey)

```cmd
choco install nasm mingw qemu python
```

## Building ODX8

Once tools are installed:

```cmd
# 1. Check tools
install-tools.bat

# 2. Build
build-odx8.bat

# 3. Run
run-odx8.bat
```

## What Gets Built

- `build/initrix.o` - Bootloader object file
- `build/quasar.o` - Kernel object file
- `build/shell.o` - Shell object file
- `build/filesystem.o` - Filesystem object file
- `build/disk.o` - Disk driver object file
- `build/installer.o` - Installer object file
- `build/odx8.bin` - Final linked binary
- `odx8.iso` - Bootable ISO image (if grub-mkrescue available)

## Running ODX8

### In QEMU (Recommended)
```cmd
run-odx8.bat
```

This will open a QEMU window with ODX8 running.

### Manual QEMU Command
```cmd
qemu-system-x86_64 -kernel build\odx8.bin -m 512M
```

Or with ISO:
```cmd
qemu-system-x86_64 -cdrom odx8.iso -m 512M
```

## Troubleshooting

### "NASM not found"
- Install NASM from link above
- Add to PATH
- Restart terminal
- Run `nasm -v` to verify

### "ld not found"
- Install MinGW-w64
- Add `C:\mingw64\bin` to PATH
- Restart terminal
- Run `ld --version` to verify

### "QEMU not found"
- Install QEMU
- Should auto-add to PATH
- Restart terminal
- Run `qemu-system-x86_64 --version` to verify

### Build fails with assembly errors
- Make sure you're using NASM (not MASM or GAS)
- Check NASM version is 2.14 or later
- Check that all .asm files are present

### QEMU shows black screen
- This might be normal during early boot
- Check for text output in QEMU window
- Try adding `-serial stdio` to see debug output

## Next Steps

After successful build:
1. Run ODX8 in QEMU
2. Try shell commands: `help`, `clear`, `reboot`
3. Explore the source code
4. Make modifications
5. Rebuild and test

## File Structure

```
ODX8/
├── bootloader/
│   └── initrix.asm          # Bootloader source
├── kernel/
│   ├── quasar.asm           # Kernel source
│   ├── disk.asm             # Disk driver
│   └── filesystem.asm       # Filesystem
├── shell/
│   ├── shell.asm            # Shell source
│   └── installer.asm        # Installer
├── build/                   # Build output (created)
│   ├── *.o                  # Object files
│   └── odx8.bin             # Final binary
├── isodir/                  # ISO staging (created)
├── build-odx8.bat           # Build script
├── run-odx8.bat             # Run script
├── linker-odx8.ld           # Linker script
└── README.md                # Documentation
```

## Development Workflow

1. Edit source files (*.asm)
2. Run `build-odx8.bat`
3. Run `run-odx8.bat`
4. Test in QEMU
5. Repeat

## Tips

- Keep QEMU window open to see output
- Use `Ctrl+C` in terminal to stop QEMU
- Build is fast (<5 seconds typically)
- Check build output for errors
- All source is in assembly - no C/C++
