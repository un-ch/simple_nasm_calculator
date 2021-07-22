global _start

section .data
NEW_LINE			db	10
NEW_LINE_LENGTH		equ	$-NEW_LINE
EXIT_SUCCESS_CODE 	equ	0

STDIN				equ 0
STDOUT				equ 1
STDERR				equ 2

SYSCALL_EXIT		equ 1
SYSCALL_READ		equ 3
SYSCALL_WRITE		equ 4

section .bss

summand_1			resb 1
eol_1				resb 1
summand_2			resb 1
eol_2				resb 1
sum					resb 1

section .text

print_number_symbol:
%ifdef OS_FREEBSD
	push STDOUT				; 1
	mov	eax, SYSCALL_WRITE	; 4
	push eax				; avoiding calling "kernel" subroutine
	int 80h
	add esp, 16				; cleaning the stack
	ret
%elifdef OS_LINUX
	mov	eax, SYSCALL_WRITE	; 4
	mov	ebx, STDOUT			; 1
	int 80h
	ret
%else
%error define OS_FREEBSD or OS_LINUX
%endif

print_new_line:
%ifdef OS_FREEBSD
	push NEW_LINE_LENGTH
	push NEW_LINE
	push STDOUT				; 1
	mov eax, SYSCALL_WRITE	; 4
	push eax				; avoiding calling "kernel" subroutine
	int 80h
	add esp, 16				; cleaning the stack
	ret
%elifdef OS_LINUX
	mov ecx, NEW_LINE
	mov edx, NEW_LINE_LENGTH
	mov eax, SYSCALL_WRITE	; 4
	mov ebx, STDOUT			; 1
	int 80h
	ret
%endif

_start:
	; input summand 1:
%ifdef OS_FREEBSD
	push 1					; length
	push summand_1
	push STDIN
	mov eax, SYSCALL_READ	; 3
	push eax				; avoiding calling "kernel" subroutine
	int 80h
	add esp, 16				; cleaning the stack
%elifdef OS_LINUX
	mov ecx, summand_1
	mov edx, 1				; length
	mov eax, SYSCALL_READ	; 3
	mov ebx, STDIN			; 0
	int 80h
%endif

	; correct new line representation:
%ifdef OS_FREEBSD
	push 1					; length
	push eol_1
	push STDIN				; 1
	mov eax, SYSCALL_READ	; 3
	push eax				; avoiding calling "kernel" subroutine
	int 80h
	add esp, 16				; cleaning the stack

%elifdef OS_LINUX
	mov ecx, eol_1
	mov edx, 1				; length
	mov eax, SYSCALL_READ	; 3
	mov ebx, STDIN			; 0
	int 80h
%endif

	; input summand 2:
%ifdef OS_FREEBSD
	push 1					; length
	push summand_2
	push STDIN
	mov eax, SYSCALL_READ	; 3
	push eax				; avoiding calling "kernel" subroutine
	int 80h
	add esp, 16				; cleaning the stack
%elifdef OS_LINUX
	mov ecx, summand_2
	mov edx, 1				; length
	mov eax, SYSCALL_READ	; 3
	mov ebx, STDIN			; 0
	int 80h
%endif

	; correct new line representation:
%ifdef OS_FREEBSD
	push 1					; length
	push eol_1
	push STDIN				; 1
	mov eax, SYSCALL_READ	; 3
	push eax				; avoiding calling "kernel" subroutine
	int 80h
	add esp, 16				; cleaning the stack

%elifdef OS_LINUX
	mov ecx, eol_1
	mov edx, 1				; length
	mov eax, SYSCALL_READ	; 3
	mov ebx, STDIN			; 0
	int 80h
%endif

	xor al, al ; AL register will hold the summation of two numbers

	sub [summand_1], byte 48 ; get the "real number value" through its ascii code
	add al, [summand_1]
	add [summand_1], byte 48 ; ascii code of the number

	sub [summand_2], byte 48 ; get the "real number value" through its ascii code
	add al, [summand_2]
	add [summand_2], byte 48 ; ascii code of the number

	mov [sum], al
	; now [sum] holds the "real number value" of summation. \
	; if we want to print its value, we should transformate summation value \
	; due to the ascii table:
	; add [sum], byte 48

	; if (summation < 10) then print a single digit:
	cmp al, 10
	jl print_summation

	mov ax, [sum]			; divident --> AX (16 bits)
	mov bx, 10				; divider --> BX (16 bits)
loop:
	xor dx, dx
	div bx
	; quotient now in AX
	; reminder now in DX
	push dx
loop_2:
	pop dx
	mov [sum], dx		; reminder --> DX


print_summation:
	add [sum], byte 48
%ifdef OS_FREEBSD
	push 1					; length
	push sum
	push STDOUT				; 1
	mov	eax, SYSCALL_WRITE	; 4
	push eax				; avoiding calling "kernel" subroutine
	int 80h
	add esp, 16				; cleaning the stack

%elifdef OS_LINUX
	mov ecx, sum
	mov edx, 1				; length
	call print_number_symbol
%endif
	call print_new_line

quit:
%ifdef OS_FREEBSD
	push EXIT_SUCCESS_CODE
	mov eax, SYSCALL_EXIT	; 1
	push eax				; avoiding calling "kernel" subroutine
	int 80h
%elifdef OS_LINUX
	mov eax, SYSCALL_EXIT	; 1
	mov ebx, EXIT_SUCCESS_CODE
	int 80h
%endif
