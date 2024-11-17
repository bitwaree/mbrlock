; MISC: Modified defs, contains customized definitions for verious needs
; (https://github.com/bitwaree/mbrlock)
; Copyright (c) 2024 bitware.



;TYPE: FUNCTION
;Reads a string from keyboard and stores at the specified address
; MOD: prints a asterisk (*) whenever a charecter entered
;Usage:
;    mov bx, <buffer_address>
;    mov dl, <max_buffer_len>
;    call scan_str
;
; Returns:
; 'al' -> how many char read (strlen)
; 'bx' -> pointer to end of the string (null)

; ------- FUNC start -------
scan_str:
    
; passed : bx -> buffer address
;        : dl -> buffer max length

; return : al -> read buffer length
	mov ah, 0h                  ; Function 0: Read character from keyboard
	push cx                     ; backup cx register
	xor cl, cl                  ; NULLify cl

scan_str_scanloop:
    mov ah, 0h                  ; Function 0: Read character from keyboard
	int 16h                     ; BIOS interrupt 16h
	cmp al, 0x0D
	je scan_str_entr_received   ; Jump: prepare to exit if enter key is received
	
	cmp cl, dl                  ; check if it's the maximum length
	je scan_str_max_len_reached
	
	mov byte [bx], al           ; send the received byte in the (inc) address
	printc '*', 0x7             ; Show a '*' whenever a key recieved
	add bx, 1                   ; array++
	add cl, 1                   ; cl   ++
	;sleep 0x1, 0x7000           ; a little delay to avoid repeat
	jmp scan_str_scanloop       ; Continue the loop until enter key is received
	
	
scan_str_max_len_reached:	
scan_str_entr_received:
	
scan_str_exit:

	mov byte [bx], 0            ; Null terminate the string
	mov al, cl                  ; Move the counter to al
	pop cx
	
	ret
; ------- FUNC end -------




;TYPE: FUNCTION
;Reads a string from keyboard and stores at the specified address
; MOD: prints the charecter one is entered
;Usage:
;    mov bx, <buffer_address>
;    mov dl, <max_buffer_len>
;    call scan_str
;
; Returns:
; 'al' -> how many char read (strlen)
; 'bx' -> pointer to end of the string (null)

; ------- FUNC start -------
scan_str:
    
; passed : bx -> buffer address
;        : dl -> buffer max length

; return : al -> read buffer length
	mov ah, 0h                  ; Function 0: Read character from keyboard
	push cx                     ; backup cx register
	xor cl, cl                  ; NULLify cl

scan_str_scanloop:
    mov ah, 0h                  ; Function 0: Read character from keyboard
	int 16h                     ; BIOS interrupt 16h
	cmp al, 0x0D
	je scan_str_entr_received   ; Jump: prepare to exit if enter key is received
	
	cmp cl, dl                  ; check if it's the maximum length
	je scan_str_max_len_reached
	
	mov byte [bx], al           ; send the received byte in the (inc) address
	printc '*', 0x7             ; Show a '*' whenever a key recieved
	add bx, 1                   ; array++
	add cl, 1                   ; cl   ++
	;sleep 0x1, 0x7000           ; a little delay to avoid repeat
	jmp scan_str_scanloop       ; Continue the loop until enter key is received
	
	
scan_str_max_len_reached:	
scan_str_entr_received:
	
scan_str_exit:

	mov byte [bx], 0            ; Null terminate the string
	mov al, cl                  ; Move the counter to al
	pop cx
	
	ret
; ------- FUNC end -------
