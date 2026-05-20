# Getting Started with ODX8

## 🚀 Quick Overview

ODX8 is a complete operating system built from scratch in x64 assembly. You're looking at:
- **Initrix** bootloader
- **Quasar** kernel  
- **QuasarFS** filesystem
- **ODX Shell** with interactive commands
- **installodx** disk installer

## 📋 What You Need

To build and run ODX8, you need these tools installed:

1. **NASM** - Assembler
2. **MinGW-w64** - Linker (ld)
3. **QEMU** - Virtual machine for testing

## 🔧 Installation Steps

### Step 1: Check What's Installed

```cmd
install-tools.bat
```

This will show you what's missing.

### Step 2: Install Tools

#### Option A: Automatic (Recommended)
```powershell
PowerShell -ExecutionPolicy Bypass -File auto-install.ps1
```

#### Option B: Manual

**NASM:**
1. Download from: https://www.nasm.us/pub/nasm/releasebuilds/2.16.03/win64/
2. Run `nasm-2.16.03-installer-x64.exe`
3. Check "Add to PATH"

**MinGW-w64:**
1. Download from: https://winlibs.com/
2. Get "GCC 13.x + MinGW-w64 (UCRT)" win64 version
3. Extract to `C:\mingw64`
4. Add `C:\mingw64\bin` to PATH

**QEMU:**
1. Download from: https://qemu.weilnetz.de/w64/
2. Run installer
3. Should auto-add to PATH

### Step 3: Restart Terminal

After installing tools, **restart your terminal** for PATH changes to take effect.

### Step 4: Verify Installation

```cmd
nasm -v
ld --version
qemu-system-x86_64 --version
```

All three should work without errors.

## 🏗️ Building ODX8

```cmd
build-odx8.bat
```

This will:
1. Assemble bootloader (initrix.asm)
2. Assemble kernel (quasar.asm)
3. Assemble shell (shell.asm)
4. Assemble filesystem (filesystem.asm)
5. Assemble disk driver (disk.asm)
6. Assemble installer (installer.asm)
7. Link everything into odx8.bin
8. Create bootable ISO (if grub-mkrescue available)

**Build time**: ~5 seconds

## 🎮 Running ODX8

```cmd
run-odx8.bat
```

This opens QEMU with ODX8 running.

### What You'll See

1. **Boot Screen**: Initrix bootloader banner
2. **Kernel Init**: Hardware detection messages
3. **Shell Prompt**: `>` waiting for commands

### Available Commands

Type these at the `>` prompt:

- `help` - Show all commands
- `clear` - Clear the screen
- `ls` - List files (in development)
- `mkdir` - Create directory (in development)
- `rm` - Remove file (in development)
- `cd` - Change directory (in development)
- `installodx` - Install ODX8 to disk (in development)
- `reboot` - Reboot the system

## 🐛 Troubleshooting

### "NASM not found"
- Install NASM
- Add to PATH
- Restart terminal
- Try again

### "ld not found"
- Install MinGW-w64
- Add `C:\mingw64\bin` to PATH
- Restart terminal
- Try again

### "QEMU not found"
- Install QEMU
- Restart terminal
- Try again

### Build Errors
- Make sure all tools are installed
- Check that you're in the ODX8 directory
- Verify all .asm files are present
- Check build output for specific errors

### QEMU Black Screen
- Wait a few seconds for boot
- Check for text output
- Try pressing Enter
- Check terminal for error messages

## 📁 Project Structure

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
├── tools/
│   └── mkusb.py             # USB creator
├── build/                   # Build output
├── README.md                # Quick start
├── BUILD-INSTRUCTIONS.md    # Detailed build guide
├── PROJECT-STATUS.md        # What's done/todo
├── ODX8-ARCHITECTURE.md     # Architecture docs
└── GETTING-STARTED.md       # This file
```

## 🎯 What to Do Next

### 1. Explore the Code
- Open `bootloader/initrix.asm` - See how booting works
- Open `kernel/quasar.asm` - See kernel initialization
- Open `shell/shell.asm` - See command handling

### 2. Try Commands
- Type `help` to see available commands
- Type `clear` to clear the screen
- Type `reboot` to reboot (QEMU will restart)

### 3. Make Changes
- Edit any .asm file
- Run `build-odx8.bat`
- Run `run-odx8.bat`
- See your changes!

### 4. Read Documentation
- `README.md` - Overview
- `ODX8-ARCHITECTURE.md` - How it all works
- `PROJECT-STATUS.md` - What's implemented
- `BUILD-INSTRUCTIONS.md` - Build details

## 💡 Tips

- **Fast Iteration**: Build is very fast (~5 seconds)
- **No Reboot Needed**: Just rebuild and re-run
- **Check Output**: Build script shows what's happening
- **QEMU Window**: Keep it open to see OS output
- **Ctrl+C**: Stop QEMU from terminal
- **Pure Assembly**: All code is in .asm files

## 🎓 Learning Path

### Beginner
1. Build and run ODX8
2. Try shell commands
3. Read README.md
4. Look at shell.asm (easiest to understand)

### Intermediate
5. Read ODX8-ARCHITECTURE.md
6. Study initrix.asm (bootloader)
7. Study quasar.asm (kernel)
8. Make small changes and rebuild

### Advanced
9. Implement missing features
10. Add new commands
11. Improve drivers
12. Optimize performance

## 📚 Resources

### In This Project
- All .asm files have comments
- Documentation in .md files
- Architecture diagrams in ODX8-ARCHITECTURE.md

### External
- **NASM Manual**: https://www.nasm.us/docs.php
- **OSDev Wiki**: https://wiki.osdev.org/
- **x86-64 Reference**: https://www.amd.com/en/support/tech-docs
- **Multiboot Spec**: https://www.gnu.org/software/grub/manual/multiboot/

## ⚠️ Important Notes

### This is Alpha Software
- Not all features are implemented
- Some commands are stubs
- Needs testing on real hardware
- May have bugs

### Speed Over Security
- No memory protection
- No privilege separation
- Everything runs in Ring 0
- Not for production use

### Educational Purpose
- Learn OS development
- Understand boot process
- Study assembly programming
- Experiment with low-level code

## 🎉 You're Ready!

You now have everything you need to:
1. ✅ Build ODX8
2. ✅ Run ODX8
3. ✅ Explore the code
4. ✅ Make changes
5. ✅ Learn OS development

**Next command to run:**
```cmd
build-odx8.bat
```

Then:
```cmd
run-odx8.bat
```

**Welcome to ODX8 - The Fastest OS on Earth!** 🚀
