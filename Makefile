# Build the kvstore application
KVSTORE_SRC = kvstore/server.asm kvstore/get.asm kvstore/set.asm kvstore/storage.asm kvstore/shared.inc
KVSTORE_OBJ = $(KVSTORE_SRC:.asm=.o)

all: kvstore_app

kvstore_app: $(KVSTORE_OBJ)
	ld -o $@ $^

%.o: %.asm
	nasm -f elf64 -o $@ $<

clean:
	rm -f $(KVSTORE_OBJ) kvstore_app

.PHONY: all clean
