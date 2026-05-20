; ============================================================================
; ODX Shell - Interactive Command Shell
; Simple, fast command-line interface
; ============================================================================

BITS 64

section .text
    global shell_main
    extern print_string
    extern print_char
    extern newline

; ============================================================================
; Shell Main Loop
; ============================================================================
shell_main:
    ; Print welcome message
    mov rsi, shell_welcome
    call print_string
    call newline
    
.main_loop:
    ; Print prompt
    mov rsi, shell_prompt
    call print_string
    
    ; Read command
    call read_command
    
    ; Parse and execute command
    call execute_command
    
    ; Loop
    jmp .main_loop

; ============================================================================
; Read Command from Keyboard
; ============================================================================
read_command:
    push rax
    push rcx
    push rdi
    
    ; Clear command buffer
    mov rdi, command_buffer
    mov rcx, 256
    xor al, al
    rep stosb
    
    ; Read characters
    mov rdi, command_buffer
    xor rcx, rcx                    ; Character count
    
.read_loop:
    ; Wait for keyboard input
    call wait_key
    
    ; Check for special keys
    cmp al, 0x0D                    ; Enter
    je .done
    cmp al, 0x08                    ; Backspace
    je .backspace
    cmp al, 0x1B                    ; Escape
    je .clear
    
    ; Regular character
    cmp rcx, 255                    ; Max length
    jge .read_loop
    
    ; Store character
    mov [rdi], al
    inc rdi
    inc rcx
    
    ; Echo character
    call print_char
    
    jmp .read_loop

.backspace:
    test rcx, rcx
    jz .read_loop
    dec rdi
    dec rcx
    mov byte [rdi], 0
    ; TODO: Implement visual backspace
    jmp .read_loop

.clear:
    mov rdi, command_buffer
    xor rcx, rcx
    jmp .read_loop

.done:
    mov byte [rdi], 0               ; Null terminate
    call newline
    
    pop rdi
    pop rcx
    pop rax
    ret

; ============================================================================
; Wait for Keyboard Input (Simplified)
; ============================================================================
wait_key:
    push rbx
    
    ; Check keyboard status port
.wait:
    in al, 0x64
    test al, 1
    jz .wait
    
    ; Read from keyboard data port
    in al, 0x60
    
    ; Convert scancode to ASCII (simplified)
    ; TODO: Implement full keyboard driver
    cmp al, 0x80
    jge .wait                       ; Ignore key release
    
    ; Simple scancode to ASCII mapping
    movzx rbx, al
    cmp rbx, 128
    jge .wait
    mov al, [scancode_to_ascii + rbx]
    test al, al
    jz .wait
    
    pop rbx
    ret

; ============================================================================
; Execute Command
; ============================================================================
execute_command:
    push rsi
    
    ; Check if empty
    mov rsi, command_buffer
    cmp byte [rsi], 0
    je .done
    
    ; Compare with known commands
    mov rsi, command_buffer
    mov rdi, cmd_help
    call strcmp
    test rax, rax
    jz .cmd_help
    
    mov rsi, command_buffer
    mov rdi, cmd_ls
    call strcmp
    test rax, rax
    jz .cmd_ls
    
    mov rsi, command_buffer
    mov rdi, cmd_mkdir
    call strcmp
    test rax, rax
    jz .cmd_mkdir
    
    mov rsi, command_buffer
    mov rdi, cmd_rm
    call strcmp
    test rax, rax
    jz .cmd_rm
    
    mov rsi, command_buffer
    mov rdi, cmd_cd
    call strcmp
    test rax, rax
    jz .cmd_cd
    
    mov rsi, command_buffer
    mov rdi, cmd_clear
    call strcmp
    test rax, rax
    jz .cmd_clear
    
    mov rsi, command_buffer
    mov rdi, cmd_installodx
    call strcmp
    test rax, rax
    jz .cmd_installodx
    
    mov rsi, command_buffer
    mov rdi, cmd_reboot
    call strcmp
    test rax, rax
    jz .cmd_reboot
    
    ; Unknown command
    mov rsi, msg_unknown
    call print_string
    call newline
    jmp .done

.cmd_help:
    call do_help
    jmp .done

