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
    command_buffer_length equ 4

    GENERIC_MESSAGE_PROMPT db "DEBUG: "
    GENERIC_MESSAGE_PROMPT_LEN equ $ - GENERIC_MESSAGE_PROMPT
    NEWLINE db 0x0A

section .bss
    input_buffer resb 259; temp for all data (4 + 255 max)
    command_buffer resb 4 ; For storing the key
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
    mov rdi, command_buffer
    mov rcx, 4
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
    mov rsi, input_buffer ; set store to buffer - rsi is pointing to the buffer that has the data
    mov rdx, 259  ; max bytes to read (may need to adjust later for logner json strings)
    syscall

;    ; Check if we read any data
             ; Check if we read enough data
    cmp rax, 4               ; Need at least 4 bytes for command
    jl main_loop             ; If less than 4, loop back

    ; Copy first 4 bytes to command_buffer
    mov rsi, input_buffer    ; Source: input_buffer
    mov rdi, command_buffer  ; Destination: command_buffer
    mov rcx, 4               ; Copy 4 bytes
    rep movsb                ; Perform copy
    mov byte [command_buffer + 4], 0  ; Null-terminate command_buffer

    ; Process remaining data into data_buffer, skipping leading spaces
    mov rsi, input_buffer    ; Start of input buffer
    add rsi, 4               ; Skip first 4 bytes
    mov rdi, data_buffer     ; Destination: data_buffer
    mov rcx, rax             ; Total bytes read
    sub rcx, 4               ; Remaining bytes
    mov rax, 1
    mov rdi, 1
    mov rsi, GENERIC_MESSAGE_PROMPT
    mov rdx, GENERIC_MESSAGE_PROMPT_LEN
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, command_buffer
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
    jle process_command      ; If no remaining bytes, skip to command processing

skip_leading_spaces:
    cmp byte [rsi], ' '      ; Check for space
    jne copy_data            ; If not space, start copying
    inc rsi                  ; Skip space
    dec rcx                  ; Reduce count
    jnz skip_leading_spaces  ; Continue if more bytes
    jmp process_command      ; If all spaces, process command

copy_data:
    mov rbx, rcx             ; Save original length for trimming
    rep movsb                ; Copy rcx bytes to data_buffer

    ; Trim trailing spaces from data_buffer
    mov rsi, data_buffer     ; Start of data_buffer

    add rsi, rbx             ; Point to end of copied data
    dec rsi                  ; Last character
    mov rcx, rbx             ; Length of data in data_buffer

trim_trailing_spaces:
    cmp rcx, 0               ; Check if length is 0
    jle trim_done            ; If so, done
    cmp byte [rsi], ' '      ; Check if current byte is space
    jne trim_done            ; If not, done
    dec rsi                  ; Move back
    dec rcx                  ; Reduce length
    jmp trim_trailing_spaces

trim_done:
    mov byte [rsi + 1], 0    ; Null-terminate after last non-space

process_command:
    ; Optional: Print command_buffer for debugging
    mov rax, 1               ; sys_write
    mov rdi, 1               ; stdout
    mov rsi, command_buffer  ; Command

    mov rdx, 4               ; Length 4
    syscall

    ; Optional: Print data_buffer for debugging
    mov rax, 1               ; sys_write
    mov rdi, 1               ; stdout
    mov rsi, data_buffer     ; Data
    mov rdx, rcx             ; Length of trimmed data
    syscall
    ; Compare command_buffer with "GET "
    mov rsi, command_buffer
    mov rdi, get_str
    call strcmp
    test eax, eax
    jz handle_get

    ; Compare command_buffer with "SET "
    mov rsi, command_buffer
    mov rdi, set_str
    call strcmp

    test eax, eax
    jz handle_set

    ; Compare command_buffer with "EXIT"
    mov rsi, command_buffer
    mov rdi, exit_str
    call strcmp
    test eax, eax
    jz exit_program

    ; If no match, loop back (or handle error)
    jmp main_loop

handle_get:
    mov rax, 1
    mov rdi, 1
    mov rsi, get_msg_log
    mov rdx, get_msg_log_len
    syscall
    mov rax, 1
    mov rdi, 1
    mov rsi, NEWLINE
    mov rdx, 1
    syscall
    mov rax, 1
    mov rdi, 1
    mov rsi, GENERIC_MESSAGE_PROMPT
    mov rdx, GENERIC_MESSAGE_PROMPT_LEN
    syscall
    mov rdi, buffer
    call get_length
    mov rdx, rax
    mov rax, 1
    mov rdi, 1
    mov rsi, data_buffer
    syscall
    mov rax, 1
    mov rdi, 1
    mov rsi, NEWLINE
    mov rdx, 1
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

get_length:
    xor rax, rax            ; Clear rax (will hold length)

.loop:
    cmp byte [rdi + rax], 0 ; Check if current byte is null (0)
    je .done                ; If null, exit loop
    inc rax                 ; Increment length
    jmp .loop               ; Continue checking next byte
.done:
    ret
