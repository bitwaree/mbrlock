; SPEAKER.ASM: Code snippets for speaker management


;TYPE: FUNCTION
;Initialize pc speaker for sounds
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
