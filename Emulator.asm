; =========================================================
;   Project 3 : Letter Recall Game  (Random Edition)
;   University of Alexandria - Faculty of Engineering
;   Division of Communications & Electronics
;   Subject  : Microprocessors & Interfacing  (Spring 2026)
;   Lecturer : Dr. Nayera Sadek
; =========================================================
;   Platform : EMU8086 emulator  /  MTS-86C Lab Kit
;   Assembler: MASM / EMU8086 built-in assembler
; ---------------------------------------------------------
;   Game Rules:
;     - Level 1 : 3 random letters shown then hidden
;     - Level 2 : 5 random letters shown then hidden
;     - Level 3 : 7 random letters shown then hidden
;   Player must recall and re-type the exact sequence.
;   Retry option given after a wrong answer.
;   Letters are randomly generated each game using BIOS timer.
; ---------------------------------------------------------
;   Difficulty modes (chosen by player before game starts):
;     E - Easy   : letters visible ~5 seconds  (delay_outer = 05H)
;     M - Medium : letters visible ~3 seconds  (delay_outer = 03H)
;     H - Hard   : letters visible ~1.5 seconds(delay_outer = 01H)
; =========================================================
;
;   *** MTS-86C KIT NOTES ***
;   1. INT 10H (screen clear) is NOT available on the kit.
;      Replace CLR_SCR body with 25x newline prints.
;   2. INT 1AH (BIOS timer) used for random seed.
;      If unavailable use INT 21H/2CH instead.
;   3. DELAY_FACTOR EQU below is for kit speed scaling only.
;      The memorise duration is now controlled by delay_outer.
; =========================================================

DELAY_FACTOR  EQU  01H   ; 01H = EMU8086,  08H ~ 10 MHz kit

; =========================================================
.MODEL SMALL
.STACK 200H

.DATA

; ---------- Messages ----------
msg_title     DB 13,10
              DB ' +==============================+',13,10
              DB ' |     LETTER  RECALL  GAME     |',13,10
              DB ' +==============================+',13,10
              DB '  Memorize the letters shown,',13,10
              DB '  then type them back!',13,10,'$'

msg_diff      DB 13,10
              DB ' Select difficulty:',13,10
              DB '   E  -  Easy    (~5 seconds)',13,10
              DB '   M  -  Medium  (~3 seconds)',13,10
              DB '   H  -  Hard    (~1.5 seconds)',13,10
              DB 13,10
              DB ' Your choice: ','$'

msg_diff_easy DB 13,10,' >> EASY mode selected <<',13,10,'$'
msg_diff_med  DB 13,10,' >> MEDIUM mode selected <<',13,10,'$'
msg_diff_hard DB 13,10,' >> HARD mode selected <<',13,10,'$'
msg_diff_err  DB 13,10,' Invalid key! Press E, M or H: ','$'

msg_press     DB 13,10,' Press any key to start...','$'

msg_level     DB 13,10,13,10
              DB ' >>>  LEVEL ','$'

msg_lvl_end   DB '  <<<',13,10,'$'

msg_memo      DB 13,10,' Memorize: ','$'

msg_type      DB 13,10,13,10
              DB ' Now type the letters: ','$'

msg_correct   DB 13,10
              DB ' +---------------------------+',13,10
              DB ' |  CORRECT!  Great memory!  |',13,10
              DB ' +---------------------------+',13,10,'$'

msg_wrong     DB 13,10,' WRONG!  The answer was:  ','$'

msg_retry     DB 13,10,' Try again?  Y / N : ','$'

msg_win       DB 13,10
              DB ' +=================================+',13,10
              DB ' |  YOU WIN!  CONGRATULATIONS!    |',13,10
              DB ' +=================================+',13,10,'$'

msg_over      DB 13,10,' Game Over. Better luck next time!',13,10,'$'

msg_nl        DB 13,10,'$'

; ---------- Random Generation ----------
rnd_seed      DB 0          ; rolling seed - updated after every letter

