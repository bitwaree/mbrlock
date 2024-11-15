; ------- DEF start -------

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
; ------- DEF end -------

