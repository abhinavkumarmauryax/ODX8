# ODX8 Operating System - Architecture Document

## Project Overview

**Name**: ODX8
**Bootloader**: Initrix
**Kernel**: Quasar
**Philosophy**: Maximum speed, maximum compatibility, zero abstraction overhead

## Core Principles

1. **Speed First**: No security layers, no user/kernel separation, direct hardware access
2. **Custom Everything**: Own binary format, own filesystem, own ABI
3. **Universal Compatibility**: Works on all CPUs, all boot methods, all hardware
4. **Zero Dependencies**: Built entirely from scratch

## System Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    ODX8 Operating System                 │
├─────────────────────────────────────────────────────────┤
│  Shell (ODX Shell)                                       │
│  - Commands: ls, mkdir, rm, cd, help, installodx        │
│  - Direct hardware I/O                                   │
├─────────────────────────────────────────────────────────┤
│  Quasar Kernel                                           │
│  - No user/kernel separation (Ring 0 only)              │
│  - Direct memory access                                  │
│  - Zero-copy I/O                                         │
│  - Custom syscall interface                              │
├─────────────────────────────────────────────────────────┤
│  Filesystem: QuasarFS                                    │
│  - Flat structure (no directories initially)            │
│  - Direct block access                                   │
│  - No journaling (speed over safety)                     │
│  - Memory-mapped files                                   │
├─────────────────────────────────────────────────────────┤
│  Hardware Abstraction (Minimal)                          │
│  - CPU detection (x86, x64, ARM future)                 │
│  - Disk drivers (IDE, SATA, NVMe, USB)                  │
│  - Memory management (flat model)                        │
│  - Display (VGA, VESA, GOP)                             │
├─────────────────────────────────────────────────────────┤
│  Initrix Bootloader                                      │
│  - Multi-boot support (BIOS, UEFI, EFI, Legacy)        │
│  - RAM-only mode                                         │
│  - USB boot support                                      │
│  - Disk installer                                        │
└─────────────────────────────────────────────────────────┘
```

## Binary Format: ODX Executable (ODXE)

Custom binary format optimized for speed:

```
Header (64 bytes):
  Magic: "ODXE" (4 bytes)
  Version: 1 (4 bytes)
  Entry Point: (8 bytes)
  Code Size: (8 bytes)
  Data Size: (8 bytes)
  BSS Size: (8 bytes)
  Reserved: (24 bytes)

Code Section:
  Raw executable code

Data Section:
  Initialized data

BSS Section:
  Uninitialized data (zero-filled)
```

## Filesystem: QuasarFS

Ultra-fast filesystem design:

```
Superblock (512 bytes):
  Magic: "QSFS" (4 bytes)
  Version: 1 (4 bytes)
  Block Size: 4096 (4 bytes)
  Total Blocks: (8 bytes)
  Free Blocks: (8 bytes)
  Root Directory Block: (8 bytes)
  Bitmap Block: (8 bytes)
  Reserved: (464 bytes)

Block Bitmap:
  1 bit per block (0=free, 1=used)

Directory Entry (64 bytes):
  Name: (48 bytes)
  Type: (1 byte) - 0=file, 1=dir
  Flags: (1 byte)
  Size: (8 bytes)
  First Block: (8 bytes)
  Reserved: (6 bytes)

File Data:
  Direct block access, no indirection
  Contiguous allocation for speed
