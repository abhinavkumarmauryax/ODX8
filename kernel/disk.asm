; ============================================================================
; Disk Drivers - ODX8 Operating System
; Support for IDE, SATA, NVMe, USB
; ============================================================================

BITS 64

section .text
    global disk_init
    global disk_detect
    global disk_read
    global disk_write
    global disk_read_block
    global disk_write_block

; ============================================================================
; Disk Types
; ============================================================================
DISK_TYPE_NONE      equ 0
DISK_TYPE_IDE       equ 1
DISK_TYPE_SATA      equ 2
DISK_TYPE_NVME      equ 3
DISK_TYPE_USB       equ 4

; IDE/ATA Ports
ATA_PRIMARY_IO      equ 0x1F0
ATA_PRIMARY_CTRL    equ 0x3F6
ATA_SECONDARY_IO    equ 0x170
ATA_SECONDARY_CTRL  equ 0x376

; ATA Commands
ATA_CMD_READ        equ 0x20
ATA_CMD_WRITE       equ 0x30
ATA_CMD_IDENTIFY    equ 0xEC

; ATA Registers
ATA_REG_DATA        equ 0
ATA_REG_ERROR       equ 1
ATA_REG_FEATURES    equ 1
ATA_REG_SECCOUNT    equ 2
ATA_REG_LBA_LO      equ 3
ATA_REG_LBA_MID     equ 4
ATA_REG_LBA_HI      equ 5
ATA_REG_DRIVE       equ 6
ATA_REG_STATUS      equ 7
ATA_REG_COMMAND     equ 7

; ATA Status bits
ATA_SR_BSY          equ 0x80
ATA_SR_DRDY         equ 0x40
ATA_SR_DRQ          equ 0x08
ATA_SR_ERR          equ 0x01

; ============================================================================
; Initialize Disk System
; ============================================================================
disk_init:
    push rax
    push rsi
    
    ; Detect disks
    call disk_detect
    
    ; Initialize primary disk
    cmp byte [disk_count], 0
    je .no_disk
    
    ; Set current disk to first detected
    mov byte [current_disk], 0
    
    pop rsi
    pop rax
    ret

.no_disk:
    ; No disk found - use RAM disk
    mov byte [disk_type], DISK_TYPE_NONE
    pop rsi
    pop rax
    ret

; ============================================================================
; Detect Disks
; ============================================================================
disk_detect:
    push rax
    push rbx
    push rdx
    push rsi
    
    xor rbx, rbx                        ; Disk counter
    
    ; Try to detect IDE primary master
    mov dx, ATA_PRIMARY_IO
    call ata_identify
    test rax, rax
    jz .try_secondary
    
    mov byte [disk_type + rbx], DISK_TYPE_IDE
    mov word [disk_port + rbx*2], ATA_PRIMARY_IO
    inc rbx
    
.try_secondary:
    ; Try IDE secondary master
    mov dx, ATA_SECONDARY_IO
    call ata_identify
    test rax, rax
    jz .detect_done
    
    mov byte [disk_type + rbx], DISK_TYPE_IDE
    mov word [disk_port + rbx*2], ATA_SECONDARY_IO
    inc rbx
    
.detect_done:
    mov [disk_count], bl
    
    pop rsi
    pop rdx
    pop rbx
    pop rax
    ret

; ============================================================================
; ATA Identify
; Input: DX = base port
; Returns: 1 if disk found, 0 if not
; ============================================================================
ata_identify:
    push rbx
    push rcx
    push rdx
    
    ; Select drive
    mov al, 0xA0                        ; Master drive
    add dx, ATA_REG_DRIVE
    out dx, al
    sub dx, ATA_REG_DRIVE
    
    ; Wait for drive to be ready
    call ata_wait_ready
    test rax, rax
    jz .not_found
    
    ; Send IDENTIFY command
    mov al, ATA_CMD_IDENTIFY
    add dx, ATA_REG_COMMAND
    out dx, al
    sub dx, ATA_REG_COMMAND
    
    ; Wait for response
    call ata_wait_ready
    test rax, rax
    jz .not_found
    
    ; Read identification data
    add dx, ATA_REG_DATA
    mov rcx, 256
    mov rdi, disk_identify_buffer
.read_loop:
    in ax, dx
    stosw
    loop .read_loop
    
    mov rax, 1                          ; Found
    pop rdx
    pop rcx
    pop rbx
    ret

.not_found:
    xor rax, rax
    pop rdx
    pop rcx
    pop rbx
    ret

; ============================================================================
; ATA Wait Ready
; Input: DX = base port
; Returns: 1 if ready, 0 if timeout
; ============================================================================
ata_wait_ready:
    push rcx
    push rdx
    
    add dx, ATA_REG_STATUS
    mov rcx, 10000                      ; Timeout counter
    
