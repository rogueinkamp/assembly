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

section .bss
    key_buffer resb 256  ; For storing the key

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

    ; Assuming buffer is where the data was read into
    mov byte [buffer + rax], 0 ; Null terminate, where rax holds the number of bytes actually read
    lea rdi, [buffer + rax - 1]  ; rdi now points to the last character read
    .trim_trailing:
        cmp byte [rdi], ' '
        jne .trim_done
        mov byte [rdi], 0
        cmp rdi, buffer
        je .trim_done

        dec rdi
        jmp .trim_trailing

    .trim_done:
        ; Now move the result to key_buffer in one step
        mov rsi, buffer
        mov rdi, key_buffer
        call strcpy ; You need to implement or use an existing strcpy function

    ; Debug print before copy
    mov rax, 1
    mov rdi, 1

    mov rsi, buffer
    mov rdx, 256  ; Or however long buffer might be
    syscall

    ; Define the copy loop as a local procedure
    .copy_loop:
        mov al, [rsi]
        test al, al              ; Check if we've reached null terminator
        jz .copy_done            ; If null, we're done copying
        mov [rdi], al            ; Store character to destination
        inc rsi
        inc rdi
        jmp .copy_loop

    .copy_done:
        mov byte [rdi], 0        ; Ensure destination string is null terminated
        ret

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
