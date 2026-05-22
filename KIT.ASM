; =========================================================
;   Project 3 : Letter Recall Game (FULL BARE-METAL FIXED)
;   Hardware  : MTS-86C Kit (LCD & Keypad)
; =========================================================

DELAY_FACTOR  EQU 08H

; --- Hardware Port Definitions ---
LCD_CMD_PORT  EQU 0FFC1H
LCD_STAT_PORT EQU 0FFC3H
LCD_DATA_PORT EQU 0FFC5H
KBD_CMD_PORT  EQU 0FFEAH
KBD_DATA_PORT EQU 0FFE8H

; =========================================================
.MODEL TINY
.CODE
ORG 0000H              

START:
    JMP MAIN           

; ---------- Data & Shortened LCD Messages ----------
msg_title    DB 'LETTER RECALL   $'
msg_press    DB 'Press any key...$'
msg_level    DB 'LEVEL $'
msg_memo     DB 'Memorize:       $'
msg_type     DB 'Type sequence:  $'
msg_correct  DB 'CORRECT!        $'
msg_wrong    DB 'WRONG! Was:     $'
msg_retry    DB 'Retry?(1=Y 0=N) $'
msg_win      DB 'YOU WIN!        $'
msg_over     DB 'GAME OVER.      $'

; ---------- Hexadecimal Level Sequences ----------
lvl1_data    DB 3,  'A','3','F'
lvl2_data    DB 5,  'B','7','1','C','9'
lvl3_data    DB 7,  'E','0','D','5','2','8','4'

cur_lvl      DB 0          
seq_count    DB 0          
seq_base     DW 0          
user_buf     DB 8 DUP(?)   

; --- Scan Code to ASCII Lookup Table ---
SCAN_TABLE   DB '0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'

; =========================================================
; MAIN LOGIC
; =========================================================
MAIN PROC
    MOV  AX, CS
    MOV  DS, AX
    MOV  ES, AX

    CALL LCD_INIT           

    ; --- Welcome Screen ---
    CALL LCD_CLEAR
    LEA  SI, msg_title
    CALL LCD_PRINT
    CALL LCD_LINE2          
    LEA  SI, msg_press
    CALL LCD_PRINT

    CALL WAIT_KEY           

    ; --- Run Levels ---
    MOV  cur_lvl, 1
    LEA  SI, lvl1_data
    CALL DO_LEVEL
    CMP  AX, 0
    JE   SHOW_GAMEOVER

    MOV  cur_lvl, 2
    LEA  SI, lvl2_data
    CALL DO_LEVEL
    CMP  AX, 0
    JE   SHOW_GAMEOVER

    MOV  cur_lvl, 3
    LEA  SI, lvl3_data
    CALL DO_LEVEL
    CMP  AX, 0
    JE   SHOW_GAMEOVER

    ; --- Win Screen ---
    CALL LCD_CLEAR
    LEA  SI, msg_win
    CALL LCD_PRINT
    JMP  EXIT_MAIN

SHOW_GAMEOVER:
    CALL LCD_CLEAR
    LEA  SI, msg_over
    CALL LCD_PRINT

EXIT_MAIN:
    HLT
MAIN ENDP

; =========================================================
; LEVEL LOGIC
; =========================================================
DO_LEVEL PROC
    MOV  seq_base, SI
    MOV  AL, [SI]
    MOV  seq_count, AL

RETRY_LVL:
    CALL LCD_CLEAR
    LEA  SI, msg_level
    CALL LCD_PRINT

    MOV  AL, cur_lvl
    ADD  AL, '0'
    CALL WRITE_DATA         

    CALL LCD_LINE2
    LEA  SI, msg_memo
    CALL LCD_PRINT
    CALL DELAY_LONG

    ; --- Show Sequence ---
    CALL LCD_CLEAR
    MOV  SI, seq_base
    INC  SI                 
    XOR  CH, CH
    MOV  CL, seq_count      
SHOW_LOOP:
    MOV  AL, [SI]
    CALL WRITE_DATA
    MOV  AL, ' '            
    CALL WRITE_DATA
    INC  SI
    LOOP SHOW_LOOP

    CALL DELAY_LONG
    CALL DELAY_LONG

    ; --- Prompt User Input ---
    CALL LCD_CLEAR
    LEA  SI, msg_type
    CALL LCD_PRINT
    CALL LCD_LINE2

    LEA  DI, user_buf
    XOR  CH, CH
    MOV  CL, seq_count