.cmd_ls:
    call do_ls
    jmp .done

.cmd_mkdir:
    call do_mkdir
    jmp .done

.cmd_rm:
    call do_rm
    jmp .done

.cmd_cd:
    call do_cd
    jmp .done

.cmd_clear:
    extern clear_screen
    call clear_screen
    jmp .done

.cmd_installodx:
    call do_installodx
    jmp .done

.cmd_reboot:
    call do_reboot
    jmp .done

.done:
    pop rsi
    ret

; ============================================================================
; String Compare
; Returns: 0 if equal, non-zero if different
; ============================================================================
strcmp:
    push rsi
    push rdi
.loop:
    mov al, [rsi]
    mov bl, [rdi]
    cmp al, bl
    jne .not_equal
    test al, al
    jz .equal
    inc rsi
    inc rdi
    jmp .loop
.equal:
    xor rax, rax
    pop rdi
    pop rsi
    ret
.not_equal:
    mov rax, 1
    pop rdi
    pop rsi
    ret

; ============================================================================
; Command Implementations
; ============================================================================

do_help:
    mov rsi, help_text
    call print_string
    call newline
    ret

do_ls:
    mov rsi, msg_ls
    call print_string
    call newline
    ; TODO: Implement actual file listing
    ret

do_mkdir:
    mov rsi, msg_mkdir
    call print_string
    call newline
    ; TODO: Implement directory creation
    ret

do_rm:
    mov rsi, msg_rm
    call print_string
    call newline
    ; TODO: Implement file removal
    ret

do_cd:
    mov rsi, msg_cd
    call print_string
    call newline
    ; TODO: Implement directory change
    ret

do_installodx:
    extern installer_main
    call installer_main
    ret

do_reboot:
    mov rsi, msg_rebooting
    call print_string
    call newline
    
    ; Triple fault reboot
    cli
    mov al, 0xFE
    out 0x64, al
    hlt
    ret

; ============================================================================
; Data Section
; ============================================================================
section .data
    align 16

shell_welcome:
    db 0x0A, 0x0D
    db 'ODX Shell v1.0 - Type "help" for commands', 0x0A, 0x0D, 0

shell_prompt:
    db '> ', 0

; Command strings
cmd_help:           db 'help', 0
cmd_ls:             db 'ls', 0
cmd_mkdir:          db 'mkdir', 0
cmd_rm:             db 'rm', 0
cmd_cd:             db 'cd', 0
cmd_clear:          db 'clear', 0
cmd_installodx:     db 'installodx', 0
cmd_reboot:         db 'reboot', 0

; Messages
msg_unknown:        db 'Unknown command. Type "help" for available commands.', 0
msg_ls:             db 'Listing files...', 0
msg_mkdir:          db 'Creating directory...', 0
msg_rm:             db 'Removing file...', 0
msg_cd:             db 'Changing directory...', 0
msg_installodx:     db 'ODX8 Installer', 0x0A, 0x0D, 0
msg_detecting_partitions: db 'Detecting disk partitions...', 0
msg_install_todo:   db 'Installation feature coming soon!', 0
msg_rebooting:      db 'Rebooting system...', 0

help_text:
    db 'Available commands:', 0x0A, 0x0D
    db '  help        - Show this help message', 0x0A, 0x0D
    db '  ls          - List files and directories', 0x0A, 0x0D
    db '  mkdir       - Create a directory', 0x0A, 0x0D
    db '  rm          - Remove a file', 0x0A, 0x0D
    db '  cd          - Change directory', 0x0A, 0x0D
    db '  clear       - Clear the screen', 0x0A, 0x0D
    db '  installodx  - Install ODX8 to disk', 0x0A, 0x0D
    db '  reboot      - Reboot the system', 0x0A, 0x0D, 0

; Simplified scancode to ASCII table
scancode_to_ascii:
    times 16 db 0
    db 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', 0, 0, 0x0D, 0
    db 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', 0, 0, 0, 0, 0
    db 'z', 'x', 'c', 'v', 'b', 'n', 'm', 0, 0, 0, 0, 0, 0, ' '
    times 50 db 0

; ============================================================================
; BSS Section
; ============================================================================
section .bss
    align 16

command_buffer:     resb 256
