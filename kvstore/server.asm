section .data
    filename db "kv_store.txt", 0
    mode db "a+", 0   ; Append mode for writing, read for reading
    buffer times 256 db 0  ; Buffer for input/output
    get_str db "GET", 0
    set_str db "SET", 0
    cmd_str_len equ 3
    exit_str db "EXIT", 0
    exit_str_len equ 4
    space   db " ", 0
    newline db 10, 0    ; ASCII newline
    get_msg db "GOT GET MSG ", 0
    get_msg_len equ $ - get_msg - 1
    set_msg db "GOT SET MSG ", 0
    set_msg_len equ $ - set_msg - 1
    start_msg db "INPUT COMMAND >", 0
    start_msg_len equ $ - start_msg - 1
    ;fo_msg db "FO ERR", 0
    ;fo_msg_len equ $ - fo_msg - 1
    not_found_msg db "NOT FOUND -> ", 0
    not_found_msg_len equ $ - not_found_msg - 1


section .bss
    fd resd 1           ; File descriptor
    key resb 128        ; Key buffer
    value resb 128      ; Value buffer
    debug_buffer resb 1  ; Reserve 1 byte for debug output

section .text
    global _start
 strcmp:
    .loop:
        mov al, [rsi]
        mov bl, [rdi]
        or al, 0x20
        or bl, 0x20
        cmp al, bl
        jne .debug_notequal
        jmp .continue_check

    .debug_notequal:
        ; Debug: Print the characters that differ
        mov byte [debug_buffer], al
        mov rax, 1
        mov rdi, 1
        mov rsi, debug_buffer
        mov rdx, 1
        syscall

        mov eax, 1
        ret

    .continue_check:
        test al, al
        jz .done

        inc rsi
        inc rdi
        jmp .loop


    .done:
        xor eax, eax
        ret

_start:
    ; Open or create file

    ;===================================================================================================

    ;mov rax, 2          ; sys_open system call number
    ;mov rdi, filename   ; Address of the filename string
    ;mov rsi, 0x42       ; Flags like O_CREAT | O_RDWR
    ;mov rdx, 0644       ; File permissions (if creating)
    ;syscall
    ; System Call Return: After a syscall for sys_open, rax will contain either:
    ; A non-negative integer representing the file descriptor if the file was successfully opened.
    ; -1 if there was an error (this is due to how Linux system calls return errors,
    ; where -1 signals an error and errno is set to indicate the specific error).
    ;cmp rax, -1
    ;jl .fo_error
    ;mov [fd], rax

    ;===================================================================================================
    ; test rax, rax
    ; js .fo_error           ; Jump if sign flag set (open failed)


    jmp main_loop

;.fo_error:
;    ; For now, just log the set message
;    mov rax, 1              ; system call number for write
;    mov rdi, 1              ; file descriptor (stdout)
;    mov rsi, fo_msg        ; message buffer
;    mov rdx, fo_msg_len    ; message length
;
;    ; Make system call
;    syscall
;    ; Clear rsi and rdx if you want
;    xor rsi, rsi
;    xor rdx, rdx
;    call exit

main_loop:
    call clear_buffer  ; Clear the buffer before reading new input
    mov rax, 1              ; system call number for write
    mov rdi, 1              ; file descriptor (stdout)
    mov rsi, start_msg        ; message buffer
    mov rdx, start_msg_len    ; message length
    ; Make system call
    syscall

    ; Read command from stdin
    mov rax, 0          ; sys_read for 64-bit
    mov rdi, 0          ; stdin
    mov rsi, buffer
    mov rdx, 255
    syscall
    mov rcx, rax  ; Store the length of what was read
    mov rax, 1
    mov rdi, 1
    mov rsi, buffer
    mov rdx, rcx  ; rcx should hold the length of what was read
    syscall
    ; Check if command is 'GET'
    mov rsi, buffer
    mov rdi, get_str
    call strcmp
    test eax, eax       ; If strcmp returns 0, it's a match
    jz handle_get

    ; Check if command is 'SET'
    mov rsi, buffer
    mov rdi, set_str
    call strcmp
    test eax, eax
    jz handle_set

    ; Check if command is 'EXIT'
    mov rsi, buffer
    mov rdi, exit_str
    call strcmp ; strcmp returns value to eax (ZF)
    test eax, eax ; bitwise AND
    jz close_and_exit

    jmp cmd_not_found


close_file:
    mov rax, 3          ; sys_close
    mov rdi, [fd]       ; File descriptor to close
    syscall
    ; Optionally, reset fd to 0 or -1 to indicate it's closed
    mov qword [fd], -1  ; or 0 if you prefer

exit:
    mov rax, 60             ; sys_exit for 64-bit
    xor rdi, rdi            ; Exit status 0
    syscall

close_and_exit:
    call close_file
    call exit

handle_set:
    ; For now, just log the set message
    mov rax, 1              ; system call number for write
    mov rdi, 1              ; file descriptor (stdout)
    mov rsi, set_msg        ; message buffer
    mov rdx, set_msg_len    ; message length

    ; Make system call
    syscall
    jmp main_loop

handle_get:
    ; For now, just log the get message
    mov rax, 1              ; system call number for write
    mov rdi, 1              ; file descriptor (stdout)
    mov rsi, get_msg        ; message buffer
    mov rdx, get_msg_len    ; message length

    ; Make system call
    syscall
    jmp main_loop


cmd_not_found:
    ; First, print the custom message
    mov rax, 1              ; system call number for write
    mov rdi, 1              ; file descriptor (stdout)
    mov rsi, not_found_msg  ; address of the custom message
    mov rdx, not_found_msg_len  ; length of the custom message
    syscall
    ; Clear rsi and rdx if you want
    xor rsi, rsi
    xor rdx, rdx
    mov rax, 1              ; system call number for write
    mov rdi, 1              ; file descriptor (stdout)
    mov rsi, buffer        ; message buffer
    mov rdx, rcx            ; message length

    ; Make system call
    syscall
    ; Clear rsi and rdx if you want
    xor rsi, rsi
    xor rdx, rdx
    jmp main_loop


 clear_buffer:
    mov rdi, buffer      ; First argument: address of buffer
    mov rcx, 256         ; Number of bytes to clear (256 for 256-byte buffer)
    xor rax, rax         ; Value to write (0)
    cld                  ; Clear direction flag for forward movement
    rep stosb            ; Store AL into ES:[EDI] CX times
    ret
