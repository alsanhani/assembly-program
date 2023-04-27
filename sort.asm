.data 
new_line  db    0dh,0ah,'$'
msg1      db    "enter first value (-32768..32767)!"
          db    0dh,0ah,'$'
msg2      db    0dh,0ah, "enter second value (-32768..32767)!"
          db    0dh,0ah, '$'
msg3      db    0dh,0ah, "enter third value (-32768..32767)!"
          db    0dh,0ah, '$'
msg4      db    0dh,0ah,0dh,0ah, "after sorting from biggest to smallest:",'$'
msg5      db    0dh,0ah, "num1 = ",'$'
msg6      db    0dh,0ah, "num2 = ", '$'
msg7      db    0dh,0ah, "num3 = ", '$'
num1      dw    ?
num2      dw    ?
num3      dw    ?
.stack 
 .code 
    push    ds
    mov     ax, 0
    push    ax
; set segment registers:                
    mov     ax,@data
    mov     ds, ax
    lea     dx, msg1
    call    puts       ; display the message.
    call    scan_num   ; input the number into cx.
    mov     num1, cx

; ask for second number:
    lea     dx, msg2
    call    puts       ; display the message.
    call    scan_num   ; input the number into cx.
    mov     num2, cx

; ask for third number:
    lea     dx, msg3
    call    puts       ; display the message.
    call    scan_num   ; input the number into cx.
    mov     num3, cx

; sorting:
    mov     bx, num1
    mov     cx, num2
    call    sort       ; exchange if bx<cx
    mov     num1, bx
    mov     num2, cx

    mov     bx, num2
    mov     cx, num3
    call    sort       ; exchange if bx<cx
    mov     num2, bx
    mov     num3, cx

    mov     bx, num1
    mov     cx, num2
    call    sort       ; exchange if bx<cx
    mov     num1, bx
    mov     num2, cx

; print the result:
    lea     dx, msg4
    call    puts

    lea     dx, msg5
    call    puts
    mov     ax, num1
    call    print_num ; print ax.

    lea     dx, msg6
    call    puts
    mov     ax, num2
    call    print_num ; print ax.

    lea     dx, msg7
    call    puts
    mov     ax, num3
    call    print_num ; print ax.

    lea     dx, new_line
    call    puts
    
    mov     ah, 0
    int     16h
;***********************************
; displays the message (dx-address),
; uses dos function to print:
puts    proc    near
        push    ax
        mov     ah, 09h
        int     21h
        pop     ax
        ret
endp

;************************************
; if bx < cx then exchanges them
; (works with signed numbers)
sort    proc    near
        cmp     bx, cx
        jge     compared
        xchg    bx, cx
compared:
        ret
endp

;***********************************
; gets the multi-digit SIGNED number from the keyboard,
; and stores the result in CX register:
SCAN_NUM        PROC    NEAR
        PUSH    DX
        PUSH    AX
        PUSH    SI
        MOV     CX, 0

        ; reset flag:
        MOV     CS:make_minus, 0

next_digit:

        ; get char from keyboard
        ; into AL:
        MOV     AH, 00h
        INT     16h
        ; and print it:
        MOV     AH, 0Eh
        INT     10h

        ; check for MINUS:
        CMP     AL, '-'
        JE      set_minus

        ; check for ENTER key:
        CMP     AL, 13  ; carriage return?
        JNE     not_cr
        JMP     stop_input
not_cr:


        CMP     AL, 8                   ; 'BACKSPACE' pressed?
        JNE     backspace_checked
        MOV     DX, 0                   ; remove last digit by
        MOV     AX, CX                  ; division:
        DIV     CS:ten                  ; AX = DX:AX / 10 (DX-rem).
        MOV     CX, AX
       ; PUTC    ' '                     ; clear position.
       ; PUTC    8                       ; backspace again.
        JMP     next_digit
backspace_checked:


        ; allow only digits:
        CMP     AL, '0'
        JAE     ok_AE_0
        JMP     remove_not_digit
