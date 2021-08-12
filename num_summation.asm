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
remainder			resb 4
buffer				resb 120

section .text
print_digit:
	push ebp				; save an old value of EBP
	mov ebp, esp
%ifdef OS_FREEBSD
	push STDOUT				; 1
	mov	eax, SYSCALL_WRITE	; 4
	push eax				; avoiding calling "kernel" subroutine
	int 80h
	add esp, 16				; cleaning the stack
%elifdef OS_LINUX
	mov	eax, SYSCALL_WRITE	; 4
	mov	ebx, STDOUT			; 1
	int 80h
%else
%error define OS_FREEBSD or OS_LINUX
%endif
	mov esp, ebp
	pop ebp					; restore an old value of EBP
	ret

print_new_line:
	push ebp				; save an old value of EBP
	mov ebp, esp
%ifdef OS_FREEBSD
	push NEW_LINE_LENGTH
	push NEW_LINE
	push STDOUT				; 1
	mov eax, SYSCALL_WRITE	; 4
	push eax				; avoiding calling "kernel" subroutine
	int 80h
	add esp, 16				; cleaning the stack
%elifdef OS_LINUX
	mov ecx, NEW_LINE
	mov edx, NEW_LINE_LENGTH
	mov eax, SYSCALL_WRITE	; 4
	mov ebx, STDOUT			; 1
	int 80h
%endif
	mov esp, ebp
	pop ebp					; restore an old value of EBP
	ret

_start:
	mov esi, buffer			; buffer adress --> ESI
again:
	; input number:
%ifdef OS_FREEBSD
	push 1					; length
	push esi
	push STDIN
	mov eax, SYSCALL_READ	; 3
	push eax				; avoiding calling "kernel" subroutine
	int 80h
	add esp, 16				; cleaning the stack
%elifdef OS_LINUX
	mov eax, SYSCALL_READ	; 3
	mov ebx, STDIN			; 0
	mov ecx, esi			; buffer adress --> ecx
	mov edx, 1				; length
	int 80h
%endif

	cmp byte [esi], 0		; EOF ?
	je end_input
	inc esi					; next byte of [buffer] memory
	jmp again

	; ESI now holds the adress of the last input element in [buffer] memory \
	; we assume that current ESI value is limited null;
end_input:
	xor edi, edi
	xor eax, eax
	xor ebx, ebx

	sub esi, 1				; move to a penultimate element in the [buffer] memory

	; EBX will hold the result of raising the base 10 to the power 0, \
	; which is need for decimal representation
	mov ebx, 1
	; EDI will hold sum:
loop:
	cmp esi, buffer			; first element ?
	jl div_preparation
	cmp byte [esi], 10		; line feed ?
	je .next_summand
.next_digit:
	movzx eax, byte [esi]
	sub eax, 48				; get value
	mul ebx
	add edi, eax			; EDI holds current sum
	dec esi					; previous byte(?) in buffer memory

	; update the result of raising the base 10 to the power for the next iteration:
	mov eax, 10
	mul ebx
	mov ebx, eax

	jmp loop
.next_summand:
	dec esi					; previous byte(?) in buffer memory
	mov ebx, 1				; result of raising the base 10 to the power 0
	jmp loop

	; EDI holds summ now
div_preparation:
	mov eax, edi
	mov esi, 10
push_remainder:
	div esi
	test eax, eax			; if the quotient is equal to 0
	je .last_push
	push edx				; push remainder
	xor edx, edx
	inc ebp					; counting the numbers of "pushing"
	jmp push_remainder

.last_push:
	push edx
	xor edx, edx
	inc ebp					; counting the numbers of "pushing"

pop_remainder:
	xor eax, eax
	test ebp, ebp			; if counter of "pushing" is equal to 0
	je end_div
	pop eax
	mov [remainder], eax
	add byte [remainder], 48; get digit
%ifdef OS_FREEBSD
	push 4
	push remainder
	push STDOUT
	mov	eax, SYSCALL_WRITE	; 4
	push eax				; avoiding calling "kernel" subroutine
	int 80h
	add esp, 16				; cleaning the stack
%elifdef OS_LINUX
	mov ecx, remainder
	mov edx, 4
	call print_digit
%endif
	dec ebp
	jmp pop_remainder
end_div:
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
