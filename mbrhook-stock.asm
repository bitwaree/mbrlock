; MBR bootloader code for mbrlock
; This is a minimalistic version with no extra code.
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
    loadsector 0x8a00, 8, 2
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
    
    ;the code goes here


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

string1 db "This is a test string", 0



;------------Function Snippets------------;

; a test function
func1:
    push bx
    mov bx, ax
    pop bx

    ret
