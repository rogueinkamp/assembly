compile-and-run-64:
	nasm -f elf64 hello.asm -o hello.o && ld hello.o -o hello && ./hello

compile-and-run-32:
	nasm -f elf hello.asm -o hello.o && ld -m elf_i386 hello.o -o hello && ./hello
