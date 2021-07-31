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

sum					resb 1
result				resb 4

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
	mov esi, buffer			; buffer adress --> ESI
	;mov edi, 0				; counter of chars
again:
	; input number:
	mov eax, SYSCALL_READ	; 3
	mov ebx, STDIN			; 0
	mov ecx, esi			; buffer adress --> ecx
	mov edx, 1				; length
	int 80h

	cmp byte [esi], 0		; EOF ?
	je end_input
	inc esi					; next byte of buffer memory
	jmp again

end_input:
	mov esi, buffer			; buffer adress --> ESI
	xor edi, edi
	; EDI will hold summ:
loop:
	cmp byte [esi], 0		; EOF ?
	je print_remainder
	cmp byte [esi], 10		; line feed ?
	je .next_digit
	sub byte [esi], 48		; get value of digit
	add edi, [esi]			; add to summ
	add byte [esi], 48
.next_digit:
	inc esi					; next simbol(?) in buffer memory
	jmp loop

	; EDI holds summ now
print_summ:
	mov [sum], edi
	add byte [sum], 48		; get digit
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
	sub byte [sum], 48		; get value of digit
	call print_new_line

print_remainder:
	mov [result], edi
	xor edx, edx
	xor eax, eax
	xor ebp, ebp
	mov al, [result]		; ??????????????????
	mov esi, 10

make_div:
	div esi
	push edx				; push reminder
	xor edx, edx
	inc ebp
	cmp eax, 0				; if the quotient == 0
	jne make_div
pop_remainder:
	xor eax, eax
	cmp ebp, 0
	je end_div
	pop eax
	mov [result], eax
	add byte [result], 48	; get digit

	mov ecx, result
	mov edx, 4
	mov	eax, SYSCALL_WRITE	; 4
	mov	ebx, STDOUT			; 1
	int 80h

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
