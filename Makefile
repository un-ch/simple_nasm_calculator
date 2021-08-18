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

simple_nasm_calculator: simple_nasm_calculator.o
	@$(LD) $(LDFLAGS) simple_nasm_calculator.o -o simple_nasm_calculator

simple_nasm_calculator.o: simple_nasm_calculator.asm
	@$(NASM) $(NASMFLAGS) simple_nasm_calculator.asm

run:
	@./simple_nasm_calculator
clean:
	@rm -f *.o simple_nasm_calculator
