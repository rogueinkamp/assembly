section .data
    msg db 'Hello, World!', 0Ah
    msg_len equ $ - msg

section .text
    global _start

_start:
    ; Set up system call arguments
    mov rax, 1          ; system call number for write
    mov rdi, 1          ; file descriptor (stdout)
    mov rsi, msg        ; message buffer
    mov rdx, msg_len    ; message length

    ; Make system call
    syscall

    ; Exit system call
    mov rax, 60         ; system call number for exit
    xor rdi, rdi        ; exit code (0)
    syscall