; ---------- Difficulty ----------
; delay_outer controls how many outer loops DELAY_LONG runs.
; More loops = longer visible time for memorising.
;   Easy   : 05H  (~5 s in EMU8086)
;   Medium : 03H  (~3 s)
;   Hard   : 01H  (~1.5 s)
delay_outer   DB 03H        ; default = Medium (overwritten by CHOOSE_DIFF)

; ---------- Working Variables ----------
cur_lvl       DB 0          ; current level number (1, 2, 3)
seq_count     DB 0          ; number of letters in current level

seq_buf       DB 8 DUP(?)   ; generated sequence for current level
user_buf      DB 8 DUP(?)   ; player input buffer  (max 7 + spare)
read_ctr      DB 0          ; separate counter for READ_LOOP (keeps CX safe)

; =========================================================
.CODE

; =========================================================
; MAIN
; =========================================================
MAIN PROC
    MOV  AX, @DATA
    MOV  DS, AX

    ; --- Seed the RNG once at startup using BIOS ticks ---
    MOV  AH, 00H
    INT  1AH                  ; CX:DX = ticks since midnight
    MOV  AL, DL
    XOR  AL, DH
    XOR  AL, CL
    MOV  rnd_seed, AL

    CALL CLR_SCR

    ; ---- Welcome screen ----
    LEA  DX, msg_title
    MOV  AH, 09H
    INT  21H

    ; ---- Difficulty selection ----
    CALL CHOOSE_DIFF

    ; ---- Wait for any key ----
    LEA  DX, msg_press
    MOV  AH, 09H
    INT  21H
    MOV  AH, 08H
    INT  21H

    ; ---- Level 1 :  3 letters ----
    MOV  cur_lvl,   1
    MOV  seq_count, 3
    CALL DO_LEVEL
    CMP  AX, 0
    JE   SHOW_GAMEOVER

    ; ---- Level 2 :  5 letters ----
    MOV  cur_lvl,   2
    MOV  seq_count, 5
    CALL DO_LEVEL
    CMP  AX, 0
    JE   SHOW_GAMEOVER

    ; ---- Level 3 :  7 letters ----
    MOV  cur_lvl,   3
    MOV  seq_count, 7
    CALL DO_LEVEL
    CMP  AX, 0
    JE   SHOW_GAMEOVER

    ; ---- All levels passed ----
    LEA  DX, msg_win
    MOV  AH, 09H
    INT  21H
    JMP  EXIT_MAIN

SHOW_GAMEOVER:
    LEA  DX, msg_over
    MOV  AH, 09H
    INT  21H

EXIT_MAIN:
    MOV  AH, 4CH
    INT  21H
MAIN ENDP

; =========================================================
; CHOOSE_DIFF
;   Shows difficulty menu and sets delay_outer accordingly.
;   Keeps looping until the player presses E, M, or H
;   (accepts both uppercase and lowercase).
;
;   Difficulty -> delay_outer mapping:
;     Easy   (E/e) -> 05H
;     Medium (M/m) -> 03H
;     Hard   (H/h) -> 01H
; =========================================================
CHOOSE_DIFF PROC
    ; Print difficulty menu
    LEA  DX, msg_diff
    MOV  AH, 09H
    INT  21H

DIFF_READ:
    MOV  AH, 08H              ; read key, no echo
    INT  21H

    ; echo the pressed key so player sees it
    MOV  DL, AL
    MOV  AH, 02H
    INT  21H

    ; force uppercase for comparison
    OR   AL, 20H              ; lowercase
    CMP  AL, 'e'
    JE   DIFF_EASY
    CMP  AL, 'm'
    JE   DIFF_MED
    CMP  AL, 'h'
    JE   DIFF_HARD

    ; invalid key - show error and ask again
    LEA  DX, msg_diff_err
    MOV  AH, 09H
    INT  21H
    JMP  DIFF_READ

DIFF_EASY:
    MOV  delay_outer, 05H
    LEA  DX, msg_diff_easy
    MOV  AH, 09H
    INT  21H
    RET

DIFF_MED:
    MOV  delay_outer, 03H
    LEA  DX, msg_diff_med
    MOV  AH, 09H
    INT  21H
    RET

