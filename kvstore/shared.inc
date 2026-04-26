; Shared definitions for kvstore
section .data
    ; Buffers
    buffer times 256 db 0  ; Shared buffer for input/output
    input_buffer times 256 db 0
    command_buffer times 32 db 0
    data_buffer times 256 db 0

    ; File handling
    filename db "kv_store.txt", 0
    mode db "a+", 0        ; Append mode for writing, read for reading
    fd dd 0                ; File descriptor

    ; Common strings
    newline db 10, 0       ; ASCII newline
    space db " ", 0
