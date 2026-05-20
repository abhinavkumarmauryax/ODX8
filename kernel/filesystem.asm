; ============================================================================
; QuasarFS - Ultra-Fast Filesystem for ODX8
; Direct block access, no journaling, optimized for speed
; ============================================================================

BITS 64

section .text
    global quasarfs_init
    global quasarfs_read
    global quasarfs_write
    global quasarfs_create
    global quasarfs_delete
    global quasarfs_list

; ============================================================================
; QuasarFS Constants
; ============================================================================
QSFS_MAGIC          equ 0x53465351      ; "QSFS"
QSFS_VERSION        equ 1
QSFS_BLOCK_SIZE     equ 4096
QSFS_MAX_FILES      equ 1024
QSFS_MAX_NAME       equ 48

; File types
QSFS_TYPE_FILE      equ 0
QSFS_TYPE_DIR       equ 1

; ============================================================================
; QuasarFS Structures
; ============================================================================

; Superblock (512 bytes)
struc qsfs_superblock
    .magic:         resd 1              ; Magic number "QSFS"
    .version:       resd 1              ; Version
    .block_size:    resd 1              ; Block size (4096)
    .total_blocks:  resq 1              ; Total blocks
    .free_blocks:   resq 1              ; Free blocks
    .root_dir:      resq 1              ; Root directory block
    .bitmap_block:  resq 1              ; Block bitmap location
    .reserved:      resb 464            ; Reserved
endstruc

; Directory Entry (64 bytes)
struc qsfs_dirent
    .name:          resb 48             ; File name
    .type:          resb 1              ; File type
    .flags:         resb 1              ; Flags
    .size:          resq 1              ; File size
    .first_block:   resq 1              ; First data block
    .reserved:      resb 6              ; Reserved
endstruc

; ============================================================================
; Initialize QuasarFS
; ============================================================================
quasarfs_init:
    push rax
    push rbx
    push rcx
    push rsi
    
    ; Check if filesystem exists
    call qsfs_check_superblock
    test rax, rax
    jnz .exists
    
    ; Create new filesystem
    call qsfs_format
    
.exists:
    ; Load root directory
    call qsfs_load_root
    
    ; Initialize file table
    mov rcx, QSFS_MAX_FILES
    mov rdi, file_table
    xor rax, rax
.clear_table:
    stosq
    loop .clear_table
    
    pop rsi
    pop rcx
    pop rbx
    pop rax
    ret

; ============================================================================
; Check Superblock
; Returns: 1 if valid, 0 if not
; ============================================================================
qsfs_check_superblock:
    push rbx
    push rsi
    
    ; Read superblock from disk (block 0)
    mov rax, 0                          ; Block 0
    mov rbx, superblock_buffer
    call disk_read_block
    
    ; Check magic
    mov eax, [superblock_buffer + qsfs_superblock.magic]
    cmp eax, QSFS_MAGIC
    jne .invalid
    
    ; Check version
    mov eax, [superblock_buffer + qsfs_superblock.version]
    cmp eax, QSFS_VERSION
    jne .invalid
    
    mov rax, 1
    pop rsi
    pop rbx
    ret

.invalid:
    xor rax, rax
    pop rsi
    pop rbx
    ret

; ============================================================================
; Format Disk with QuasarFS
; ============================================================================
qsfs_format:
    push rax
    push rbx
    push rcx
    push rdi
    
    ; Clear superblock buffer
    mov rdi, superblock_buffer
    mov rcx, 512 / 8
    xor rax, rax
    rep stosq
    
    ; Fill superblock
    mov dword [superblock_buffer + qsfs_superblock.magic], QSFS_MAGIC
    mov dword [superblock_buffer + qsfs_superblock.version], QSFS_VERSION
    mov dword [superblock_buffer + qsfs_superblock.block_size], QSFS_BLOCK_SIZE
    mov qword [superblock_buffer + qsfs_superblock.total_blocks], 65536  ; 256MB
    mov qword [superblock_buffer + qsfs_superblock.free_blocks], 65534
    mov qword [superblock_buffer + qsfs_superblock.root_dir], 2
    mov qword [superblock_buffer + qsfs_superblock.bitmap_block], 1
    
    ; Write superblock to disk
    mov rax, 0
    mov rbx, superblock_buffer
    call disk_write_block
    
    ; Initialize block bitmap (all free except superblock and bitmap)
    mov rdi, bitmap_buffer
    mov rcx, QSFS_BLOCK_SIZE / 8
    mov rax, 0xFFFFFFFFFFFFFFFF      ; All free
    rep stosq
    
    ; Mark first 3 blocks as used (superblock, bitmap, root)
    mov byte [bitmap_buffer], 0x07   ; 0000 0111
    
    ; Write bitmap
    mov rax, 1
    mov rbx, bitmap_buffer
    call disk_write_block
    
    ; Initialize root directory
    mov rdi, root_dir_buffer
    mov rcx, QSFS_BLOCK_SIZE / 8
    xor rax, rax
    rep stosq
    
    ; Write root directory
    mov rax, 2
    mov rbx, root_dir_buffer
    call disk_write_block
    
    pop rdi
    pop rcx
    pop rbx
    pop rax
    ret