DIFF_HARD:
    MOV  delay_outer, 01H
    LEA  DX, msg_diff_hard
    MOV  AH, 09H
    INT  21H
    RET

CHOOSE_DIFF ENDP

; =========================================================
; GET_RANDOM_LETTER
;   Generates a single random uppercase letter A-Z.
;
;   Method:
;     1. Read BIOS timer ticks via INT 1AH (CX:DX).
;     2. XOR bytes together with rnd_seed.
;     3. LCG scramble: AL = (109*AL + 11) XOR DL
;     4. DIV 26 -> remainder 0..25
;     5. ADD 'A' -> letter A..Z
;     6. Update rnd_seed.
;
;   Output : AL = random letter ('A'..'Z')
;
;   *** KIT NOTE ***
;   If INT 1AH unavailable, replace INT 1AH block with:
;       MOV  AH, 2CH
;       INT  21H       ; DH=seconds, DL=hundredths
; =========================================================
GET_RANDOM_LETTER PROC
    PUSH BX
    PUSH CX
    PUSH DX

    MOV  AH, 00H
    INT  1AH                  ; CX = high word, DX = low word

    MOV  AL, DL
    XOR  AL, DH
    XOR  AL, CL
    XOR  AL, rnd_seed

    MOV  BL, AL
    MOV  AL, 6DH              ; 109 decimal
    MUL  BL                   ; AX = 109 * AL
    ADD  AL, 0BH              ; + 11
    XOR  AL, DL

    XOR  AH, AH
    MOV  BL, 26
    DIV  BL                   ; AH = remainder (0..25)
    MOV  AL, AH

    ADD  AL, 'A'
    MOV  rnd_seed, AL

    POP  DX
    POP  CX
    POP  BX
    RET
GET_RANDOM_LETTER ENDP

; =========================================================
; FILL_SEQ
;   Fills seq_buf with seq_count random uppercase letters.
; =========================================================
FILL_SEQ PROC
    PUSH AX
    PUSH CX
    PUSH DI

    LEA  DI, seq_buf
    XOR  CH, CH
    MOV  CL, seq_count

FILL_LOOP:
    CALL GET_RANDOM_LETTER
    MOV  [DI], AL
    INC  DI
    LOOP FILL_LOOP

    POP  DI
    POP  CX
    POP  AX
    RET
FILL_SEQ ENDP

; =========================================================
; DO_LEVEL
;   Runs one complete level: generate -> show -> hide ->
;   input -> check, with retry support.
;
;   Input  : seq_count = letters for this level
;            cur_lvl   = level number (1, 2, or 3)
;   Output : AX = 1  (level passed)
;            AX = 0  (player chose N on retry)
; =========================================================
DO_LEVEL PROC

    CALL FILL_SEQ             ; generate sequence once per level

RETRY_LVL:
    CALL CLR_SCR

    ; ---- Print ">>> LEVEL X <<<" ----
    LEA  DX, msg_level
    MOV  AH, 09H
    INT  21H

    MOV  DL, cur_lvl
    ADD  DL, '0'
    MOV  AH, 02H
    INT  21H

    LEA  DX, msg_lvl_end
    MOV  AH, 09H
    INT  21H

    ; ---- Print "Memorize: " ----
    LEA  DX, msg_memo
    MOV  AH, 09H
    INT  21H

    ; ---- Display the generated letters ----
    LEA  SI, seq_buf
    XOR  CH, CH
    MOV  CL, seq_count

SHOW_LOOP:
    MOV  DL, [SI]
    MOV  AH, 02H
    INT  21H
    MOV  DL, ' '
    INT  21H
    INC  SI
    LOOP SHOW_LOOP

    ; ---- Keep visible for difficulty-controlled duration ----
    CALL DELAY_LONG

    ; ---- Hide by clearing the screen ----
    CALL CLR_SCR

    ; ---- Prompt player to type ----
    LEA  DX, msg_type
    MOV  AH, 09H
    INT  21H

    ; ---- Read exactly seq_count characters ----
    ; Uses read_ctr (memory) not CX -- INT 21h/02h can
    ; corrupt CX in EMU8086, breaking a LOOP counter.
    LEA  DI, user_buf
    MOV  AL, seq_count
    MOV  read_ctr, AL

