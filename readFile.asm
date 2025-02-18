section .data
    filename db "example.txt", 0  ; Null-terminated filename
    mode     db "r", 0             ; Read mode for fopen

section .bss
    buffer resb 1024               ; Buffer to read lines into, 1024 bytes long
    fd resq 1                      ; File descriptor

section .text
    global _start

_start:
    ; Open the file
    mov rax, 2         ; sys_open
    mov rdi, filename  ; filename
    mov rsi, 0         ; O_RDONLY flag
    mov rdx, 0777      ; mode (not used with O_RDONLY)
    syscall
    test rax, rax      ; Check if open failed
    js .exit           ; If negative (error), jump to exit

    mov [fd], rax      ; Store file descriptor

.read_loop:
    ; Read a line
    mov rax, 0         ; sys_read
    mov rdi, [fd]      ; File descriptor
    mov rsi, buffer    ; Buffer to read into
    mov rdx, 1024      ; Max bytes to read
    syscall
    test rax, rax      ; Check if read returned 0 (EOF)
    jz .close_file     ; If so, we're done reading

    ; Print the line to STDOUT
    mov rdx, rax       ; Number of bytes read
    mov rax, 1         ; sys_write
    mov rdi, 1         ; STDOUT
    mov rsi, buffer    ; Buffer to write from
    syscall

    ; Check for newline or end of file
    cmp byte [buffer + rax - 1], 0xa ; Check if last byte is newline
    jne .read_loop     ; If not, continue reading (this might not be perfect for all cases)
    
    jmp .read_loop     ; Loop back to read another line

.close_file:
    ; Close the file
    mov rax, 3         ; sys_close
    mov rdi, [fd]      ; File descriptor
    syscall

.exit:
    ; Exit the program
    mov rax, 60        ; sys_exit
    xor rdi, rdi       ; Exit code 0
    syscall
