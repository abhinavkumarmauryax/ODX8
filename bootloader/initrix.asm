; ============================================================================
; Initrix Bootloader - ODX8 Operating System
; Ultra-fast, multi-boot compatible bootloader
; Supports: BIOS, UEFI, USB, RAM-only mode
; ============================================================================

BITS 32

; Multiboot2 header for GRUB/UEFI compatibility
section .multiboot
    align 8
multiboot_header_start:
    dd 0xe85250d6                   ; Multiboot2 magic
    dd 0                            ; Architecture: i386
    dd multiboot_header_end - multiboot_header_start
    dd -(0xe85250d6 + 0 + (multiboot_header_end - multiboot_header_start))
    
    ; Framebuffer tag
    align 8
    dw 5                            ; Type: framebuffer
    dw 0                            ; Flags
    dd 20                           ; Size
    dd 1024                         ; Width
    dd 768                          ; Height
    dd 32                           ; Depth
    
    ; End tag
    align 8
    dw 0
    dw 0
    dd 8
multiboot_header_end:

section .text
    global _start
    extern quasar_main

_start:
    cli                             ; Disable interrupts
    
    ; Save multiboot info
    mov [multiboot_magic], eax
    mov [multiboot_info], ebx
    
    ; Setup temporary stack
    mov esp, stack_top
    
    ; Clear direction flag
    cld
    
    ; Display boot message
    mov esi, msg_initrix
    call print_string_32
    
    ; Detect CPU
    call detect_cpu
    
    ; Check for 64-bit support
    call check_long_mode
    test eax, eax
    jz .no_long_mode
    
    ; Setup paging for long mode
    call setup_page_tables
    
    ; Enable long mode
    call enable_long_mode
    
    ; Load GDT
    lgdt [gdt64.pointer]
    
    ; Jump to 64-bit code
    jmp gdt64.code:long_mode_start

.no_long_mode:
    mov esi, msg_no_64bit
    call print_string_32
    jmp halt_32

; ============================================================================
; CPU Detection
; ============================================================================
detect_cpu:
    pushad
    
    ; Check for CPUID support
    pushfd
    pop eax
    mov ecx, eax
    xor eax, 0x00200000             ; Flip ID bit
    push eax
    popfd
    pushfd
    pop eax
    push ecx
    popfd
    xor eax, ecx
    jz .no_cpuid
    
    ; Get CPU vendor
    xor eax, eax
    cpuid
    mov [cpu_vendor], ebx
    mov [cpu_vendor+4], edx
    mov [cpu_vendor+8], ecx
    
    mov esi, msg_cpu_detected
    call print_string_32
    
    popad
    ret

.no_cpuid:
    mov esi, msg_no_cpuid
    call print_string_32
    jmp halt_32

; ============================================================================
; Check for Long Mode (64-bit) support
; ============================================================================
check_long_mode:
    mov eax, 0x80000000
    cpuid
    cmp eax, 0x80000001
    jb .no_long_mode
    
    mov eax, 0x80000001
    cpuid
    test edx, 1 << 29               ; Check LM bit
    jz .no_long_mode
    
    mov eax, 1
    ret

.no_long_mode:
    xor eax, eax
    ret

; ============================================================================
; Setup Page Tables for Long Mode
; ============================================================================
setup_page_tables:
    ; Clear page tables
    mov edi, page_table_l4
    mov ecx, 4096 * 3 / 4
    xor eax, eax
    rep stosd
    
    ; Setup PML4
    mov eax, page_table_l3
    or eax, 0x03                    ; Present + Writable
    mov [page_table_l4], eax
    
    ; Setup PDPT
    mov eax, page_table_l2
    or eax, 0x03
    mov [page_table_l3], eax
    
    ; Setup PD (identity map first 1GB with 2MB pages)
    mov edi, page_table_l2
    mov eax, 0x00000083             ; Present + Writable + Huge
    mov ecx, 512                    ; 512 * 2MB = 1GB
.map_page:
    mov [edi], eax
    add eax, 0x200000               ; 2MB
    add edi, 8
    loop .map_page
    
    ret

