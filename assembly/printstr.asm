; PRINTSTR.ASM: string printing apis
; (https://github.com/bitwaree/mbrlock)
; Copyright (c) 2024 bitware.



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





;TYPE: FUNCTION
;goto the next line
;Usage: 
;    call enter_nextline

; ------- FUNC start -------
enter_nextline:
	
	push bx
	mov ah, 0x0e
	mov al, 0x0a;		Next line char print
	;mov bx, %2;		Color of the cheracter
	int 0x10
	
	mov al, 0x0D;		move cursor to the start
	;mov bx, %2;		Color of the cheracter
	int 0x10
	
	pop bx

	ret

; ------- FUNC END -------




;TYPE: FUNCTION
;prints a string in video mode
;Usage:
;    mov bx, <string>
;    mov cx, <attribute>
;    call vid_print_str

; ------- FUNC start -------
vid_print_str:

	;mov dx, bx	;reset dx register as well
	;bx and dx equals 0
	;mov bx, bx	            ;acts like a (char *)

vid_print_str_loop:

	;mov bx, dx
	;add bx, msg

	cmp byte [bx], 0
	je vid_print_str_done	;Jmp to hlt if the string is terminated with NULL byte

	printc byte [bx], cx	;Print char byte
	add bx, 1
	jmp vid_print_str_loop

vid_print_str_done:
	
	ret

; ------- FUNC END -------