; ============================================================================
; Load Root Directory
; ============================================================================
qsfs_load_root:
    push rax
    push rbx
    
    mov rax, 2                          ; Root directory block
    mov rbx, root_dir_buffer
    call disk_read_block
    
    pop rbx
    pop rax
    ret

; ============================================================================
; List Files
; ============================================================================
quasarfs_list:
    push rax
    push rbx
    push rcx
    push rsi
    
    ; Load root directory
    call qsfs_load_root
    
    ; Iterate through directory entries
    mov rsi, root_dir_buffer
    mov rcx, QSFS_BLOCK_SIZE / 64       ; Max entries per block
    
.loop:
    ; Check if entry is used
    cmp byte [rsi + qsfs_dirent.name], 0
    je .next
    
    ; Print file name
    push rcx
    push rsi
    lea rsi, [rsi + qsfs_dirent.name]
    extern print_string
    call print_string
    
    ; Print file size
    mov al, ' '
    extern print_char
    call print_char
    
    pop rsi
    mov rax, [rsi + qsfs_dirent.size]
    extern print_decimal
    call print_decimal
    
    mov al, ' '
    call print_char
    
    ; Print type
    cmp byte [rsi + qsfs_dirent.type], QSFS_TYPE_DIR
    je .is_dir
    
    push rsi
    mov rsi, str_file
    call print_string
    pop rsi
    jmp .print_done
    
.is_dir:
    push rsi
    mov rsi, str_dir
    call print_string
    pop rsi
    
.print_done:
    extern newline
    call newline
    pop rcx
    
.next:
    add rsi, 64                         ; Next entry
    loop .loop
    
    pop rsi
    pop rcx
    pop rbx
    pop rax
    ret

; ============================================================================
; Create File
; Input: RSI = filename, RCX = size
; ============================================================================
quasarfs_create:
    push rax
    push rbx
    push rcx
    push rdi
    push rsi
    
    ; Find free directory entry
    call qsfs_find_free_entry
    test rax, rax
    jz .error
    
    mov rdi, rax                        ; Directory entry pointer
    
    ; Copy filename
    mov rcx, QSFS_MAX_NAME
    rep movsb
    
    ; Set file properties
    mov byte [rdi + qsfs_dirent.type], QSFS_TYPE_FILE
    mov byte [rdi + qsfs_dirent.flags], 0
    pop rsi
    push rsi
    mov [rdi + qsfs_dirent.size], rcx
    
    ; Allocate blocks
    call qsfs_allocate_blocks
    mov [rdi + qsfs_dirent.first_block], rax
    
    ; Write directory back
    mov rax, 2
    mov rbx, root_dir_buffer
    call disk_write_block
    
    mov rax, 1                          ; Success
    jmp .done

.error:
    xor rax, rax                        ; Failure
    
.done:
    pop rsi
    pop rdi
    pop rcx
    pop rbx
    pop rax
    ret

; ============================================================================
; Find Free Directory Entry
; Returns: RAX = pointer to free entry, or 0 if none
; ============================================================================
qsfs_find_free_entry:
    push rcx
    push rsi
    
    mov rsi, root_dir_buffer
    mov rcx, QSFS_BLOCK_SIZE / 64
    
.loop:
    cmp byte [rsi + qsfs_dirent.name], 0
    je .found
    add rsi, 64
    loop .loop
    
    xor rax, rax                        ; Not found
    jmp .done
    
.found:
    mov rax, rsi
    
.done:
    pop rsi
    pop rcx
    ret

; ============================================================================
; Allocate Blocks
; Input: RCX = number of blocks needed
; Returns: RAX = first block number
; ============================================================================
qsfs_allocate_blocks:
    push rbx
    push rcx
    
    ; TODO: Implement actual block allocation
    ; For now, return next available block
    mov rax, [next_free_block]
    add qword [next_free_block], rcx
    
    pop rcx
    pop rbx
    ret

; ============================================================================
; Disk I/O Stubs (to be implemented in disk.asm)
; ============================================================================
disk_read_block:
    ; Input: RAX = block number, RBX = buffer
    ; TODO: Implement actual disk read
    ret

disk_write_block:
    ; Input: RAX = block number, RBX = buffer
    ; TODO: Implement actual disk write
    ret

; ============================================================================
; Data Section
; ============================================================================
section .data
    align 16

str_file:           db '[FILE]', 0
str_dir:            db '[DIR]', 0

; ============================================================================
; BSS Section
; ============================================================================
section .bss
    align 4096

superblock_buffer:  resb 512
bitmap_buffer:      resb QSFS_BLOCK_SIZE
root_dir_buffer:    resb QSFS_BLOCK_SIZE
file_table:         resb QSFS_MAX_FILES * 8
next_free_block:    resq 1
