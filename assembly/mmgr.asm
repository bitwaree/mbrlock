; MMGR.ASM: memory management stuffs
; (https://github.com/bitwaree/mbrlock)
; Copyright (c) 2024 bitware.


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




;TYPE: FUNCTION
;loads a sector at a specified address
;Usage: 
;    push <sector_count>
;    push <sector_num>
;    push <address>
;    call load_sector

; ------- FUNC start -------
load_sector:
	
	;get the arguments from stack
	pop bx             ; pop the <address>
	pop cx             ; pop the <sector_num>
	pop ax             ; pop the <sector_count>
	
	; Load the next stage (assume it's in the next sector)
    ;mov bx, 0x7C00    ; Load address for the next stage
    mov ah, 0x02       ; BIOS function to read sectors
    mov al, al         ; Number of sectors to read
    mov ch, 0          ; Cylinder
    mov cl, cl         ; Sector number ('n'th sector)
    mov dh, 0          ; Head
    mov bx, bx         ; Load to address (eg. 0x7C00)
    int 0x13           ; Call BIOS to read sector
	
	ret

; ------- FUNC END -------




;TYPE: FUNCTION
;loads a sector at a specified address
;Usage: 
;    mov bx, <address>               ; pop the <address>
;    mov cl, <sector_num>            ; pop the <sector_num>
;    mov al, <sector_count>          ; pop the <sector_count>
;    call load_sector

; ------- FUNC start -------
load_sector:
	
	; Load the next stage (assume it's in the next sector)
    ;mov bx, 0x7C00    ; Load address for the next stage
    mov ah, 0x02       ; BIOS function to read sectors
    mov al, al         ; Number of sectors to read
    mov ch, 0          ; Cylinder
    mov cl, cl         ; Sector number ('n'th sector)
    mov dh, 0          ; Head
    mov bx, bx         ; Load to address (eg. 0x7C00)
    int 0x13           ; Call BIOS to read sector
	
	ret

; ------- FUNC END -------