```

## Boot Modes

### 1. USB Live Boot (RAM-only)
- Load entire OS into RAM
- No disk writes
- Ultra-fast operation

### 2. Disk Installation
- `installodx` command
- Partition detection
- Direct block write

### 3. Multi-Boot Support
- BIOS (Legacy)
- UEFI
- EFI
- GRUB chainload
- systemd-boot
- Direct firmware boot

## Memory Model

**Flat Memory Model** (No protection):
- All code runs in Ring 0
- Direct physical memory access
- No virtual memory overhead (optional paging for large systems)
- Memory-mapped I/O

## Hardware Compatibility

### CPU Support
- x86 (32-bit)
- x86-64 (64-bit) - Primary target
- ARM (future)
- RISC-V (future)

### Disk Support
- IDE/PATA
- SATA/AHCI
- NVMe
- USB Mass Storage
- SD/MMC

### Display Support
- VGA Text Mode (80x25)
- VESA VBE
- UEFI GOP (Graphics Output Protocol)
- Framebuffer

## Performance Targets

- **Boot Time**: <10ms (already achieved)
- **Shell Response**: <1ms
- **File I/O**: Direct DMA, zero-copy
- **Context Switch**: N/A (no multitasking initially)
- **Syscall Overhead**: <10 cycles (inline assembly)

## Development Phases

### Phase 1: Core Boot (COMPLETE)
- ✅ Initrix bootloader
- ✅ Quasar kernel entry
- ✅ 64-bit mode
- ✅ Basic VGA output

### Phase 2: Hardware Detection (IN PROGRESS)
- CPU identification
- Memory detection
- Disk enumeration
- Display initialization

### Phase 3: Filesystem
- QuasarFS implementation
- Block device drivers
- File operations

### Phase 4: Shell
- Command parser
- Built-in commands
- File management

### Phase 5: USB Boot
- USB bootloader
- RAM disk
- Live environment

### Phase 6: Installer
- Partition detection
- Disk installation
- Bootloader installation

## File Structure

```
ODX8/
├── bootloader/
│   ├── initrix.asm          # Main bootloader
│   ├── initrix-usb.asm      # USB boot variant
│   ├── initrix-uefi.asm     # UEFI variant
│   └── initrix-bios.asm     # BIOS variant
├── kernel/
│   ├── quasar.asm           # Kernel entry
│   ├── cpu.asm              # CPU detection
│   ├── memory.asm           # Memory management
│   ├── disk.asm             # Disk drivers
│   ├── display.asm          # Display drivers
│   └── filesystem.asm       # QuasarFS
├── shell/
│   ├── shell.asm            # Shell main
│   ├── commands.asm         # Built-in commands
│   └── parser.asm           # Command parser
├── tools/
│   ├── mkusb.py             # Create bootable USB
│   ├── mkfs.quasar.py       # Create QuasarFS
│   └── odxe-builder.py      # Build ODXE binaries
└── docs/
    ├── ODX8-ARCHITECTURE.md # This file
    ├── QUASARFS-SPEC.md     # Filesystem spec
    └── ODXE-FORMAT.md       # Binary format spec
```

## Design Decisions

### Why No User/Kernel Separation?
- **Speed**: No mode switches, no privilege checks
- **Simplicity**: Single address space
- **Direct Access**: Programs can access hardware directly
- **Trade-off**: No security, but maximum performance

### Why Custom Binary Format?
- **Simplicity**: ELF is complex and slow to parse
- **Speed**: Direct load, no relocation
- **Size**: Minimal header overhead
- **Control**: Optimized for our use case

### Why Flat Filesystem?
- **Speed**: No directory traversal
- **Simplicity**: Direct block access
- **Predictable**: No fragmentation initially
- **Trade-off**: Limited scalability, but fast

### Why No Multitasking Initially?
- **Speed**: No context switches
- **Simplicity**: Single execution flow
- **Deterministic**: Predictable performance
- **Future**: Can add cooperative multitasking later

## Comparison with Linux

| Feature | Linux | ODX8 |
|---------|-------|------|
| Boot Time | 1-5 seconds | <10ms |
| User/Kernel | Separated | Unified (Ring 0) |
| Filesystem | ext4, btrfs, etc. | QuasarFS |
| Binary Format | ELF | ODXE |
| Syscall Overhead | ~100 cycles | <10 cycles |
| Security | High | None (speed focus) |
| Compatibility | High | High (goal) |
| Complexity | Very High | Minimal |

## Safety Warning

⚠️ **ODX8 is designed for speed, not security**

- No memory protection
- No privilege separation
- No input validation
- Any program can crash the system
- Any program can access all hardware

**Use cases**:
- Embedded systems
- Real-time systems
- Performance benchmarking
- Educational purposes
- Dedicated hardware

**NOT for**:
- Multi-user systems
- Internet-connected systems
- Systems with sensitive data
- Production environments (without understanding risks)

## Next Steps

1. Implement CPU detection
2. Implement memory detection
3. Implement disk drivers
4. Implement QuasarFS
5. Implement shell
6. Implement USB boot
7. Implement installer
8. Test on real hardware
9. Optimize everything
10. Benchmark against Linux