ok_AE_0:        
        CMP     AL, '9'
        JBE     ok_digit
remove_not_digit:       
       mov al,' '
       call putc
        JMP     next_digit ; wait for next input.       
ok_digit:


        ; multiply CX by 10 (first time the result is zero)
        PUSH    AX
        MOV     AX, CX
        MUL     CS:ten                  ; DX:AX = AX*10
        MOV     CX, AX
        POP     AX

        ; check if the number is too big
        ; (result should be 16 bits)
        CMP     DX, 0
        JNE     too_big

        ; convert from ASCII code:
        SUB     AL, 30h

        ; add AL to CX:
        MOV     AH, 0
        MOV     DX, CX      ; backup, in case the result will be too big.
        ADD     CX, AX
        JC      too_big2    ; jump if the number is too big.

        JMP     next_digit

set_minus:
        MOV     CS:make_minus, 1
        JMP     next_digit

too_big2:
        MOV     CX, DX      ; restore the backuped value before add.
        MOV     DX, 0       ; DX was zero before backup!
too_big:
        MOV     AX, CX
        DIV     CS:ten  ; reverse last DX:AX = AX*10, make AX = DX:AX / 10
        MOV     CX, AX
        ;PUTC    8       ; backspace.
        ;PUTC    ' '     ; clear last entered digit.
        ;PUTC    8       ; backspace again.        
        JMP     next_digit ; wait for Enter/Backspace.
        
        
stop_input:
        ; check flag:
        CMP     CS:make_minus, 0
        JE      not_minus
        NEG     CX
not_minus:

        POP     SI
        POP     AX
        POP     DX
        RET
make_minus      DB      ?       ; used as a flag.
SCAN_NUM        ENDP





; this procedure prints number in AX,
; used with PRINT_NUM_UNS to print signed numbers:
PRINT_NUM       PROC    NEAR
        PUSH    DX
        PUSH    AX

        CMP     AX, 0
        JNZ     not_zero

       ; PUTC    '0'
        JMP     printed

not_zero:
        ; the check SIGN of AX,
        ; make absolute if it's negative:
        CMP     AX, 0
        JNS     positive
        NEG     AX

       ; PUTC    '-'

positive:
        CALL    PRINT_NUM_UNS
printed:
        POP     AX
        POP     DX
        RET
PRINT_NUM       ENDP



; this procedure prints out an unsigned
; number in AX (not just a single digit)
; allowed values are from 0 to 65535 (FFFF)
PRINT_NUM_UNS   PROC    NEAR
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX

        ; flag to prevent printing zeros before number:
        MOV     CX, 1

        ; (result of "/ 10000" is always less or equal to 9).
        MOV     BX, 10000       ; 2710h - divider.

        ; AX is zero?
        CMP     AX, 0
        JZ      print_zero

begin_print:

        ; check divider (if zero go to end_print):
        CMP     BX,0
        JZ      end_print

        ; avoid printing zeros before number:
        CMP     CX, 0
        JE      calc
        ; if AX<BX then result of DIV will be zero:
        CMP     AX, BX
        JB      skip
calc:
        MOV     CX, 0   ; set flag.

        MOV     DX, 0
        DIV     BX      ; AX = DX:AX / BX   (DX=remainder).

        ; print last digit
        ; AH is always ZERO, so it's ignored
        ADD     AL, 30h    ; convert to ASCII code.
       call putc


        MOV     AX, DX  ; get remainder from last div.

skip:
        ; calculate BX=BX/10
        PUSH    AX
        MOV     DX, 0
        MOV     AX, BX
        DIV     CS:ten  ; AX = DX:AX / 10   (DX=remainder).
        MOV     BX, AX
        POP     AX

        JMP     begin_print
        
print_zero:
       ; PUTC    '0'
        
end_print:

        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET
PRINT_NUM_UNS   ENDP



ten             DW      10      ; used as multiplier/divider by SCAN_NUM & PRINT_NUM_UNS.  
;****************************************************************************

putc    proc  near
        mov     ah, 0eh
        int     10h     
        ret
 endp
