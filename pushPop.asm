section .data
	format db "Stack Position: %p, Contents: %x %x %x %x", 10, 0  ; %p for pointer

section .text
	global main
	extern printf

main:
	push dword 9
	push ebx
	mov ebx, esp
	push ebx
	push format
	call printf
	; Calculate how many bytes to clean up
	mov ecx, esp  ; current stack pointer after printf
	sub ecx, ebx  ; subtract initial stack pointer to get the difference
	add esp, ebx
	; Push some numbers on to the stack
	push dword 4
	push dword 3
	push dword 2
	push dword 1
	mov ebx, esp
	push ebx
	push format
	call printf
	; Calculate how many bytes to clean up
	mov ecx, esp  ; current stack pointer after printf
	sub ecx, ebx  ; subtract initial stack pointer to get the difference
	add esp, ebx

	; Exit program
	mov eax, 1  ; system call for exit
	xor ebx, ebx
	int 0x80
