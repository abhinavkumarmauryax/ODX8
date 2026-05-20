; ============================================================================
; Quasar Kernel - ODX8 Operating System
; Ultra-fast kernel with direct hardware access
; No user/kernel separation - Everything runs in Ring 0
; ============================================================================

BITS 64

section .text
    global quasar_main
    global print_string
    global print_char
    global print_hex

; ============================================================================
; Kernel Entry Point
; ============================================================================
quasar_main:
    ; Initialize kernel
    call kernel_init
    
    ; Detect hardware
    call hardware_detect
    
    ; Initialize memory
    call memory_init
    
    ; Initialize filesystem
    call filesystem_init
    
    ; Start shell
    call shell_main
    
    ; Should never return
    cli
    hlt
    jmp $

; ============================================================================
; Kernel Initialization
; ============================================================================
kernel_init:
    push rax
    push rsi
    
    ; Clear screen
    call clear_screen
    
    ; Print banner
    mov rsi, kernel_banner
    call print_string
    
    ; Print init message
    mov rsi, msg_init
    call print_string
    
    pop rsi
    pop rax
    ret

; ============================================================================
; Hardware Detection
; ============================================================================
hardware_detect:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    
    mov rsi, msg_hw_detect
    call print_string
    
    ; Detect CPU
    call detect_cpu_info
    
    ; Detect memory
    call detect_memory
    
    ; Detect disks
    call detect_disks
    
    mov rsi, msg_ok
    call print_string
    call newline
    
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

; ============================================================================
; CPU Information Detection
; ============================================================================
detect_cpu_info:
    push rax
    push rbx
    push rcx
    push rdx
    
    ; Get CPU brand string
    mov eax, 0x80000002
    cpuid
    mov [cpu_brand], eax
    mov [cpu_brand+4], ebx
    mov [cpu_brand+8], ecx
    mov [cpu_brand+12], edx
    
    mov eax, 0x80000003
    cpuid
    mov [cpu_brand+16], eax
    mov [cpu_brand+20], ebx
    mov [cpu_brand+24], ecx
    mov [cpu_brand+28], edx
    
    mov eax, 0x80000004
    cpuid
    mov [cpu_brand+32], eax
    mov [cpu_brand+36], ebx
    mov [cpu_brand+40], ecx
    mov [cpu_brand+44], edx
    
    ; Print CPU info
    mov rsi, msg_cpu
    call print_string
    mov rsi, cpu_brand
    call print_string
    call newline
    
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

; ============================================================================
; Memory Detection
; ============================================================================
detect_memory:
    push rax
    push rsi
    
    ; Get memory size (simplified - assumes 512MB for now)
    mov qword [total_memory], 512 * 1024 * 1024
    
    mov rsi, msg_memory
    call print_string
    mov rax, [total_memory]
    shr rax, 20                     ; Convert to MB
    call print_decimal
    mov rsi, msg_mb
    call print_string
    call newline
    
    pop rsi
    pop rax
    ret

; ============================================================================
; Disk Detection
; ============================================================================
detect_disks:
    push rax
    push rsi
    
    mov rsi, msg_disk
    call print_string
    
    ; TODO: Implement actual disk detection
    ; For now, assume 1 disk
    mov byte [disk_count], 1
    
    movzx rax, byte [disk_count]
    call print_decimal
    mov rsi, msg_found
    call print_string
    call newline
    
    pop rsi
    pop rax
    ret

; ============================================================================
; Memory Initialization
; ============================================================================
memory_init:
    push rax
    push rsi
    
    mov rsi, msg_mem_init
    call print_string
    
    ; Setup heap at 16MB mark
    mov qword [heap_start], 0x1000000
    mov qword [heap_current], 0x1000000
    mov qword [heap_end], 0x10000000    ; 256MB heap
    
    mov rsi, msg_ok
    call print_string
    call newline
    
    pop rsi
    pop rax
    ret

; ============================================================================
; Filesystem Initialization
; ============================================================================
filesystem_init:
    push rax
    push rsi
    
    mov rsi, msg_fs_init
    call print_string
    
    ; Initialize QuasarFS
    ; TODO: Implement actual filesystem
    
    mov rsi, msg_ok
    call print_string
    call newline
    
    pop rsi
    pop rax
    ret

