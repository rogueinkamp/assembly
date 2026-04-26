%include "shared.inc"

section .data
    file_error_msg db "GET ERROR", 10, 0

section .text
    global handle_get

handle_get:
    ; Open file
    mov rax, 2              ; sys_open
    mov rdi, filename
    mov rsi, 0              ; O_RDONLY
    syscall
    cmp rax, 0
    jl .error
    
    ; Read file
    mov rdi, rax            ; File descriptor 
    mov rax, 0              ; sys_read
    mov rsi, buffer         ; Reuse main buffer
    mov rdx, 255            ; Max bytes
    syscall
    
    ; Close file
    mov rax, 3              ; sys_close
    syscall
    
    ret
    
.error:
    mov rax, 1
    mov rdi, 1
    mov rsi, file_error_msg
    mov rdx, 13
    syscall
    ret