READ_LOOP:
    MOV  AH, 08H              ; read char, no auto echo
    INT  21H

    CMP  AL, 'a'
    JB   STORE_CHAR
    CMP  AL, 'z'
    JA   STORE_CHAR
    SUB  AL, 20H              ; lowercase -> uppercase

STORE_CHAR:
    MOV  [DI], AL
    INC  DI

    MOV  DL, AL
    MOV  AH, 02H
    INT  21H
    MOV  DL, ' '
    INT  21H

    DEC  read_ctr
    JNZ  READ_LOOP

    ; ---- Compare input with generated sequence ----
    LEA  SI, seq_buf
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

    ; ---- Correct! ----
    LEA  DX, msg_correct
    MOV  AH, 09H
    INT  21H
    CALL DELAY_SHORT
    MOV  AX, 1
    RET

WRONG_ANSWER:
    LEA  DX, msg_wrong
    MOV  AH, 09H
    INT  21H

    LEA  SI, seq_buf
    XOR  CH, CH
    MOV  CL, seq_count

PRINT_ANSWER:
    MOV  DL, [SI]
    MOV  AH, 02H
    INT  21H
    MOV  DL, ' '
    INT  21H
    INC  SI
    LOOP PRINT_ANSWER

    LEA  DX, msg_retry
    MOV  AH, 09H
    INT  21H

    MOV  AH, 08H
    INT  21H

    OR   AL, 20H
    CMP  AL, 'y'
    JE   RETRY_LVL

    MOV  AX, 0
    RET

DO_LEVEL ENDP

; =========================================================
; CLR_SCR
;   Clears screen via BIOS INT 10H, repositions cursor (0,0).
;
;   *** KIT NOTE ***
;   If INT 10H unavailable, replace body with:
;       MOV  CX, 25
;   KIT_NL:
;       LEA  DX, msg_nl
;       MOV  AH, 09H
;       INT  21H
;       LOOP KIT_NL
;       RET
; =========================================================
CLR_SCR PROC
    MOV  AX, 0600H
    MOV  BH, 07H
    XOR  CX, CX
    MOV  DX, 184FH
    INT  10H

    MOV  AH, 02H
    XOR  BX, BX
    XOR  DX, DX
    INT  10H
    RET
CLR_SCR ENDP

; =========================================================
; DELAY_LONG
;   Duration is controlled by delay_outer (set by CHOOSE_DIFF).
;   Outer loop count = delay_outer * DELAY_FACTOR
;   Inner loop count = 00FFH (255) each time.
;
;   Approximate visible times in EMU8086:
;     delay_outer = 05H -> ~5 seconds  (Easy)
;     delay_outer = 03H -> ~3 seconds  (Medium)
;     delay_outer = 01H -> ~1.5 seconds(Hard)
; =========================================================
DELAY_LONG PROC
    PUSH AX
    PUSH CX
    PUSH BX

    ; BX = delay_outer * DELAY_FACTOR
    XOR  AH, AH
    MOV  AL, delay_outer
    MOV  BL, DELAY_FACTOR
    MUL  BL                   ; AX = delay_outer * DELAY_FACTOR
    MOV  BX, AX               ; BX = outer loop count

DL_OUTER:
    MOV  CX, 00FFH
DL_INNER:
    LOOP DL_INNER
    DEC  BX
    JNZ  DL_OUTER

    POP  BX
    POP  CX
    POP  AX
    RET
DELAY_LONG ENDP

; =========================================================
; DELAY_SHORT  (~0.5 second in EMU8086, all difficulties)
; =========================================================
DELAY_SHORT PROC
    PUSH CX
    PUSH BX
    MOV  BX, 08H * DELAY_FACTOR
DSH_OUTER:
    MOV  CX, 00FFH
DSH_INNER:
    LOOP DSH_INNER
    DEC  BX
    JNZ  DSH_OUTER
    POP  BX
    POP  CX
    RET
DELAY_SHORT ENDP

END MAIN
; =========================================================
; END OF FILE
; =========================================================