.wait:
    in al, dx
    test al, ATA_SR_BSY
    jz .ready
    loop .wait
    
    ; Timeout
    xor rax, rax
    pop rdx
    pop rcx
    ret

.ready:
    mov rax, 1
    pop rdx
    pop rcx
    ret

; ============================================================================
; Read Block (4KB)
; Input: RAX = block number, RBX = buffer
; ============================================================================
disk_read_block:
    push rcx
    push rdx
    
    ; Convert block to sector (1 block = 8 sectors of 512 bytes)
    shl rax, 3
    
    ; Read 8 sectors
    mov rcx, 8
    mov rdx, rbx
    
.read_sector:
    push rax
    push rcx
    call ata_read_sector
    pop rcx
    pop rax
    
    add rdx, 512
    inc rax
    loop .read_sector
    
    pop rdx
    pop rcx
    ret

; ============================================================================
; Write Block (4KB)
; Input: RAX = block number, RBX = buffer
; ============================================================================
disk_write_block:
    push rcx
    push rdx
    
    ; Convert block to sector
    shl rax, 3
    
    ; Write 8 sectors
    mov rcx, 8
    mov rdx, rbx
    
.write_sector:
    push rax
    push rcx
    call ata_write_sector
    pop rcx
    pop rax
    
    add rdx, 512
    inc rax
    loop .write_sector
    
    pop rdx
    pop rcx
    ret

; ============================================================================
; ATA Read Sector (512 bytes)
; Input: RAX = LBA sector, RDX = buffer
; ============================================================================
ata_read_sector:
    push rbx
    push rcx
    push rdx
    push rdi
    
    ; Get disk port
    movzx rbx, byte [current_disk]
    movzx rdx, word [disk_port + rbx*2]
    
    ; Wait for drive ready
    call ata_wait_ready
    
    ; Set sector count
    mov al, 1
    add dx, ATA_REG_SECCOUNT
    out dx, al
    sub dx, ATA_REG_SECCOUNT
    
    ; Set LBA
    add dx, ATA_REG_LBA_LO
    mov al, byte [rsp + 24]             ; LBA low
    out dx, al
    
    inc dx
    mov al, byte [rsp + 25]             ; LBA mid
    out dx, al
    
    inc dx
    mov al, byte [rsp + 26]             ; LBA high
    out dx, al
    
    inc dx
    mov al, 0xE0                        ; LBA mode, master
    or al, byte [rsp + 27]
    out dx, al
    
    ; Send read command
    inc dx
    mov al, ATA_CMD_READ
    out dx, al
    
    ; Wait for data
    sub dx, ATA_REG_COMMAND
    call ata_wait_ready
    
    ; Read data
    add dx, ATA_REG_DATA
    mov rcx, 256
    pop rdi
    push rdi
.read:
    in ax, dx
    stosw
    loop .read
    
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    ret

; ============================================================================
; ATA Write Sector (512 bytes)
; Input: RAX = LBA sector, RDX = buffer
; ============================================================================
ata_write_sector:
    push rbx
    push rcx
    push rdx
    push rsi
    
    ; Get disk port
    movzx rbx, byte [current_disk]
    movzx rdx, word [disk_port + rbx*2]
    
    ; Wait for drive ready
    call ata_wait_ready
    
    ; Set sector count
    mov al, 1
    add dx, ATA_REG_SECCOUNT
    out dx, al
    sub dx, ATA_REG_SECCOUNT
    
    ; Set LBA
    add dx, ATA_REG_LBA_LO
    mov al, byte [rsp + 24]
    out dx, al
    
    inc dx
    mov al, byte [rsp + 25]
    out dx, al
    
    inc dx
    mov al, byte [rsp + 26]
    out dx, al
    
    inc dx
    mov al, 0xE0
    or al, byte [rsp + 27]
    out dx, al
    
    ; Send write command
    inc dx
    mov al, ATA_CMD_WRITE
    out dx, al
    
    ; Wait for ready
    sub dx, ATA_REG_COMMAND
    call ata_wait_ready
    
    ; Write data
    add dx, ATA_REG_DATA
    mov rcx, 256
    pop rsi
    push rsi
.write:
    lodsw
    out dx, ax
    loop .write
    
    ; Flush cache
    sub dx, ATA_REG_DATA
    call ata_wait_ready
    
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret

; ============================================================================
; Data Section
; ============================================================================
section .data
    align 16

msg_disk_init:      db '[DISK] Initializing...', 0

; ============================================================================
; BSS Section
; ============================================================================
section .bss
    align 16

disk_count:         resb 1
current_disk:       resb 1
disk_type:          resb 8              ; Up to 8 disks
disk_port:          resw 8              ; Port for each disk
disk_identify_buffer: resb 512
