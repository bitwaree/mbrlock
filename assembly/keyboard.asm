; KEYBOARD.ASM: Keyboard utilities snippets



;TYPE: FUNCTION
;Reads a string from keyboard and stores at the specified address
;Usage:
;    mov dx, <buffer_address>
;    call scan_str
;
;<buffer_address>:
; db <the_max_length>           ; [before calling] the first byte  = max length
; db 0                          ; [ after calling] the second byte = the actual length
; times <the_max_length> db 0   ; the string

; ------- FUNC start -------
scan_str:
    ; Prepare the buffer for reading
    mov dx, buffer   ; Load address of the buffer
    mov ah, 0Ah      ; Function 0Ah - Buffered input
    int 21h          ; Call DOS interrupt

    ; The string is now stored in 'string' buffer
    ; The first byte of the buffer contains the maximum length
    ; The second byte contains the actual length of the string
    ; The string itself starts from the third byte

    ret
; ------- FUNC end -------