; ============================================================================
; Display Functions
; ============================================================================

clear_screen:
    push rax
    push rcx
    push rdi
    
    mov rdi, 0xB8000
    mov rcx, 80 * 25
    mov ax, 0x0F20
    rep stosw
    
    ; Reset cursor
    mov word [cursor_pos], 0
    
    pop rdi
    pop rcx
    pop rax
    ret

print_string:
    push rax
    push rdi
    push rsi
    
    movzx rdi, word [cursor_pos]
    shl rdi, 1
    add rdi, 0xB8000
    mov ah, 0x0F
.loop:
    lodsb
    test al, al
    jz .done
    cmp al, 0x0A                    ; Newline
    je .newline
    cmp al, 0x0D                    ; Carriage return
    je .continue
    stosw
    inc word [cursor_pos]
    jmp .loop
.newline:
    ; Move to next line
    movzx rax, word [cursor_pos]
    mov rdx, 0
    mov rcx, 80
    div rcx
    inc rax
    mul rcx
    mov [cursor_pos], ax
    movzx rdi, word [cursor_pos]
    shl rdi, 1
    add rdi, 0xB8000
    jmp .loop
.continue:
    jmp .loop
.done:
    pop rsi
    pop rdi
    pop rax
    ret

print_char:
    push rax
    push rdi
    
    movzx rdi, word [cursor_pos]
    shl rdi, 1
    add rdi, 0xB8000
    mov ah, 0x0F
    stosw
    inc word [cursor_pos]
    
    pop rdi
    pop rax
    ret

newline:
    push rax
    push rcx
    push rdx
    
    movzx rax, word [cursor_pos]
    mov rdx, 0
    mov rcx, 80
    div rcx
    inc rax
    mul rcx
    mov [cursor_pos], ax
    
    pop rdx
    pop rcx
    pop rax
    ret

print_hex:
    push rax
    push rbx
    push rcx
    push rdx
    
    mov rcx, 16
    mov rbx, hex_chars
.loop:
    rol rax, 4
    push rax
    and rax, 0x0F
    mov al, [rbx + rax]
    call print_char
    pop rax
    dec rcx
    jnz .loop
    
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

print_decimal:
    push rax
    push rbx
    push rcx
    push rdx
    
    mov rbx, 10
    xor rcx, rcx
.divide:
    xor rdx, rdx
    div rbx
    push rdx
    inc rcx
    test rax, rax
    jnz .divide
.print:
    pop rax
    add al, '0'
    call print_char
    dec rcx
    jnz .print
    
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

; ============================================================================
; Data Section
; ============================================================================
section .data
    align 16

kernel_banner:
    db 0x0A, 0x0D
    db '========================================', 0x0A, 0x0D
    db '  QUASAR KERNEL v1.0', 0x0A, 0x0D
    db '  ODX8 Operating System', 0x0A, 0x0D
    db '========================================', 0x0A, 0x0D
    db 0x0A, 0x0D, 0

msg_init:           db '[INIT] Initializing kernel...', 0x0A, 0x0D, 0
msg_hw_detect:      db '[HW] Detecting hardware...', 0
msg_cpu:            db '  CPU: ', 0
msg_memory:         db '  RAM: ', 0
msg_mb:             db ' MB', 0
msg_disk:           db '  Disks: ', 0
msg_found:          db ' found', 0
msg_mem_init:       db '[MEM] Initializing memory...', 0
msg_fs_init:        db '[FS] Initializing QuasarFS...', 0
msg_ok:             db ' [OK]', 0

hex_chars:          db '0123456789ABCDEF'

; ============================================================================
; BSS Section
; ============================================================================
section .bss
    align 16

; Display
cursor_pos:         resw 1

; CPU info
cpu_brand:          resb 48

; Memory info
total_memory:       resq 1
heap_start:         resq 1
heap_current:       resq 1
heap_end:           resq 1

; Disk info
disk_count:         resb 1
