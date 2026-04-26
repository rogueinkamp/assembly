; Shared definitions for kvstore
section .data
    ; Buffers
    buffer times 256 db 0    ; Main I/O buffer
    input_buffer times 256 db 0
    command_buffer times 32 db 0  
    data_buffer times 256 db 0

    ; File operations
    filename db "kv_store.txt", 0
    mode db "a+", 0          ; File mode: append+/read
    fd dd 0                  ; File descriptor
    
    ; Common strings
    newline db 10, 0         ; \n
    space db " ", 0          ; Space character
