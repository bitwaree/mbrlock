; MBR Bootloader that jumps to an address at offset 0x520
; (Beyond the first 512 bytes of the sector)

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




;-------Start of Assembly-------;


[org 0x7c00]            ; Start of the boot sector, it's loaded at 0x7c00 in memory

init:
	;cli
	;xor ax,	ax
	;mov ds, ax          ;initialize segment registers
	;mov es, ax
	;mov ss, ax
	sti                 ; Activate interrupts

intercept:
	;load (8+9)th sector at physical address: 0x7c00 + (0x200 * 7) = 0x8a00
    loadsector 0x8a00, 8, 2
	jmp mbrlocker       ; Hook to mbrlocker code
	
	times 0x13-($-$$) db 0x90   ; nops
hookend:
	
	
times 510-($-$$) db 0   ; boot signature
dw 0xaa55

;sector 8
times 3584-($-$$) db 0

;start of sector 8
mbrlocker:

	;acctual init code
	cli					; Disable Interrupts
	xor ax, ax          ; Initialization of registers
	
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, 0x7c00      ; Setup StackPointer
	mov bp, sp          ; Setup BasePointer
	sti 				; Re-Enable Interrupts
	
	;acctual hack

    textmode_clear
	mov si, bannerstr
	call print_str
	
	sleep 0x8, 0xff00
	

;-----excess mbr code------
    times 0xFFD-($-$$) db 0x90   ; nops
;-----excess code end-----
	
	jmp hookend

; 9th sector
;------------Constant Data definations------------;


bannerstr:
    db 0x0A, 0x0A, 0x0A, 0x0A, 0x0A, 0x0A
    ;db '            _/      _/  _/_/_/    _/_/_/    _/                      _/         '
    ;db '           _/_/  _/_/  _/    _/  _/    _/  _/    _/_/      _/_/_/  _/  _/      '
    ;db '          _/  _/  _/  _/_/_/    _/_/_/    _/  _/    _/  _/        _/_/         '
    ;db '         _/      _/  _/    _/  _/    _/  _/  _/    _/  _/        _/  _/        '
    ;db '        _/      _/  _/_/_/    _/    _/  _/    _/_/      _/_/_/  _/    _/       '
    ;db 0
	
    db '                         __  ______  ___  __         __                        '
    db '                        /  |/  / _ )/ _ \/ /__  ____/ /__                      '
    db '                       / /|_/ / _  / , _/ / _ \/ __/  `_/                      '
    db '                      /_/  /_/____/_/|_/_/\___/\__/_/\_\                       '
	db '                                               ----by bitware                  '
	db 0


;------------Extra needed Snippets------------;


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


