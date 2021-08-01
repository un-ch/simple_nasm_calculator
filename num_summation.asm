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
	inc esi					; next byte of buffer memory
	jmp again

end_input:
	mov esi, buffer			; buffer adress --> ESI
	xor edi, edi
	xor eax, eax
	; EDI will hold sum:
loop:
	cmp byte [esi], 0		; EOF ?
	je div_preparation
	cmp byte [esi], 10		; line feed ?
	je .next_digit
	movzx eax, byte [esi]
	sub eax, 48
	add edi, eax
.next_digit:
	inc esi					; next symbol(?) in buffer memory
	jmp loop
	; EDI holds summ now
div_preparation:
	xor edx, edx
	xor eax, eax
	xor ebp, ebp
	mov eax, edi
	mov esi, 10
push_remainder:
	div esi
	push edx				; push remainder
	xor edx, edx
	inc ebp					; digit counter
	test eax, eax			; if the quotient equal to 0 (cmp eax, 0)
	jne push_remainder
pop_remainder:
	xor eax, eax
	test ebp, ebp			; digit counter
	je end_div
	pop eax
	mov [remainder], eax
	add byte [remainder], 48; get digit

	mov ecx, remainder
	mov edx, 4
	call print_digit

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
