; TYPE: NASM MACRO
;prints a charcater (char, color)
;Usage:
;    printc <char>, <color>

; ------- DEF start -------
%macro printc 2
	push bx
	mov ah, 0x0e
	mov al, %1;		Character to print
	mov bx, %2;		Color of the cheracter
	int 0x10

	pop bx
%endmacro
; ------- DEF end -------



;TYPE: FUNCTION
;prints a string
;Usage: 
;    mov si, <ptr>
;    call print_str

; ------- FUNC start -------
print_str:
	
    mov ah, 0x0e ; int 10h teletype function

; print loop
print_loop:

    lodsb
    cmp al, 0
    je print_done
    int 0x10
    jmp print_loop

print_done:
	ret

; ------- FUNC END -------
