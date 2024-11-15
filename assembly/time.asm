;TYPE: FUNCTION
; makes a delay
;Usage: 
;    call delay

; ------- FUNC start -------
delay:
    mov cx, 0xFFFF      ; Set the outer loop counter
outer_loop:
    mov bx, 0xFFFF      ; Set the inner loop counter
inner_loop:
    nop                  ; No operation (do nothing)
    dec bx               ; Decrement inner loop counter
    jnz inner_loop       ; Repeat until bx is zero
    dec cx               ; Decrement outer loop counter
    jnz outer_loop       ; Repeat until cx is zero
    ret                  ; Return from delay function
; ------- FUNC stop -------




;TYPE: FUNCTION
; makes a delay
;Usage:
;    mov dx, <microseconds>
;    call sleep_microsec

; ------- FUNC start -------
sleep_microsec:

    mov cx, 0          ; Set CX to 0 for the high word (not used)
    mov dx, dx         ; Set DX to microseconds (2 seconds)
    mov ah, 86h        ; Function to wait
    int 0x15	; Call BIOS interrupt
; ------- FUNC stop -------



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
