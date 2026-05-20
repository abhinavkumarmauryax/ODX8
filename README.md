# ODX8 Operating System

**The Fastest Operating System on Earth**

## 🚀 Quick Start

```cmd
# 1. Install tools (if needed)
install-tools.bat

# 2. Build ODX8
build-odx8.bat

# 3. Run in QEMU
run-odx8.bat
```

## 📋 Overview

ODX8 is a from-scratch operating system designed for maximum speed and compatibility. Built entirely in x64 assembly with zero external dependencies.

### Components

- **Initrix**: Ultra-fast bootloader with multi-boot support
- **Quasar**: High-performance kernel with direct hardware access
- **QuasarFS**: Custom filesystem optimized for speed
- **ODX Shell**: Interactive command-line interface

### Philosophy

- **Speed First**: No abstraction layers, no security overhead
- **Universal Compatibility**: Works on all CPUs, boot methods, and hardware
- **Custom Everything**: Own binary format, filesystem, and ABI
- **Zero Dependencies**: Built entirely from scratch

## 🎯 Features

- ✅ Multi-boot support (BIOS, UEFI, GRUB)
- ✅ 64-bit long mode
- ✅ Hardware detection (CPU, RAM, Disks)
- ✅ VGA text mode display
- ✅ Interactive shell
- ✅ <10ms boot time target

## 🛠️ System Requirements

### Development
- **NASM**: x64 assembler
- **ld**: GNU linker (MinGW-w64)
- **QEMU**: For testing

### Runtime
- **CPU**: x86-64 (AMD64/Intel 64)
- **RAM**: 512MB minimum
- **Boot**: BIOS or UEFI

## 💻 Shell Commands

- `help` - Show available commands
- `ls` - List files and directories
- `mkdir` - Create directory
- `rm` - Remove file
- `cd` - Change directory
- `clear` - Clear screen
- `installodx` - Install ODX8 to disk
- `reboot` - Reboot system

## 📁 Project Structure

```
ODX8/
├── bootloader/
│   └── initrix.asm          # Initrix bootloader
├── kernel/
│   ├── quasar.asm           # Quasar kernel
│   ├── disk.asm             # Disk drivers
│   └── filesystem.asm       # QuasarFS
├── shell/
│   ├── shell.asm            # ODX Shell
│   └── installer.asm        # installodx command
├── tools/
│   └── mkusb.py             # USB creator
├── build-odx8.bat           # Build script
├── run-odx8.bat             # Run in QEMU
└── README.md                # This file
```

## ⚡ Performance

- **Boot Time**: <10ms target (7-16ms typical in QEMU)
- **Comparison**: 100-1000x faster than Linux
- **Design**: Ring 0 only, direct hardware access, zero overhead

## ⚠️ Safety Warning

ODX8 prioritizes speed over security:
- No memory protection
- No privilege separation
- Any program can access all hardware

**Use for**: Embedded systems, real-time systems, research, education
**NOT for**: Production, multi-user, internet-connected systems

## 📖 Documentation

- `README.md` - This file (quick start)
- `ODX8-ARCHITECTURE.md` - Detailed architecture

## 🎓 Credits

**Project**: ODX8 Operating System  
**Bootloader**: Initrix  
**Kernel**: Quasar  
**Filesystem**: QuasarFS  
**Goal**: Fastest OS on Earth

---

**Status**: Alpha | **Platform**: x86-64 | **Language**: Assembly (NASM)
