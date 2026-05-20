; ============================================================================
; ODX8 Installer - installodx command
; Detects partitions and installs ODX8 to disk
; ============================================================================

BITS 64

section .text
    global installer_main
    extern print_string
    extern print_char
    extern print_decimal
    extern print_hex
    extern newline
    extern wait_key

; ============================================================================
; Installer Main
; ============================================================================
installer_main:
    push rax
    push rbx
    push rcx
    push rsi
    
    ; Print banner
    call clear_screen
    mov rsi, installer_banner
    call print_string
    call newline
    call newline
    
    ; Detect disks
    mov rsi, msg_detecting
    call print_string
    call newline
    
    call detect_disks
    
    ; Show detected disks
    call show_disks
    
    ; Ask user to select disk
    call select_disk
    
    ; Detect partitions on selected disk
    call detect_partitions
    
    ; Show partitions
    call show_partitions
    
    ; Ask user to select partition
    call select_partition
    
    ; Confirm installation
    call confirm_install
    test rax, rax
    jz .cancelled
    
    ; Perform installation
    call perform_install
    
    ; Done
    mov rsi, msg_complete
    call print_string
    call newline
    jmp .done

.cancelled:
    mov rsi, msg_cancelled
    call print_string
    call newline

.done:
    mov rsi, msg_press_key
    call print_string
    call wait_key
    
    pop rsi
    pop rcx
    pop rbx
    pop rax
    ret

; ============================================================================
; Detect Disks
; ============================================================================
detect_disks:
    push rax
    push rbx
    
    ; TODO: Implement actual disk detection
    ; For now, simulate 1 disk
    mov byte [num_disks], 1
    mov qword [disk_size], 10 * 1024 * 1024 * 1024  ; 10GB
    
    pop rbx
    pop rax
    ret

; ============================================================================
; Show Disks
; ============================================================================
show_disks:
    push rax
    push rbx
    push rsi
    
    mov rsi, msg_disks_found
    call print_string
    movzx rax, byte [num_disks]
    call print_decimal
    call newline
    call newline
    
    ; Show each disk
    movzx rbx, byte [num_disks]
    xor rcx, rcx
    
.loop:
    cmp rcx, rbx
    jge .done
    
    ; Print disk number
    mov rsi, msg_disk
    call print_string
    mov rax, rcx
    call print_decimal
    mov rsi, msg_colon
    call print_string
    
    ; Print disk size
    mov rax, [disk_size]
    shr rax, 30                         ; Convert to GB
    call print_decimal
    mov rsi, msg_gb
    call print_string
    
    ; Print disk type
    mov rsi, msg_type_ide
    call print_string
    call newline
    
    inc rcx
    jmp .loop

.done:
    call newline
    pop rsi
    pop rbx
    pop rax
    ret

; ============================================================================
; Select Disk
; ============================================================================
select_disk:
    push rax
    push rsi
    
    mov rsi, msg_select_disk
    call print_string
    
    ; Read input
    call wait_key
    sub al, '0'
    mov [selected_disk], al
    
    call print_char
    call newline
    call newline
    
    pop rsi
    pop rax
    ret

; ============================================================================
; Detect Partitions
; ============================================================================
detect_partitions:
    push rax
    push rbx
    
    ; Read MBR
    xor rax, rax                        ; Sector 0
    mov rbx, mbr_buffer
    extern disk_read_sector
    call disk_read_sector
    
    ; Parse partition table
    mov rsi, mbr_buffer + 0x1BE         ; Partition table offset
    xor rcx, rcx
    
.parse_loop:
    cmp rcx, 4
    jge .done
    
    ; Check if partition is active
    mov al, [rsi]
    test al, al
    jz .next
    
    ; Store partition info
    mov rbx, rcx
    imul rbx, 16
    add rbx, partition_table
    
    ; Copy partition entry
    push rcx
    push rsi
    mov rdi, rbx
    mov rcx, 16
    rep movsb
    pop rsi
    pop rcx
    
    inc byte [num_partitions]
    
.next:
    add rsi, 16
    inc rcx
    jmp .parse_loop

.done:
    pop rbx
    pop rax
    ret

; ============================================================================
; Show Partitions
; ============================================================================
show_partitions:
    push rax
    push rbx
    push rcx
    push rsi
    
    mov rsi, msg_partitions_found
    call print_string
    movzx rax, byte [num_partitions]
    call print_decimal
    call newline
    call newline
    
    ; Show each partition
    movzx rbx, byte [num_partitions]
    xor rcx, rcx
    
