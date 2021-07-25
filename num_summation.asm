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

buffer				resb 120

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
	mov esi, buffer			; buffer adress --> esi
	mov edi, 0				; counter of chars
again:
	mov eax, SYSCALL_READ	; 3
	mov ebx, STDIN			; 0
	mov ecx, esi			; buffer adress --> ecx
	mov edx, 1				; length
	int 80h

	cmp [esi], byte 0		; EOF ?
	je loop

	cmp [esi], byte 10		; new line ?
	inc esi					; next byte of buffer
	;inc edi					; inc char counter
	jmp again

	; if (summation < 10) then print a single digit:
	; cmp al, 10
	; jl print_summation
	mov ax, [buffer]		; divident --> AX (16 bits)
	mov bx, 10				; divider --> BX (16 bits)
	; esi will hold summation:
	xor esi, esi
	; push reminders:
loop:
	xor dx, dx
	div bx
	push dx
	inc esi
	; quotient now in AX
	; reminder now in DX
	cmp ax, 0
	jne loop
loop_2:
	; pop and print reminders:
	pop dx
	mov [sum], dx
	add [sum], byte 48
	mov ecx, sum
	mov edx, 1				; length
	call print_number_symbol
	dec esi
	cmp esi, 0
	jne loop_2

	call print_new_line
	jmp quit

nice_loop:
	xor edi, edi
	mov esi, buffer
nice_loop_2:
	mov ecx, esi			; adress for syscall
	mov edx, 1				; length
	call print_number_symbol
	;call print_new_line
	inc esi
	cmp [esi], byte 0		; EOF ?
	je quit
	jmp nice_loop_2

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

;%ifdef OS_FREEBSD
	;push 1					; length
	;push summand_1
	;push STDIN
	;mov eax, SYSCALL_READ	; 3
	;push eax				; avoiding calling "kernel" subroutine
	;int 80h
	;add esp, 16				; cleaning the stack
;%elifdef OS_LINUX
	;mov ecx, summand_1
	;mov edx, 1				; length
	;mov eax, SYSCALL_READ	; 3
	;mov ebx, STDIN			; 0
	;int 80h
;%endif

