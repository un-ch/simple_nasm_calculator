CURRENT_OS = $(shell uname)
ifeq ($(CURRENT_OS), Linux)
	OS = OS_LINUX
	LDFLAGS = -m elf_i386
endif
ifeq ($(CURRENT_OS), FreeBSD)
	OS = OS_FREEBSD
	LDFLAGS = -m elf_i386_fbsd
endif

NASMFLAGS = -f elf -d$(OS)
NASM = nasm

num_summation: num_summation.o
	@$(LD) $(LDFLAGS) num_summation.o -o num_summation

num_summation.o: num_summation.asm
	@$(NASM) $(NASMFLAGS) num_summation.asm

run:
	@./num_summation
clean:
	@rm -f *.o num_summation