READ_LOOP:
    CALL WAIT_KEY           
    MOV  [DI], AL           
    CALL WRITE_DATA         
    MOV  AL, ' '
    CALL WRITE_DATA
    INC  DI                 
    LOOP READ_LOOP

    ; --- Check Answer ---
    MOV  SI, seq_base
    INC  SI                 
    LEA  DI, user_buf
    XOR  CH, CH
    MOV  CL, seq_count
CMP_LOOP:
    MOV  AL, [SI]           
    CMP  AL, [DI]           
    JNE  WRONG_ANSWER
    INC  SI
    INC  DI
    LOOP CMP_LOOP

    CALL LCD_CLEAR
    LEA  SI, msg_correct
    CALL LCD_PRINT
    CALL DELAY_LONG
    MOV  AX, 1
    RET

WRONG_ANSWER:
    CALL LCD_CLEAR
    LEA  SI, msg_wrong
    CALL LCD_PRINT
    CALL LCD_LINE2

    MOV  SI, seq_base
    INC  SI
    XOR  CH, CH
    MOV  CL, seq_count
PRINT_ANSWER:
    MOV  AL, [SI]
    CALL WRITE_DATA
    MOV  AL, ' '
    CALL WRITE_DATA
    INC  SI
    LOOP PRINT_ANSWER
    
    CALL DELAY_LONG
    CALL DELAY_LONG

    ; --- Retry Prompt ---
    CALL LCD_CLEAR
    LEA  SI, msg_retry
    CALL LCD_PRINT

    CALL WAIT_KEY
    CMP  AL, '1'            
    JNE  NO_RETRY           
    JMP  RETRY_LVL          

NO_RETRY:
    MOV  AX, 0
    RET
DO_LEVEL ENDP


; =========================================================
; RAW HARDWARE DRIVERS (DX REGISTER FIX APPLIED)
; =========================================================

WAIT_KEY PROC
    PUSH BX
    PUSH DX
WK_POLL:
    MOV  DX, KBD_CMD_PORT   ; 16-bit port address to DX
    IN   AL, DX             ; Read from DX port
    AND  AL, 07H            
    JZ   WK_POLL            

    MOV  DX, KBD_DATA_PORT
    IN   AL, DX             
    AND  AL, 0FH            
    
    LEA  BX, SCAN_TABLE
    XLAT                    
    
    POP  DX
    POP  BX
    RET
WAIT_KEY ENDP

LCD_INIT PROC
    MOV  AL, 38H            
    CALL WRITE_CMD
    MOV  AL, 0CH            
    CALL WRITE_CMD
    CALL LCD_CLEAR
    RET
LCD_INIT ENDP

LCD_CLEAR PROC
    MOV  AL, 01H
    CALL WRITE_CMD
    RET
LCD_CLEAR ENDP

LCD_LINE2 PROC
    MOV  AL, 0C0H
    CALL WRITE_CMD
    RET
LCD_LINE2 ENDP

LCD_PRINT PROC
LP_LOOP:
    MOV  AL, [SI]
    CMP  AL, '$'
    JE   LP_DONE
    CALL WRITE_DATA
    INC  SI
    JMP  LP_LOOP
LP_DONE:
    RET
LCD_PRINT ENDP

WRITE_CMD PROC
    PUSH AX
    PUSH DX
WC_BUSY:
    MOV  DX, LCD_STAT_PORT
    IN   AL, DX             
    TEST AL, 80H            
    JNZ  WC_BUSY            
    
    POP  DX
    POP  AX                 ; Restore command to AL
    
    PUSH DX
    MOV  DX, LCD_CMD_PORT
    OUT  DX, AL             ; Send AL to DX port
    POP  DX
    RET
WRITE_CMD ENDP

WRITE_DATA PROC
    PUSH AX
    PUSH DX
WD_BUSY:
    MOV  DX, LCD_STAT_PORT
    IN   AL, DX             
    TEST AL, 80H            
    JNZ  WD_BUSY
    
    POP  DX
    POP  AX                 ; Restore character to AL
    
    PUSH DX
    MOV  DX, LCD_DATA_PORT
    OUT  DX, AL             ; Send AL to DX port
    POP  DX
    RET
WRITE_DATA ENDP

; =========================================================
; DELAYS
; =========================================================
DELAY_LONG PROC
    PUSH CX
    PUSH BX
    MOV  BX, 0180H                
DL_OUTER:
    MOV  CX, 00FFH               
DL_INNER:
    LOOP DL_INNER
    DEC  BX
    JNZ  DL_OUTER
    POP  BX
    POP  CX
    RET
DELAY_LONG ENDP

END START