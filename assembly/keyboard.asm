; KEYBOARD.ASM: Keyboard utilities snippets
; (https://github.com/bitwaree/mbrlock)
; Copyright (c) 2024 bitware.



; TYPE: NASM MACRO
; Read a character from the keyboard
;Usage:
;    get_char                   ; get the charecter input
;    cmp al, '<chr>'            ; compare the 'al' register with your <character>

; ------- DEF start -------
%macro get_char 0
    mov ah, 0h                  ; Function 0: Read character from keyboard
    int 16h                     ; BIOS interrupt 16h
    
; The character is now stored in the `al` register
; You can also check the ah register for the scan code
%endmacro
; ------- DEF end -------




; TYPE: NASM MACRO
; Checks if a key status in the keyboard.... (doesn't wait)
;Usage:
;    mov dl, '<chr>'
;    call get_keystate          ; get the charecter input
;
; Returns:
; 'al' -> (1 for true or, 0 for false)
;    

; ------- FUNC start -------
get_keystate:

    ; Check if a key is pressed
    mov ah, 1h                  ; Function 1: Check if key is pressed
    int 16h                     ; BIOS interrupt 16h
	
	cmp al, dl                  ; compare if the key passed is true
	jne char_stat_down          ; set zero if false
	
char_stat_up:
	mov al, 1                   ; set al = 1 if the key is true
	jmp get_keystate_exit
char_stat_down:
	xor al, al                  ; set al = 0 is the key if false
get_keystate_exit:
    
    ret
	
; ------- FUNC end -------





;TYPE: FUNCTION
;Reads a string from keyboard and stores at the specified address
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
	
	push cx                     ; backup cx register
	xor cl, cl                  ; NULLify cl

scan_str_scanloop:
    
	mov ah, 0h                  ; Function 0: Read character from keyboard
	int 16h                     ; BIOS interrupt 16h
	cmp al, 0x0D
	je scan_str_entr_received   ; Jump: prepare to exit if 'Enter' key is received
	
	cmp cl, dl                  ; check if it's the maximum length
	je scan_str_max_len_reached
	
	mov byte [bx], al           ; send the received byte in the (inc) address
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

