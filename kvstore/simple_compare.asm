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

section .text
    global _start

_start:
    jmp main_loop

 main_loop:
    ; Print the prompt
    mov rax, 1
    mov rdi, 1
    mov rsi, prompt_msg
    mov rdx, prompt_msg_len
    syscall

    ; Read command from stdin
    mov rax, 0
    mov rdi, 0
    mov rsi, buffer
    mov rdx, 255  ; Read up to 255 bytes
    syscall

    ; Find the actual length of the input (up to newline or null)
    mov rcx, rax  ; rcx now holds the length read
    mov byte [buffer + rcx], 0  ; Null-terminate after the actual input


    ; Trim newline if present
    dec rcx  ; Check if last char is newline
    cmp byte [buffer + rcx], 10  ; ASCII for '\n'
    jne .no_newline
    mov byte [buffer + rcx], 0  ; Remove newline by setting to null
    dec rcx
    .no_newline:


    ; Now compare, but only up to the length of each command

    mov rsi, buffer
    mov rdi, get_str
    call strcmp
    test eax, eax
    jz match_found

    mov rsi, buffer
    mov rdi, set_str
    call strcmp
    test eax, eax
    jz match_found

    mov rsi, buffer

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

match_found:
    mov rax, 1
    mov rdi, 1

    mov rsi, match_msg
    mov rdx, match_msg_len
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