; ============================================================================
; Enable Long Mode
; ============================================================================
enable_long_mode:
    ; Load PML4 address
    mov eax, page_table_l4
    mov cr3, eax
    
    ; Enable PAE
    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax
    
    ; Enable long mode in EFER MSR
    mov ecx, 0xC0000080
    rdmsr
    or eax, 1 << 8
    wrmsr
    
    ; Enable paging
    mov eax, cr0
    or eax, 1 << 31
    mov cr0, eax
    
    ret

; ============================================================================
; 32-bit Print String
; ============================================================================
print_string_32:
    push eax
    push ebx
    mov ebx, 0xB8000
    mov ah, 0x0F
.loop:
    lodsb
    test al, al
    jz .done
    mov [ebx], ax
    add ebx, 2
    jmp .loop
.done:
    pop ebx
    pop eax
    ret

; ============================================================================
; 32-bit Halt
; ============================================================================
halt_32:
    cli
    hlt
    jmp halt_32

; ============================================================================
; 64-bit Code
; ============================================================================
BITS 64
long_mode_start:
    ; Setup segments
    mov ax, gdt64.data
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    
    ; Setup 64-bit stack
    mov rsp, stack_top
    
    ; Clear screen
    call clear_screen
    
    ; Display ODX8 banner
    mov rsi, banner_odx8
    call print_string_64
    
    ; Jump to Quasar kernel
    call quasar_main
    
    ; Should never return
    cli
    hlt
    jmp $

; ============================================================================
; 64-bit Clear Screen
; ============================================================================
clear_screen:
    push rax
    push rcx
    push rdi
    
    mov rdi, 0xB8000
    mov rcx, 80 * 25
    mov ax, 0x0F20                  ; White space
    rep stosw
    
    pop rdi
    pop rcx
    pop rax
    ret

; ============================================================================
; 64-bit Print String
; ============================================================================
print_string_64:
    push rax
    push rdi
    
    mov rdi, 0xB8000
    mov ah, 0x0F
.loop:
    lodsb
    test al, al
    jz .done
    stosw
    jmp .loop
.done:
    pop rdi
    pop rax
    ret

; ============================================================================
; Data Section
; ============================================================================
section .data
    align 16

; Boot messages
msg_initrix:        db 'Initrix Bootloader v1.0', 0
msg_cpu_detected:   db ' [CPU OK]', 0
msg_no_cpuid:       db ' [ERROR: No CPUID]', 0
msg_no_64bit:       db ' [ERROR: 64-bit not supported]', 0

; ODX8 Banner
banner_odx8:
    db '  ___  ______  ____   ___  ', 0x0A, 0x0D
    db ' / _ \|  _ \ \/ /\ \ / / | ', 0x0A, 0x0D
    db '| | | | | | \  /  \ V /| | ', 0x0A, 0x0D
    db '| |_| | |_| /  \   | | |_| ', 0x0A, 0x0D
    db ' \___/|____/_/\_\  |_| (_) ', 0x0A, 0x0D
    db '                           ', 0x0A, 0x0D
    db 'Initrix Bootloader | Quasar Kernel', 0x0A, 0x0D
    db 'The Fastest OS on Earth', 0x0A, 0x0D
    db 0

; GDT for 64-bit mode
gdt64:
    dq 0                                    ; Null descriptor
.code: equ $ - gdt64
    dq 0x00AF9A000000FFFF                  ; 64-bit code segment
.data: equ $ - gdt64
    dq 0x00CF92000000FFFF                  ; 64-bit data segment
.pointer:
    dw $ - gdt64 - 1
    dq gdt64

; ============================================================================
; BSS Section
; ============================================================================
section .bss
    align 4096

; Page tables
page_table_l4:
    resb 4096
page_table_l3:
    resb 4096
page_table_l2:
    resb 4096

; Multiboot info
multiboot_magic:
    resd 1
multiboot_info:
    resd 1

; CPU info
cpu_vendor:
    resb 12

; Stack
    align 16
stack_bottom:
    resb 32768                      ; 32KB stack
stack_top:
