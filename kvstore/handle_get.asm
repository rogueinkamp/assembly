section .data
    buffer times 256 db 0  ; Buffer for input/output
    get_str db "GET", 0
    set_str db "SET", 0
    exit_str db "EXIT", 0
    prompt_msg db "INPUT COMMAND > ", 0
    prompt_msg_len equ $ - prompt_msg - 1
    match_msg db "MATCH FOUND", 10, 0
    match_msg_len equ $ - match_msg - 1
    no_match_msg db "NO MATCH", 10, 0
    no_match_msg_len equ $ - no_match_msg - 1

    set_msg_log db "SET CMD FOUND", 10, 0
    set_msg_log_len equ $ - set_msg_log - 1

    get_msg_log db "GET CMD FOUND", 10, 0
    get_msg_log_len equ $ - get_msg_log - 1
    newline db 0x0a    ; ASCII code for newline (LF)
    key_buffer_length equ 5

    GENERIC_MESSAGE_PROMPT db "DEBUG: "
    GENERIC_MESSAGE_PROMPT_LEN equ $ - GENERIC_MESSAGE_PROMPT
    NEWLINE db 0x0A

section .bss
    key_buffer resb 6  ; For storing the key
    data_buffer resb 256  ; For storing the key

section .text
    global _start

_start:
    jmp main_loop

 main_loop:
    ; Clear buffer before reading new input
    mov rdi, buffer
    mov rcx, 255
    xor rax, rax
    rep stosb
    mov rdi, key_buffer
    mov rcx, 5
    xor rax, rax
    rep stosb

    ;; Print the prompt
    mov rax, 1
    mov rdi, 1
    mov rsi, prompt_msg
    mov rdx, prompt_msg_len
    syscall

    ; read from stdin
    mov rax, 0
    mov rdi, 0
    mov rsi, buffer ; set store to buffer - rsi is pointing to the buffer that has the data
    mov rdx, 4  ; Read only first 4 bytes for command
    syscall

;    ; Check if we read any data
    cmp rax, 0
    je main_loop  ; If no bytes read, try again

    ; Trim trailing spaces
    mov rcx, rax  ; Length of what was read
    lea rsi, [buffer + rcx - 1]  ; Point to last character
    .trim_trailing:
        cmp byte [rsi], ' '
        jne .trim_done
        dec rsi
        dec rcx
        cmp rcx, 0
        jg .trim_trailing
    .trim_done:

    mov byte [rsi + 1], 0  ; Null terminate after last non-space character

    ; Move trimmed command to key_buffer
    mov rdi, key_buffer
    mov rsi, buffer
    rep movsb

    mov rax, 1
    mov rdi, 1
    mov rsi, GENERIC_MESSAGE_PROMPT
    mov rdx, GENERIC_MESSAGE_PROMPT_LEN
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, key_buffer
    mov rdx, 4
    syscall

    ; add a newline so subsequent stdout calls are clean
    mov rax, 1
    mov rdi, 1
    mov rsi, NEWLINE
    mov rdx, 1
    syscall

    ; Read remaining data if any (simplified, just read whatever's left)
    mov rax, 0
    mov rdi, 0
    mov rsi, data_buffer
    mov rdx, 255  ; Read up to 255 bytes for any additional data
    syscall

    mov rsi, key_buffer
    mov rdi, get_str
    call strcmp
    test eax, eax
    jz handle_get

    mov rsi, key_buffer
    mov rdi, set_str
    call strcmp
    test eax, eax
    jz handle_set

    mov rsi, key_buffer
    mov rdi, exit_str
    call strcmp
    test eax, eax
    jz exit_program

    ; If no match found
    mov rax, 1
    mov rdi, 1
    mov rsi, no_match_msg
    mov rdx, no_match_msg_len
    syscall
    jmp main_loop

handle_get:
    mov rax, 1
    mov rdi, 1
    mov rsi, get_msg_log
    mov rdx, get_msg_log_len
    syscall
    jmp main_loop

handle_set:
    mov rax, 1
    mov rdi, 1

    mov rsi, set_msg_log
    mov rdx, set_msg_log_len
    syscall
    jmp main_loop

exit_program:
    ; Exit syscall
    mov rax, 60
    xor rdi, rdi  ; Exit status 0
    syscall

 strcmp:
    .loop:
        mov al, [rsi]
        mov bl, [rdi]
        test al, al  ; Check for end of string
        jz .done     ; If end, we're done comparing
        test bl, bl  ; Check if we've reached the end of the second string
        jz .notequal ; If end of second string but not first, not equal
        or al, 0x20  
        or bl, 0x20
        cmp al, bl
        jne .notequal
        inc rsi
        inc rdi
        jmp .loop

    .notequal:
        mov eax, 1
        ret

    .done:
        xor eax, eax
        ret


strcpy:
    .loop:
        mov al, [rsi]
        mov [rdi], al
        test al, al
        jz .done
        inc rsi
        inc rdi
        jmp .loop
    .done:
        ret
