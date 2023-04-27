jmp start
fact dw 1
msg1 db 0Dh,0Ah, 'enter the number: $' 
msg2 db 0Dh,0Ah, 'factorial is: $' 
msg3 db 0Dh,0Ah, 'the result is too big!', 0Dh,0Ah, 'use values from 0 to 8.$' 
ten             DW      10      ; used as multiplier/divider by SCAN_NUM & PRINT_NUM_UNS.
make_minus      DB      ?       ; used as a flag.  
start: ; get first number:
mov dx, offset msg1
mov ah, 9
int 21h
call    scan_num   ; factorial of 0 = 1:
mov     ax, 1
cmp     cx, 0
je      print_result ;mov     bx, cx  ; move the number to bx: ; cx will be a counter:
mov     ax, 1
mov     bx, 1
calc_it:
mul     bx
cmp     dx, 0
jne     overflow
inc     bx
loop    calc_it
mov fact, ax
print_result:  ; print result in ax:
mov dx, offset msg2
mov ah, 9
int 21h
mov     ax, fact
call    print_num_uns
jmp     exit
 overflow:
mov dx, offset msg3
mov ah, 9
int 21h
jmp     start
 exit:  ; wait for any key press:
mov ah, 0
int 16h
; gets the multi-digit SIGNED number from the keyboard,; and stores the result in CX register:
SCAN_NUM        PROC    NEAR
        PUSH    DX
        PUSH    AX
        PUSH    SI
        MOV     CX, 0         ; reset flag:
        MOV     CS:make_minus, 0
next_digit:         ; get char from keyboard into AL:
        MOV     AH, 00h
        INT     16h
       call  print_char 
        CMP     AL, '-'    ; check for MINUS:
        JE      set_minus
        CMP     AL, 0Dh  ; check for ENTER key: ; carriage return?
        JNE     not_cr
        JMP     stop_input
not_cr:
        CMP     AL, 8                   ; 'BACKSPACE' pressed?
        JNE     backspace_checked
        MOV     DX, 0                   ; remove last digit by
        MOV     AX, CX                  ; division:
        DIV     CS:ten                  ; AX = DX:AX / 10 (DX-rem).
        MOV     CX, AX
        mov al,' '
        call  print_char ; PUTC    ' '                     ; clear positio          ; backspace again.
        JMP     next_digit
backspace_checked:             ; allow only digits:
        CMP     AL, '0'
        JAE     ok_AE_0
        JMP     remove_not_digit
ok_AE_0:        
        CMP     AL, '9'
        JBE     ok_digit
remove_not_digit:       
       mov al,' '
       call  print_char ; PUTC    ' '     ; clear last entered not digit.
       JMP     next_digit ; wait for next input.       
ok_digit:         ; multiply CX by 10 (first time the result is zero)
        PUSH    AX
        MOV     AX, CX
        MUL     CS:ten                  ; DX:AX = AX*10
        MOV     CX, AX
        POP     AX          ; check if the number is too big        ; (result should be 16 bits)
        CMP     DX, 0
        JNE     too_big         ; convert from ASCII code:
        SUB     AL, 30h         ; add AL to CX:
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
        mov al,' '
        call  print_char  ; mov ah,0eh
        JMP     next_digit ; wait for Enter/Backspace.
stop_input:       ; check flag:
        CMP     CS:make_minus, 0
        JE      not_minus
        NEG     CX
not_minus:
        POP     SI
        POP     AX
        POP     DX
        RET
SCAN_NUM        ENDP
; this procedure prints out an unsigned     ; number in AX (not just a single digit)   ; allowed values are from 0 to 65535 (FFFF)
PRINT_NUM_UNS   PROC    NEAR
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX
        MOV     CX, 1  ; flag to prevent printing zeros before number:
        MOV     BX, 10000   ; (result of "/ 10000" is always less or equal to 9). ; 2710h - divider.
        CMP     AX, 0   ; AX is zero?
        JZ      print_zero
begin_print:
        CMP     BX,0  ; check divider (if zero go to end_print):
        JZ      end_print
        CMP     CX, 0  ; avoid printing zeros before number:
        JE      calc
        CMP     AX, BX      ; if AX<BX then result of DIV will be zero:
        JB      skip
calc:
        MOV     CX, 0   ; set flag.
        MOV     DX, 0
        DIV     BX      ; AX = DX:AX / BX   (DX=remainder)    ; print last digit        ; AH is always ZERO, so it's ignored
        ADD     AL, 30h    ; convert to ASCII code.
        call  print_char 
        MOV     AX, DX  ; get remainder from last div.
skip:         ; calculate BX=BX/10
        PUSH    AX
        MOV     DX, 0
        MOV     AX, BX
        DIV     CS:ten  ; AX = DX:AX / 10   (DX=remainder).
        MOV     BX, AX
        POP     AX
        JMP     begin_print
print_zero:
       mov al,'0'
       call  print_char 
end_print:
        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET
PRINT_NUM_UNS   ENDP 
print_char   proc near
    MOV     AH, 0Eh  ; and print char :
    INT     10h  
    ret
print_char endp    