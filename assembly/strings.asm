; STRINGS.asm: string manupulation ....just like libc :)
; (https://github.com/bitwaree/mbrlock)
; Copyright (c) 2024 bitware.




;TYPE: FUNCTION
;finds the length of a null-terminated string (strlen)
;Usage:
;    mov bx, <string>
;    call str_len
;
; Returns:
; 'al' -> (0<length<255) the length

; ------- FUNC start -------
str_len:
    
; passed : bx -> buffer address

; return : al -> length
    push bx
    xor al, al

str_cmp_loop:
    
	cmp byte [bx], 0
	je str_len_exit             ; goto exit if the null byte reached

	add bx, 1                   ; array++
	add al, 1                   ;    al++
	jmp str_cmp_loop            ; Continue the loop until null-byte reached
	

	
str_len_exit:
	pop bx
	ret
; ------- FUNC end -------






;TYPE: FUNCTION
;Compares two strings
;Usage:
;    mov bx, <string1>
;    mov dx, <string2>
;    call str_cmp
;
; Returns:
; 'al' -> 0 if the strings are identical

; ------- FUNC start -------
str_cmp:
    
; passed : bx -> buffer1 address
;        : dx -> buffer2 address

; return : al -> true/false

	push cx
	
    mov cx, bx
	mov bx, dx
	call str_len                ; Get the length of the second string first
	mov ah, al                  ; MOV that into ah
	
	mov bx, cx
	call str_len                ; Get the length of the first string
	
	cmp ah, al
	jne str_cmp_nonidentical    ; length is not equal means not identical
	
	xor al, al
str_cmp_scanloop:

    ; now 'al' is going to be index counter and 'ah' is the string length
	; and 'ch' is going to contain the str2 char and 'cl' will contain str1 char
	push bx                     ; backup str1
	mov bx, dx                  ; load str2 in `bx`
	mov ch, byte [bx]           ; store the char of str2 on 'ch'
	
	pop bx                      ; get the previous 'bx' value (str1) back
	mov cl, byte [bx]           ; store the char of str1 on 'cl'
	
	cmp ch, cl
	jne str_cmp_nonidentical    ; char mismatch means non-identical
	
	cmp ah, al                  ; if the scan index counter is same as strlen
	je str_cmp_identical        ; it's identical
	add al, 1                   ; else, increment 'al' by one
	add bx, 1                   ; and,  increment 'bx' by one
	add dx, 1                   ; and,  increment 'dx' by one
    jmp str_cmp_scanloop        ; loop it :)
	
str_cmp_nonidentical:
	mov al, 1                  ; set 'al' to 1
	jmp str_cmp_exit            ; exit

str_cmp_identical:
    xor al, al                  ; set 'al' to zero
	jmp str_cmp_exit            ; exit

str_cmp_exit:

	pop cx                      ; get the cx value back
	
	ret
; ------- FUNC end -------