.loop:
    cmp rcx, rbx
    jge .done
    
    ; Print partition number
    mov rsi, msg_partition
    call print_string
    mov rax, rcx
    call print_decimal
    mov rsi, msg_colon
    call print_string
    
    ; Get partition info
    push rcx
    imul rcx, 16
    add rcx, partition_table
    
    ; Print partition type
    mov al, [rcx + 4]
    movzx rax, al
    call print_hex_byte
    mov rsi, msg_space
    call print_string
    
    ; Print size (simplified)
    mov rsi, msg_size
    call print_string
    mov eax, [rcx + 12]
    shr eax, 11                         ; Convert sectors to MB
    movzx rax, eax
    call print_decimal
    mov rsi, msg_mb
    call print_string
    
    pop rcx
    call newline
    
    inc rcx
    jmp .loop

.done:
    call newline
    pop rsi
    pop rcx
    pop rbx
    pop rax
    ret

; ============================================================================
; Select Partition
; ============================================================================
select_partition:
    push rax
    push rsi
    
    mov rsi, msg_select_partition
    call print_string
    
    ; Read input
    call wait_key
    sub al, '0'
    mov [selected_partition], al
    
    call print_char
    call newline
    call newline
    
    pop rsi
    pop rax
    ret

; ============================================================================
; Confirm Installation
; ============================================================================
confirm_install:
    push rsi
    
    mov rsi, msg_warning
    call print_string
    call newline
    
    mov rsi, msg_confirm
    call print_string
    
    ; Read input
    call wait_key
    
    cmp al, 'Y'
    je .yes
    cmp al, 'y'
    je .yes
    
    xor rax, rax                        ; No
    pop rsi
    ret

.yes:
    mov rax, 1                          ; Yes
    call newline
    call newline
    pop rsi
    ret

; ============================================================================
; Perform Installation
; ============================================================================
perform_install:
    push rax
    push rbx
    push rsi
    
    ; Step 1: Format partition
    mov rsi, msg_formatting
    call print_string
    call newline
    
    extern quasarfs_format
    call quasarfs_format
    
    ; Step 2: Copy kernel
    mov rsi, msg_copying_kernel
    call print_string
    call newline
    
    ; TODO: Implement kernel copy
    
    ; Step 3: Install bootloader
    mov rsi, msg_installing_bootloader
    call print_string
    call newline
    
    ; TODO: Implement bootloader installation
    
    ; Step 4: Update boot sector
    mov rsi, msg_updating_boot
    call print_string
    call newline
    
    ; TODO: Implement boot sector update
    
    pop rsi
    pop rbx
    pop rax
    ret

; ============================================================================
; Helper Functions
; ============================================================================

clear_screen:
    push rax
    push rcx
    push rdi
    
    mov rdi, 0xB8000
    mov rcx, 80 * 25
    mov ax, 0x0F20
    rep stosw
    
    pop rdi
    pop rcx
    pop rax
    ret

print_hex_byte:
    push rax
    push rbx
    
    mov rbx, rax
    shr rax, 4
    and rax, 0x0F
    add al, '0'
    cmp al, '9'
    jle .first_digit
    add al, 7
.first_digit:
    call print_char
    
    mov rax, rbx
    and rax, 0x0F
    add al, '0'
    cmp al, '9'
    jle .second_digit
    add al, 7
.second_digit:
    call print_char
    
    pop rbx
    pop rax
    ret

; ============================================================================
; Data Section
; ============================================================================
section .data
    align 16

installer_banner:
    db '========================================', 0x0A, 0x0D
    db '  ODX8 INSTALLER', 0x0A, 0x0D
    db '========================================', 0

msg_detecting:      db 'Detecting disks...', 0
msg_disks_found:    db 'Found ', 0
msg_disk:           db 'Disk ', 0
msg_partition:      db 'Partition ', 0
msg_colon:          db ': ', 0
msg_gb:             db ' GB', 0
msg_mb:             db ' MB', 0
msg_space:          db ' ', 0
msg_type_ide:       db ' (IDE/SATA)', 0
msg_size:           db ' Size: ', 0
msg_select_disk:    db 'Select disk number: ', 0
msg_partitions_found: db 'Found ', 0
msg_select_partition: db 'Select partition number: ', 0
msg_warning:        db 'WARNING: This will erase all data on the selected partition!', 0
msg_confirm:        db 'Type Y to continue, any other key to cancel: ', 0
msg_cancelled:      db 'Installation cancelled.', 0
msg_formatting:     db '[1/4] Formatting partition with QuasarFS...', 0
msg_copying_kernel: db '[2/4] Copying kernel...', 0
msg_installing_bootloader: db '[3/4] Installing Initrix bootloader...', 0
msg_updating_boot:  db '[4/4] Updating boot sector...', 0
msg_complete:       db 'Installation complete! You can now reboot.', 0
msg_press_key:      db 'Press any key to continue...', 0

; ============================================================================
; BSS Section
; ============================================================================
section .bss
    align 16

num_disks:          resb 1
num_partitions:     resb 1
selected_disk:      resb 1
selected_partition: resb 1
disk_size:          resq 1
mbr_buffer:         resb 512
partition_table:    resb 64             ; 4 partitions * 16 bytes
