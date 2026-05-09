;==============================================================================
; primitives.s - 65816 Forth Kernel Primitives
;
; All words are in ROM. Dictionary entries are linked in order.
; The HEADER macro creates the link field, flags, and name.
; The CODEPTR macro emits the code field (ITC code pointer).
;
; Pattern for each primitive word:
;
;   HEADER  "NAME", NAME_ENTRY, NAME_CFA, flags, PREV_ENTRY
;   CODEPTR NAME_CODE
;   .proc   NAME_CODE
;           ... machine code ...
;           NEXT
;   .endproc
;
; All code assumes:
;   Native mode, A=16-bit, X=16-bit, Y=16-bit
;   unless explicitly switched with SEP/REP + .a8/.a16 hints
;==============================================================================

        .p816
        .smart off

        .include "macros.inc"
        .include "dictionary.inc"
        .include "constants.inc"
        .include "hal.inc"

; Import zero page variables from forth.s
; Using .importzp ensures ca65 uses direct page addressing
        .importzp       W
        .importzp       UP
        .importzp       RSP_INIT
        .importzp       SCRATCH0
        .importzp       SCRATCH1
        .importzp       TMPA
        .importzp       TMPB

        .segment "CODE"

;==============================================================================
; SECTION 1: STACK PRIMITIVES
;==============================================================================

;------------------------------------------------------------------------------
; PSP_UNDERFLOW_HANDLER - called by NEXT if underflow detected.
;------------------------------------------------------------------------------
        PUBLIC  PSP_UNDERFLOW_HANDLER
        .a16
        .i16
                LDA     #underflow_msg
                JSR     hal_cputs
                JMP     ABORT_CODE

underflow_msg:
                .byte   "Stack underflow", C_RETURN, L_FEED, $00
        ENDPUBLIC

;------------------------------------------------------------------------------
; DUP ( a -- a a )
;------------------------------------------------------------------------------
        HEADER  "DUP", DUP_ENTRY, DUP_CFA, 0, 0
        CODEPTR DUP_CODE
        PUBLIC  DUP_CODE
        .a16
        .i16
                PEEK                    ; Load TOS
                PUSH                    ; Push copy
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; ?DUP  ( x -- 0 | x x )
; https://forth-standard.org/standard/core/qDUP
;------------------------------------------------------------------------------
        HEADER  "?DUP", QDUP_ENTRY, QDUP_CFA, 0, DUP_ENTRY
        CODEPTR DOCOL
        .word   DUP_CFA
        .word   ZBRANCH_CFA
        .word   QDUP_DONE
        .word   DUP_CFA
QDUP_DONE:
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; DROP ( a -- )
;------------------------------------------------------------------------------
        HEADER  "DROP", DROP_ENTRY, DROP_CFA, 0, QDUP_ENTRY
        CODEPTR DROP_CODE
        PUBLIC  DROP_CODE
        .a16
        .i16
                DROP
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; SWAP ( a b -- b a )
;------------------------------------------------------------------------------
        HEADER  "SWAP", SWAP_ENTRY, SWAP_CFA, 0, DROP_ENTRY
        CODEPTR SWAP_CODE
        PUBLIC  SWAP_CODE
        .a16
        .i16
                PEEK                    ; b (TOS)
                STA     SCRATCH0
                LDA     2,X             ; a (NOS)
                PUT                     ; TOS = a
                LDA     SCRATCH0        ; b
                STA     2,X             ; NOS = b
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; OVER ( a b -- a b a )
;------------------------------------------------------------------------------
        HEADER  "OVER", OVER_ENTRY, OVER_CFA, 0, SWAP_ENTRY
        CODEPTR OVER_CODE
        PUBLIC  OVER_CODE
        .a16
        .i16
                LDA     2,X             ; a (NOS)
                PUSH                    ; Push copy of a
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; ROT ( a b c -- b c a )
;------------------------------------------------------------------------------
        HEADER  "ROT", ROT_ENTRY, ROT_CFA, 0, OVER_ENTRY
        CODEPTR ROT_CODE
        PUBLIC  ROT_CODE
        .a16
        .i16
                LDA     4,X             ; a (bottom)
                STA     SCRATCH0
                LDA     2,X             ; b
                STA     4,X             ; bottom slot = b
                LDA     0,X             ; c (TOS)
                STA     2,X             ; middle slot = c
                LDA     SCRATCH0        ; a
                STA     0,X             ; TOS = a
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; NIP ( a b -- b )
;------------------------------------------------------------------------------
        HEADER  "NIP", NIP_ENTRY, NIP_CFA, 0, ROT_ENTRY
        CODEPTR NIP_CODE
        PUBLIC  NIP_CODE
        .a16
        .i16
                POP                     ; b (TOS)
                PUT                     ; Overwrite a with b
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; TUCK ( a b -- b a b )
;------------------------------------------------------------------------------
        HEADER  "TUCK", TUCK_ENTRY, TUCK_CFA, 0, NIP_ENTRY
        CODEPTR TUCK_CODE
        PUBLIC  TUCK_CODE
        .a16
        .i16
                DEX
                DEX
                LDA     2,X             ; b
                STA     0,X             ; TOS = b
                LDA     4,X             ; a
                STA     2,X             ; NOS = a
                LDA     0,X             ; b
                STA     4,X             ; Slot below a = b
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; 2DROP ( a b -- )
;------------------------------------------------------------------------------
        HEADER  "2DROP", TWODROP_ENTRY, TWODROP_CFA, 0, TUCK_ENTRY
        CODEPTR TWODROP_CODE
        PUBLIC  TWODROP_CODE
        .a16
        .i16
                DROP
                DROP
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; 2DUP ( a b -- a b a b )
;------------------------------------------------------------------------------
        HEADER  "2DUP", TWODUP_ENTRY, TWODUP_CFA, 0, TWODROP_ENTRY
        CODEPTR TWODUP_CODE
        PUBLIC  TWODUP_CODE
        .a16
        .i16
                DEX
                DEX
                DEX
                DEX
                LDA     6,X             ; a
                STA     2,X             ; Push a
                LDA     4,X             ; b
                STA     0,X             ; Push b
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; 2SWAP ( a b c d -- c d a b )
;------------------------------------------------------------------------------
        HEADER  "2SWAP", TWOSWAP_ENTRY, TWOSWAP_CFA, 0, TWODUP_ENTRY
        CODEPTR TWOSWAP_CODE
        PUBLIC  TWOSWAP_CODE
        .a16
        .i16
                LDA     0,X             ; d
                STA     SCRATCH0
                LDA     2,X             ; c
                STA     SCRATCH1
                LDA     4,X             ; b
                STA     0,X
                LDA     6,X             ; a
                STA     2,X
                LDA     SCRATCH0        ; d
                STA     4,X
                LDA     SCRATCH1        ; c
                STA     6,X
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; 2OVER ( a b c d -- a b c d a b )
;------------------------------------------------------------------------------
        HEADER  "2OVER", TWOOVER_ENTRY, TWOOVER_CFA, 0, TWOSWAP_ENTRY
        CODEPTR TWOOVER_CODE
        PUBLIC  TWOOVER_CODE
        .a16
        .i16
                DEX
                DEX
                DEX
                DEX
                LDA     10,X            ; a
                STA     2,X             ; Push a (NOS)
                LDA     8,X             ; b
                STA     0,X             ; Push b
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; 2ROT ( d1_lo d1_hi d2_lo d2_hi d3_lo d3_hi -- d2_lo d2_hi d3_lo d3_hi d1_lo d1_hi )
;------------------------------------------------------------------------------
        HEADER  "2ROT", TWOROT_ENTRY, TWOROT_CFA, 0, TWOOVER_ENTRY
        CODEPTR DOCOL
        .word   LIT_CFA
        .word   5
        .word   ROLL_CFA               ; ( d1_hi d2_lo d2_hi d3_lo d3_hi d1_lo )
        .word   LIT_CFA
        .word   5
        .word   ROLL_CFA               ; ( d2_lo d2_hi d3_lo d3_hi d1_lo d1_hi )
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; DEPTH ( -- n ) number of items on parameter stack
;------------------------------------------------------------------------------
        HEADER  "DEPTH", DEPTH_ENTRY, DEPTH_CFA, 0, TWOROT_ENTRY
        CODEPTR DEPTH_CODE
        PUBLIC  DEPTH_CODE
        .a16
        .i16
                JSR     calc_depth
                PUSH
                NEXT

calc_depth:     TXA
                EOR     #$FFFF          ; Two's complement
                INC     A
                CLC
                ADC     #PSP_INIT       ; PSP_INIT - result / 2
                CMP     #$8000          ; if bit 15 is set, carry = 1
                ROR     A               ; Divide by 2 (cells)
                RTS
	ENDPUBLIC

;------------------------------------------------------------------------------
; PICK ( xu...x1 x0 u -- xu...x1 x0 xu )
;------------------------------------------------------------------------------
        HEADER  "PICK", PICK_ENTRY, PICK_CFA, 0, DEPTH_ENTRY
        CODEPTR PICK_CODE
        PUBLIC  PICK_CODE
        .a16
        .i16
                STX     SCRATCH0        ; SCRATCH0 = stack base (PSP)
                LDA     0,X             ; u
                INC     A               ; u+1 (skip u itself)
                ASL     A               ; * 2 (cell size)
                CLC
                ADC     SCRATCH0        ; X + (u+1)*2
                STA     SCRATCH0
                LDA     (SCRATCH0)      ; Fetch xu
                STA     0,X             ; Replace u with xu
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; ROLL ( xu xu-1 ... x0 u -- xu-1 ... x0 xu )
; Remove u. Rotate u+1 items on the top of the stack. An ambiguous condition
; exists if there are less than u+2 items on the stack before ROLL is executed.
;------------------------------------------------------------------------------
        HEADER  "ROLL", ROLL_ENTRY, ROLL_CFA, 0, PICK_ENTRY
        CODEPTR ROLL_CODE
        PUBLIC  ROLL_CODE
        .a16
        .i16
                PHY                     ; save IP

                LDA     a:0,X           ; fetch n
                INX
                INX                     ; drop n
                STA     SCRATCH0        ; save n
                CMP     #00             ; n=0, nothing to do
                BEQ     @return

                ASL     SCRATCH0        ; SCRATCH0 = n*2 (byte offset)

                ; Fetch x_n
                TXA
                CLC
                ADC     SCRATCH0
                STA     SCRATCH1        ; SCRATCH1 = addr of x_n
                LDA     (SCRATCH1)      ; fetch x_n
                PHA                     ; save on hw stack

                ; Shift x_0..x_n-1 up by one cell
@shift_loop:
                LDA     SCRATCH1
                SEC
                SBC     #CELL_SIZE
                STA     SCRATCH1        ; point to next lower item
                LDA     (SCRATCH1)      ; fetch it
                LDY     #CELL_SIZE
                STA     (SCRATCH1),Y    ; store one cell higher
                TXA
                CMP     SCRATCH1        ; reached PSP (x_0 position)?
                BNE     @shift_loop

                PLA                     ; restore x_n
                STA     a:0,X           ; store at TOS (x_0 position)

@return:        PLY                     ; restore IP
                NEXT
        ENDPUBLIC

;==============================================================================
; SECTION 2: RETURN STACK PRIMITIVES
;==============================================================================

;------------------------------------------------------------------------------
; >R ( a -- ) (R: -- a)
;------------------------------------------------------------------------------
        HEADER  ">R", TOR_ENTRY, TOR_CFA, 0, ROLL_ENTRY
        CODEPTR TOR_CODE
        PUBLIC  TOR_CODE
        .a16
        .i16
                POP                     ; Pop from parameter stack
                RPUSH                   ; Push onto return stack
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; R> ( -- a ) (R: a -- )
;------------------------------------------------------------------------------
        HEADER  "R>", RFROM_ENTRY, RFROM_CFA, 0, TOR_ENTRY
        CODEPTR RFROM_CODE
        PUBLIC  RFROM_CODE
        .a16
        .i16
                RPOP                    ; Pop from return stack
                PUSH                    ; Push onto parameter stack
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; R@ ( -- a ) (R: a -- a)
;------------------------------------------------------------------------------
        HEADER  "R@", RFETCH_ENTRY, RFETCH_CFA, 0, RFROM_ENTRY
        CODEPTR RFETCH_CODE
        PUBLIC  RFETCH_CODE
        .a16
        .i16
                ; Peek at return stack top without permanently popping.
                RPEEK                   ; Peek R@ value (A = value)
                PUSH                    ; Push copy onto parameter stack
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; 2>R ( x1 x2 -- ) R: ( -- x1 x2 ) Semantically equivalent to SWAP >R >R.
;------------------------------------------------------------------------------
        HEADER  "2>R", TWOTOR_ENTRY, TWOTOR_CFA, 0, RFETCH_ENTRY
        CODEPTR TWOTOR_CODE
        PUBLIC  TWOTOR_CODE
        .a16
        .i16
                LDA     2,X             ; x1 (NOS)
                RPUSH                   ; push x1 first
                POP                     ; x2 (TOS)
                RPUSH                   ; push x2 on top
                DROP
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; 2R> ( -- x1 x2 ) R: ( x1 x2 -- ) Semantically equivalent to R> R> SWAP.
;------------------------------------------------------------------------------
        HEADER  "2R>", TWORFROM_ENTRY, TWORFROM_CFA, 0, TWOTOR_ENTRY
        CODEPTR TWORFROM_CODE
        PUBLIC  TWORFROM_CODE
        .a16
        .i16
                DEX
                DEX
                RPOP                    ; x2 (TOS of return stack)
                PUSH                    ; x2 (TOS)
                RPOP                    ; x1
                STA     2,X             ; x1 (NOS)
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; 2R@ ( -- x1 x2 ) R: ( x1 x2 -- x1 x2 )
; Semantically equivalent to R> R> 2DUP >R >R SWAP.
;------------------------------------------------------------------------------
        HEADER  "2R@", TWORFETCH_ENTRY, TWORFETCH_CFA, 0, TWORFROM_ENTRY
        CODEPTR TWORFETCH_CODE
        PUBLIC  TWORFETCH_CODE
        .a16
        .i16
                LDA     3,S             ; x1
                PUSH                    ; x1 (future NOS)
                LDA     1,S             ; x2 (TOS of return stack)
                PUSH                    ; x2 (TOS)
                NEXT
        ENDPUBLIC

;==============================================================================
; SECTION 3: ARITHMETIC CONSTANTS AND PRIMITIVES
;==============================================================================

;------------------------------------------------------------------------------
; ZERO ( -- 0 ) pushes zero, shortcut to LIT 0.
;------------------------------------------------------------------------------
        HEADER  "ZERO", ZERO_ENTRY, ZERO_CFA, 0, TWORFETCH_ENTRY
        CODEPTR ZERO_CODE
        PUBLIC  ZERO_CODE
        .a16
        .i16
                DEX
                DEX
                STZ     0,X             ; push zero
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; MIN-INT ( -- n ) pushes lowest single precision integer
;------------------------------------------------------------------------------
        HEADER  "MIN-INT", MININT_ENTRY, MININT_CFA, 0, ZERO_ENTRY
        CODEPTR MININT_CODE
        PUBLIC  MININT_CODE
        .a16
        .i16
                LDA     #$8000
                PUSH
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; MAX-INT ( -- n ) pushes highest single precision integer
;------------------------------------------------------------------------------
        HEADER  "MAX-INT", MAXINT_ENTRY, MAXINT_CFA, 0, MININT_ENTRY
        CODEPTR MAXINT_CODE
        PUBLIC  MAXINT_CODE
        .a16
        .i16
                LDA     #$7FFF
                PUSH
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; MIN-2INT ( -- d ) pushes lowest single precision integer
;------------------------------------------------------------------------------
        HEADER  "MIN-2INT", MINTWOINT_ENTRY, MINTWOINT_CFA, 0, MAXINT_ENTRY
        CODEPTR MINTWOINT_CODE
        PUBLIC  MINTWOINT_CODE
        .a16
        .i16
                LDA     #$0000
                PUSH
                LDA     #$8000
                PUSH
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; MAX-2INT ( -- d ) pushes highest single precision integer
;------------------------------------------------------------------------------
        HEADER  "MAX-2INT", MAXTWOINT_ENTRY, MAXTWOINT_CFA, 0, MINTWOINT_ENTRY
        CODEPTR MAXTWOINT_CODE
        PUBLIC  MAXTWOINT_CODE
        .a16
        .i16
                LDA     #$FFFF
                PUSH
                LDA     #$7FFF
                PUSH
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; + ( a b -- a+b )
;------------------------------------------------------------------------------
        HEADER  "+", PLUS_ENTRY, PLUS_CFA, 0, MAXTWOINT_ENTRY
        CODEPTR PLUS_CODE
        PUBLIC  PLUS_CODE
        .a16
        .i16
                POP                     ; b
                CLC
                ADC     0,X             ; a + b
                PUT                     ; Replace with result
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; +! ( n addr -- ) adds n to the cell at addr.
; https://forth-standard.org/standard/core/PlusStore
;------------------------------------------------------------------------------
        HEADER  "+!", PLUSSTORE_ENTRY, PLUSSTORE_CFA, 0, PLUS_ENTRY
        CODEPTR PLUSSTORE_CODE
        PUBLIC  PLUSSTORE_CODE
        .a16
        .i16
                LDA     0,X             ; addr
                STA     SCRATCH0        ; save addr
                LDA     2,X             ; n
                CLC
                ADC     (SCRATCH0)      ; n + [addr]
                STA     (SCRATCH0)      ; store back
                INX
                INX
                INX
                INX
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; - ( a b -- a-b )
;------------------------------------------------------------------------------
        HEADER  "-", MINUS_ENTRY, MINUS_CFA, 0, PLUSSTORE_ENTRY
        CODEPTR MINUS_CODE
        PUBLIC  MINUS_CODE
        .a16
        .i16
                LDA     2,X             ; a
                SEC
                SBC     0,X             ; a - b
                DROP
                PUT
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; D+ ( d1_lo d1_hi d2_lo d2_hi -- d3_lo d3_hi )
; 32-bit addition with carry from low to high cell.
; Stack: TOS=d2_hi, NOS=d2_lo, NOS2=d1_hi, NOS3=d1_lo
;------------------------------------------------------------------------------
        HEADER  "D+", DPLUS_ENTRY, DPLUS_CFA, 0, MINUS_ENTRY
        CODEPTR DPLUS_CODE
        PUBLIC  DPLUS_CODE
        .a16
        .i16
                CLC
                LDA     a:6,X           ; d1_lo
                ADC     a:2,X           ; + d2_lo
                STA     a:6,X           ; result_lo
                LDA     a:4,X           ; d1_hi
                ADC     a:0,X           ; + d2_hi + carry
                STA     a:4,X           ; result_hi
                INX
                INX
                INX
                INX                     ; drop d2 cells
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; D- ( d1_lo d1_hi d2_lo d2_hi -- d3_lo d3_hi )
; 32-bit subtraction with borrow from low to high cell.
;------------------------------------------------------------------------------
        HEADER  "D-", DMINUS_ENTRY, DMINUS_CFA, 0, DPLUS_ENTRY
        CODEPTR DMINUS_CODE
        PUBLIC  DMINUS_CODE
        .a16
        .i16
                SEC
                LDA     a:6,X           ; d1_lo
                SBC     a:2,X           ; - d2_lo
                STA     a:6,X           ; result_lo
                LDA     a:4,X           ; d1_hi
                SBC     a:0,X           ; - d2_hi - borrow
                STA     a:4,X           ; result_hi
                INX
                INX
                INX
                INX                     ; drop d2 cells
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; M+ ( d n -- d ) add single to double, sign extending n first
;------------------------------------------------------------------------------
        HEADER  "M+", MPLUS_ENTRY, MPLUS_CFA, 0, DMINUS_ENTRY
        CODEPTR DOCOL
        .word   STOD_CFA                ; sign extend n to double
        .word   DPLUS_CFA               ; add to d
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; * ( a b -- a*b ) 16x16 -> 16 (low word)
;
; Two's-complement word multiplication gives the same bit pattern for
; both signed and unsigned inputs, so no sign handling is needed.
; Algorithm: shift-and-add, 16 iterations.
;
; Note: While UM* DROP returns the same result, it's slightly more
; expensive. Also use of page zero variables is waranted for efficiency.
; https://forth-standard.org/standard/core/Times
;------------------------------------------------------------------------------
        HEADER  "*", STAR_ENTRY, STAR_CFA, 0, MPLUS_ENTRY
        CODEPTR STAR_CODE
        PUBLIC  STAR_CODE
        .a16
        .i16
                LDA     0,X             ; b = multiplier
                STA     TMPA
                LDA     2,X             ; a = multiplicand
                STA     TMPB            ; shifting multiplicand lives in TMPB
                INX
                INX
                STZ     SCRATCH0        ; product accumulator = 0
.ifndef UNROLL
                PHY
                LDY     #16
@loop:
.else
.macro SHIFTADD16
.scope
.endif
                LSR     TMPA            ; multiplier >>= 1; LSB → carry
                BCC     @skip
                LDA     SCRATCH0
                CLC
                ADC     TMPB            ; product += curr shifted multiplicand
                STA     SCRATCH0
@skip:
                ASL     TMPB            ; shift multiplicand, not the sum
.ifndef UNROLL
                DEY
                BNE     @loop
.else
.endscope
.endmacro
                ; Unroll the loop for performance.
                SHIFTADD16
                SHIFTADD16
                SHIFTADD16
                SHIFTADD16
                SHIFTADD16
                SHIFTADD16
                SHIFTADD16
                SHIFTADD16
                SHIFTADD16
                SHIFTADD16
                SHIFTADD16
                SHIFTADD16
                SHIFTADD16
                SHIFTADD16
                SHIFTADD16
                SHIFTADD16
.endif
                LDA     SCRATCH0
                STA     0,X
.ifndef UNROLL
                PLY
.endif
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; UM* ( u1 u2 -- ud )   unsigned 16×16 → 32-bit product
; On exit: NOS = ud_low, TOS = ud_high   (ANS Forth convention)
;
; Algorithm: shift-and-add over a 32-bit accumulator.
;   TMPA      = multiplier   (16-bit, shifted right)
;   TMPB      = multiplicand low  word (shifted left, carry tracked below)
;   SCRATCH1  = multiplicand high word (starts 0; receives carry from TMPB)
;   SCRATCH0  = product low  word (accumulator)
;   2,X slot  = product high word (accumulator, kept on stack)
;------------------------------------------------------------------------------
        HEADER  "UM*", UMSTAR_ENTRY, UMSTAR_CFA, 0, STAR_ENTRY
        CODEPTR UMSTAR_CODE
        PUBLIC  UMSTAR_CODE
        .a16
        .i16
                LDA     0,X             ; u2 → TMPA (multiplier)
                STA     TMPA
                LDA     2,X             ; u1 → TMPB (multiplicand low)
                STA     TMPB
                STZ     SCRATCH1        ; multiplicand high = 0
                STZ     SCRATCH0        ; product low  = 0
                STZ     0,X             ; product high = 0  (reuse TOS slot)
.ifndef UNROLL
                PHY                     ; save IP
                LDY     #16             ; 16 iterations
@loop:
.else
                ; Put the contents of an iteration in a macro.
.macro SHIFTADD32
.scope
.endif
                LSR     TMPA            ; multiplier >>= 1; old LSB → carry
                BCC     @skip           ; bit 0 was 0, nothing to add

                ; Add 32-bit multiplicand (SCRATCH1:TMPB) to prod (0,X:SCRATCH0)
                CLC
                LDA     SCRATCH0
                ADC     TMPB            ; product_low  += multiplicand_low
                STA     SCRATCH0
                LDA     0,X
                ADC     SCRATCH1        ; product_high += multiplicand_high + c
                STA     0,X
@skip:
                ; Shift 32-bit multiplicand left
                ASL     TMPB            ; multiplicand_low <<= 1
                ROL     SCRATCH1        ; multiplicand_high <<= 1
.ifndef UNROLL
                DEY
                BNE     @loop
.else
.endscope
.endmacro
                ; Unroll the loop for performance.
                SHIFTADD32
                SHIFTADD32
                SHIFTADD32
                SHIFTADD32
                SHIFTADD32
                SHIFTADD32
                SHIFTADD32
                SHIFTADD32
                SHIFTADD32
                SHIFTADD32
                SHIFTADD32
                SHIFTADD32
                SHIFTADD32
                SHIFTADD32
                SHIFTADD32
                SHIFTADD32
.endif
                ; Place results on parameter stack:
                ;   TOS = ud_high, NOS = ud_low
                LDA     SCRATCH0
                STA     2,X             ; NOS = low
.ifndef UNROLL
                PLY                     ; restore IP
.endif
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; UM/MOD ( ud u -- ur uq ) unsigned 32/16 -> 16 remainder, 16 quotient
; UNDEFINED if quotient overflows 16 bits (i.e. ud_high >= u)
; Entry stack: ( ud_low ud_high divisor -- )
;   0,X = divisor  (u)
;   2,X = ud_high  (high cell of 32-bit dividend)
;   4,X = ud_low   (low cell of 32-bit dividend)
;
; Exit stack: ( remainder quotient )
;   0,X = quotient
;   2,X = remainder
; https://forth-standard.org/standard/core/UMDivMOD
;------------------------------------------------------------------------------
        HEADER  "UM/MOD", UMSLASHMOD_ENTRY, UMSLASHMOD_CFA, 0, UMSTAR_ENTRY
        CODEPTR UMSLASHMOD_CODE
        PUBLIC  UMSLASHMOD_CODE
        .a16
        .i16
                JSR     UMSLASHMOD_IMPL
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; UMSLASHMOD_IMPL  –  shared subroutine: unsigned 32÷16 → 16r 16q
;
; Called via JSR from UM/MOD and SLASHMOD_IMPL.
;
; Entry stack layout (X = PSP before JSR):
;   0,X = divisor  (u16)
;   2,X = ud_high  (high cell of 32-bit dividend)
;   4,X = ud_low   (low  cell of 32-bit dividend)
;
; Exit stack layout (after internal INX/INX that pops divisor):
;   0,X = quotient   (u16)
;   2,X = remainder  (u16)
;
; Algorithm: restoring shift-and-subtract, 16 iterations.
;   We treat the pair (2,X  remainder:quotient 0,X) as a single 32-bit
;   shift register.  Each iteration:
;     1. Shift 32-bit register left 1 bit:
;          ASL quotient_slot   → old bit 15 goes to carry
;          ROL remainder_slot  → carry comes in at LSB
;     2. Attempt subtraction: remainder - divisor
;          If no borrow (remainder ≥ divisor):
;            keep new remainder, set quotient LSB (bit 0, now 0 after ASL) to 1
;          Else restore remainder.
;------------------------------------------------------------------------------
        .export UMSLASHMOD_IMPL
        .proc   UMSLASHMOD_IMPL
        .a16
        .i16
                LDA     0,X             ; load divisor
                STA     TMPA            ; TMPA = divisor
                INX
                INX                     ; pop divisor slot
                ; Now: 0,X = ud_high (remainder register)
                ;      2,X = ud_low  (quotient register)
.ifndef UNROLL
                PHY                     ; save IP
                LDY     #16             ; 16 iterations
@loop:
.else
.macro SHIFTSUB32
.scope
.endif
                ASL     2,X             ; quotient  <<= 1; old bit15 → carry
                ROL     0,X             ; remainder <<= 1; carry → bit0
                LDA     0,X             ; current remainder
                SEC
                SBC     TMPA            ; remainder - divisor
                BCC     @restore        ; borrow → remainder < divisor, skip
                STA     0,X             ; update remainder
                INC     2,X             ; set quotient LSB
@restore:
.ifndef UNROLL
                DEY
                BNE     @loop
.else
.endscope
.endmacro
                ; Unroll the loop for performance.
                SHIFTSUB32
                SHIFTSUB32
                SHIFTSUB32
                SHIFTSUB32
                SHIFTSUB32
                SHIFTSUB32
                SHIFTSUB32
                SHIFTSUB32
                SHIFTSUB32
                SHIFTSUB32
                SHIFTSUB32
                SHIFTSUB32
                SHIFTSUB32
                SHIFTSUB32
                SHIFTSUB32
                SHIFTSUB32
.endif
                ; 0,X = remainder, 2,X = quotient
                ; swap to ANS order TOS=quotient NOS=remainder
                LDA     0,X
                STA     SCRATCH0
                LDA     2,X
                STA     0,X
                LDA     SCRATCH0
                STA     2,X
.ifndef UNROLL
                PLY                     ; restore IP
.endif
                RTS
        .endproc

;------------------------------------------------------------------------------
; /MOD ( n1 n2 -- rem quot )   signed floored division
;------------------------------------------------------------------------------
        HEADER  "/MOD", SLASHMOD_ENTRY, SLASHMOD_CFA, 0, UMSLASHMOD_ENTRY
        CODEPTR DOCOL
        .word   SWAP_CFA                ; ( n2 n1 )
        .word   STOD_CFA                ; ( n2 n1 n1_hi )
        .word   ROT_CFA                 ; ( n1 n1_hi n2 )
        .word   FMMOD_CFA               ; ( rem quot )
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; / ( n1 n2 -- quot ) signed division
;------------------------------------------------------------------------------
        HEADER  "/", SLASH_ENTRY, SLASH_CFA, 0, SLASHMOD_ENTRY
        CODEPTR DOCOL
        .word   SLASHMOD_CFA            ; ( rem quot )
        .word   NIP_CFA                 ; ( quot )
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; MOD ( n1 n2 -- rem )
;------------------------------------------------------------------------------
        HEADER  "MOD", MOD_ENTRY, MOD_CFA, 0, SLASH_ENTRY
        CODEPTR DOCOL
        .word   SLASHMOD_CFA            ; ( rem quot )
        .word   DROP_CFA                ; ( rem )
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; SM/REM ( d1 n1 -- n2 n3 ) Divide d1 by n1, giving the symmetric quotient n3
; and the remainder n2. Input and output stack arguments are signed. An
; ambiguous condition exists if n1 is zero or if the quotient lies outside
; the range of a single-cell signed integer.
; https://forth-standard.org/standard/core/SMDivREM
;------------------------------------------------------------------------------
        HEADER  "SM/REM", SMREM_ENTRY, SMREM_CFA, 0, MOD_ENTRY
        CODEPTR SMREM_CODE
        PUBLIC  SMREM_CODE
        .a16
        .i16
                JSR     SMREM_IMPL
                NEXT
        ENDPUBLIC

        PUBLIC  SMREM_IMPL
        .a16
        .i16
        SMREM_N     = 1                 ; saved divisor (n)
        SMREM_DHIGH = 3                 ; saved d-high
        SMREM_SIGN  = 5                 ; saved sign indicator (d-high XOR n)

                ; Save sign indicator, d-high, and n
                LDA     2,X             ; d-high
                EOR     0,X             ; XOR with n for sign indicator
                PHA                     ; SMREM_SIGN
                LDA     2,X             ; d-high
                PHA                     ; SMREM_DHIGH
                LDA     0,X             ; n
                PHA                     ; SMREM_N

                ; Take absolute value of n
                LDA     0,X
                BPL     @n_pos
                EOR     #$FFFF
                INC     A
                STA     0,X
@n_pos:
                ; Take absolute value of 32-bit dividend
                LDA     2,X             ; d-high
                BPL     @d_pos
                LDA     4,X             ; d-low
                EOR     #$FFFF          ; invert
                CLC
                ADC     #1              ; +1, carry set if result = 0
                STA     4,X
                LDA     2,X             ; d-high
                EOR     #$FFFF          ; invert
                ADC     #0              ; add carry
                STA     2,X
@d_pos:
                JSR     UMSLASHMOD_IMPL ; ( rem quot )

                ; Apply sign to quotient: sign(d-high XOR n)
                LDA     SMREM_SIGN,S
                BPL     @quot_pos
                LDA     0,X
                BEQ     @quot_pos
                EOR     #$FFFF
                INC     A
                STA     0,X
@quot_pos:
                ; Apply sign to remainder: sign of original d-high
                LDA     SMREM_DHIGH,S
                BPL     @rem_pos
                LDA     2,X
                BEQ     @rem_pos
                EOR     #$FFFF
                INC     A
                STA     2,X
@rem_pos:
                PLA                     ; drop SMREM_N
                PLA                     ; drop SMREM_DHIGH
                PLA                     ; drop SMREM_SIGN
                RTS
        ENDPUBLIC

;------------------------------------------------------------------------------
; FM/MOD ( d1 n1 -- n2 n3 ) Divide d1 by n1, giving the floored quotient n3 and
; the remainder n2. Input and output stack arguments are signed. An ambiguous
; condition exists if n1 is zero or if the quotient lies outside the range of
; a single-cell signed integer.
; https://forth-standard.org/standard/core/FMDivMOD
;------------------------------------------------------------------------------
        HEADER  "FM/MOD", FMMOD_ENTRY, FMMOD_CFA, 0, SMREM_ENTRY
        CODEPTR FMMOD_CODE
        PUBLIC  FMMOD_CODE
        .a16
        .i16
                LDA     2,X             ; d-high
                EOR     0,X             ; sign indicator
                PHA                     ; save sign indicator
                LDA     0,X             ; n
                PHA                     ; save n
                JSR     SMREM_IMPL      ; ( rem quot )
                ; Floor correction
                LDA     3,S             ; sign indicator
                BPL     @done           ; same signs → no correction
                LDA     2,X             ; remainder
                BEQ     @done           ; zero → no correction
                DEC     0,X             ; quot -= 1
                LDA     2,X
                CLC
                ADC     1,S             ; rem += n
                STA     2,X
@done:
                PLA                     ; drop n
                PLA                     ; drop sign indicator
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; NEGATE ( n -- -n )
;------------------------------------------------------------------------------
        HEADER  "NEGATE", NEGATE_ENTRY, NEGATE_CFA, 0, FMMOD_ENTRY
        CODEPTR NEGATE_CODE
        PUBLIC  NEGATE_CODE
        .a16
        .i16
                PEEK
                EOR     #$FFFF
                INC     A
                PUT
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; ABS ( n -- |n| )
;------------------------------------------------------------------------------
        HEADER  "ABS", ABS_ENTRY, ABS_CFA, 0, NEGATE_ENTRY
        CODEPTR ABS_CODE
        PUBLIC  ABS_CODE
        .a16
        .i16
                PEEK
                BPL     @done
                EOR     #$FFFF
                INC     A
                PUT
@done:          NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; DABS ( d -- ud ) double absolute value
;------------------------------------------------------------------------------
        HEADER  "DABS", DABS_ENTRY, DABS_CFA, 0, ABS_ENTRY
        CODEPTR DOCOL
        .word   DUP_CFA                 ; ( d_lo d_hi d_hi ) peek at sign
        .word   ZEROLESS_CFA            ; ( d_lo d_hi flag )
        .word   ZBRANCH_CFA
        .word   DABS_DONE
        .word   DNEGATE_CFA             ; ( ud_lo ud_hi ) negate if negative
DABS_DONE:
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; MAX ( a b -- max )
;------------------------------------------------------------------------------
        HEADER  "MAX", MAX_ENTRY, MAX_CFA, 0, DABS_ENTRY
        CODEPTR MAX_CODE
        PUBLIC  MAX_CODE
        .a16
        .i16
                LDA     2,X             ; a
                CMP     0,X             ; a - b (signed)
                BPL     @endif          ; a >= b, a is max
                LDA     0,X             ; a < b, overwrite a with b
                STA     2,X
@endif:         DROP                    ; Drop TOS as NOS is max
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; MIN ( a b -- min )
;------------------------------------------------------------------------------
        HEADER  "MIN", MIN_ENTRY, MIN_CFA, 0, MAX_ENTRY
        CODEPTR MIN_CODE
        PUBLIC  MIN_CODE
        .a16
        .i16
                LDA     2,X             ; a
                CMP     0,X             ; a - b (signed)
                BMI     @endif          ; a < b, a is min
                LDA     0,X             ; a >= b, overwrite a with b
                STA     2,X
@endif:         DROP                    ; Drop TOS as NOS is min
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; 1+ ( n -- n+1 )
;------------------------------------------------------------------------------
        HEADER  "1+", ONEPLUS_ENTRY, ONEPLUS_CFA, 0, MIN_ENTRY
        CODEPTR ONEPLUS_CODE
        PUBLIC  ONEPLUS_CODE
        .a16
        .i16
                INC     0,X
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; 1- ( n -- n-1 )
;------------------------------------------------------------------------------
        HEADER  "1-", ONEMINUS_ENTRY, ONEMINUS_CFA, 0, ONEPLUS_ENTRY
        CODEPTR ONEMINUS_CODE
        PUBLIC  ONEMINUS_CODE
        .a16
        .i16
                DEC     0,X
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; 2* ( n -- n*2 )
;------------------------------------------------------------------------------
        HEADER  "2*", TWOSTAR_ENTRY, TWOSTAR_CFA, 0, ONEMINUS_ENTRY
        CODEPTR TWOSTAR_CODE
        PUBLIC  TWOSTAR_CODE
        .a16
        .i16
                ASL     0,X
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; 2/ ( n -- n/2 ) arithmetic shift right
;------------------------------------------------------------------------------
        HEADER  "2/", TWOSLASH_ENTRY, TWOSLASH_CFA, 0, TWOSTAR_ENTRY
        CODEPTR TWOSLASH_CODE
        PUBLIC  TWOSLASH_CODE
        .a16
        .i16
                PEEK
                ; Arithmetic shift right: preserve sign bit
                CMP     #$8000          ; Set carry if negative
                ROR     A               ; Shift right, sign bit from carry
                PUT
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; D2* ( d -- d*2 ) double shift left.
; https://forth-standard.org/standard/double/DTwoTimes
;------------------------------------------------------------------------------
        HEADER  "D2*", DTWOSTAR_ENTRY, DTWOSTAR_CFA, 0, TWOSLASH_ENTRY
        CODEPTR DOCOL
        .word   TWODUP_CFA
        .word   DPLUS_CFA
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; D2/ ( d -- d/2 ) double arithmetic right shift.
; https://forth-standard.org/standard/double/DTwoDiv
;------------------------------------------------------------------------------
        HEADER  "D2/", DTWOSLASH_ENTRY, DTWOSLASH_CFA, 0, DTWOSTAR_ENTRY
        CODEPTR DOCOL
        .word   DUP_CFA
        .word   LIT_CFA
        .word   1
        .word   AND_CFA
        .word   LIT_CFA
        .word   15
        .word   LSHIFT_CFA
        .word   TOR_CFA
        .word   TWOSLASH_CFA
        .word   SWAP_CFA
        .word   TWOSLASH_CFA
        .word   RFROM_CFA
        .word   OR_CFA
        .word   SWAP_CFA
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; S>D ( n -- d ) Convert the number n to the double-cell number d with the
; same numerical value.
; https://forth-standard.org/standard/core/StoD
;------------------------------------------------------------------------------
        HEADER  "S>D", STOD_ENTRY, STOD_CFA, 0, DTWOSLASH_ENTRY
        CODEPTR STOD_CODE
        PUBLIC  STOD_CODE
        .a16
        .i16
                DEX
                DEX
                LDA     2,X             ; n
                BPL     @positive
                LDA     #$FFFF          ; negative → high cell = $FFFF
                STA     0,X
                NEXT
@positive:
                STZ     0,X             ; positive → high cell = 0
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; D>S ( d -- n ) truncate double to single, discard high cell
;------------------------------------------------------------------------------
        HEADER  "D>S", DTOS_ENTRY, DTOS_CFA, 0, STOD_ENTRY
        CODEPTR DOCOL
        .word   DROP_CFA
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; DNEGATE ( d -- -d ) negate the double cell in ANS order on stack.
; https://forth-standard.org/standard/double/DNEGATE
;------------------------------------------------------------------------------
        HEADER  "DNEGATE", DNEGATE_ENTRY, DNEGATE_CFA, 0, DTOS_ENTRY
        CODEPTR DNEGATE_CODE
        PUBLIC  DNEGATE_CODE
        .a16
        .i16
                LDA     0,X             ; high cell
                EOR     #$FFFF          ; invert
                STA     0,X
                LDA     2,X             ; low cell
                EOR     #$FFFF          ; invert
                INC     A               ; +1
                STA     2,X
                BNE     @done           ; no carry
                INC     0,X             ; propagate carry to high cell
@done:          NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; M* ( n1 n2 -- d ) d is the signed product of n1 times n2.
; https://forth-standard.org/standard/core/MTimes
;------------------------------------------------------------------------------
        HEADER  "M*", MSTAR_ENTRY, MSTAR_CFA, 0, DNEGATE_ENTRY
        CODEPTR DOCOL
        .word   TWODUP_CFA             ; ( n1 n2 n1 n2 )
        .word   XOR_CFA                ; ( n1 n2 xor ) sign of result
        .word   TOR_CFA                ; R: ( sign )
        .word   ABS_CFA                ; ( n1 |n2| )
        .word   SWAP_CFA               ; ( |n2| n1 )
        .word   ABS_CFA                ; ( |n2| |n1| )
        .word   UMSTAR_CFA             ; ( ud ) unsigned 32-bit result
        .word   RFROM_CFA              ; ( ud sign )
        .word   ZEROLESS_CFA           ; ( ud flag ) true if result negative
        .word   ZBRANCH_CFA
        .word   MSTAR_DONE
        .word   DNEGATE_CFA            ; negate if signs differed
MSTAR_DONE:
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; */MOD ( n1 n2 n3 -- n4 n5 ) Multiply n1 by n2 producing the intermediate
; double-cell result d. Divide d by n3 producing the single-cell remainder n4
; and the single-cell quotient n5. An ambiguous condition exists if n3 is zero,
; or if the quotient n5 lies outside the range of a single-cell signed integer.
; If d and n3 differ in sign, the implementation-defined result returned will
; be the same as that returned by either the phrase >R M* R> FM/MOD or the
; phrase >R M* R>
; https://forth-standard.org/standard/core/TimesDivMOD
;------------------------------------------------------------------------------
        HEADER  "*/MOD", SSMOD_ENTRY, SSMOD_CFA, 0, MSTAR_ENTRY
        CODEPTR DOCOL
        .word   TOR_CFA                ; ( n1 n2 ) R: ( n3 )
        .word   MSTAR_CFA              ; ( d ) 32-bit result
        .word   RFROM_CFA              ; ( d n3 )
        .word   SMREM_CFA              ; ( rem quot )
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; */ ( n1 n2 n3 -- n4 ) Multiply n1 by n2 producing the intermediate
; double-cell result d. Divide d by n3 giving the single-cell quotient n4.
; An ambiguous condition exists if n3 is zero or if the quotient n4 lies
; outside the range of a signed number.
; https://forth-standard.org/standard/core/TimesDiv
;------------------------------------------------------------------------------
        HEADER  "*/", SSSLASH_ENTRY, SSSLASH_CFA, 0, SSMOD_ENTRY
        CODEPTR DOCOL
        .word   SSMOD_CFA              ; ( rem quot )
        .word   NIP_CFA                ; ( quot )
        .word   EXIT_CFA

;==============================================================================
; SECTION 4: COMPARISON PRIMITIVES
; ANS Forth: TRUE = $FFFF, FALSE = $0000
;==============================================================================

;------------------------------------------------------------------------------
; = ( a b -- flag )
;------------------------------------------------------------------------------
        HEADER  "=", EQUAL_ENTRY, EQUAL_CFA, 0, SSSLASH_ENTRY
        CODEPTR EQUAL_CODE
        PUBLIC  EQUAL_CODE
        .a16
        .i16
                POP
                CMP     0,X
                BEQ     @true
                STZ     0,X
                NEXT
@true:          LDA     #FORTH_TRUE
                STA     0,X
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; <> ( a b -- flag )
;------------------------------------------------------------------------------
        HEADER  "<>", NOTEQUAL_ENTRY, NOTEQUAL_CFA, 0, EQUAL_ENTRY
        CODEPTR NOTEQUAL_CODE
        PUBLIC  NOTEQUAL_CODE
        .a16
        .i16
                POP
                CMP     0,X
                BNE     @true
                STZ     0,X
                NEXT
@true:          LDA     #FORTH_TRUE
                STA     0,X
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; < ( a b -- flag ) signed
;------------------------------------------------------------------------------
        HEADER  "<", LESS_ENTRY, LESS_CFA, 0, NOTEQUAL_ENTRY
        CODEPTR LESS_CODE
        PUBLIC  LESS_CODE
        .a16
        .i16
                LDA     2,X             ; a
                SEC
                SBC     0,X             ; a - b
                BVS     @overflow       ; Overflow-aware signed compare
                BMI     @true           ; result negative and no overflow = a<b
                LDA     #FORTH_FALSE    ; Set TOS to false
                BRA     @return
@overflow:
                BPL     @true           ; overflow + positive result = a<b
@false:         LDA     #FORTH_FALSE    ; Set TOS to false
                BRA     @return
@true:          LDA     #FORTH_TRUE     ; Set TOS to true
@return:
                DROP                    ; Drop b
                PUT                     ; Set TOS to result
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; > ( a b -- flag ) signed
;------------------------------------------------------------------------------
        HEADER  ">", GREATER_ENTRY, GREATER_CFA, 0, LESS_ENTRY
        CODEPTR GREATER_CODE
        PUBLIC  GREATER_CODE
        .a16
        .i16
                LDA     0,X             ; b
                SEC
                SBC     2,X             ; b - a (reversed for >)
                BVS     @overflow       ; Overflow-aware signed compare
                BMI     @true           ; like the previous function
                LDA     #FORTH_FALSE    ; Set TOS to false
                BRA     @return
@overflow:
                BPL     @true
@false:         LDA     #FORTH_FALSE    ; Set TOS to false
                BRA     @return
@true:          LDA     #FORTH_TRUE     ; Set TOS to true
@return:
                INX                     ; Drop b
                INX
                STA     0,X             ; Set TOS to result
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; U< ( u1 u2 -- flag ) unsigned less than
;------------------------------------------------------------------------------
        HEADER  "U<", ULESS_ENTRY, ULESS_CFA, 0, GREATER_ENTRY
        CODEPTR ULESS_CODE
        PUBLIC  ULESS_CODE
        .a16
        .i16
                LDA     2,X             ; u1
                CMP     0,X             ; u1 - u2 (unsigned)
                INX
                INX
                BCC     @true           ; Carry clear = u1 < u2
                STZ     0,X
                NEXT
@true:          LDA     #FORTH_TRUE
                STA     0,X
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; U> ( u1 u2 -- flag ) unsigned greater than
;------------------------------------------------------------------------------
        HEADER  "U>", UGREATER_ENTRY, UGREATER_CFA, 0, ULESS_ENTRY
        CODEPTR UGREATER_CODE
        PUBLIC  UGREATER_CODE
        .a16
        .i16
                LDA     0,X             ; u2
                CMP     2,X             ; u2 - u1 (reversed)
                INX
                INX
                BCC     @true
                STZ     0,X
                NEXT
@true:          LDA     #FORTH_TRUE
                STA     0,X
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; 0= ( a -- flag )
;------------------------------------------------------------------------------
        HEADER  "0=", ZEROEQ_ENTRY, ZEROEQ_CFA, 0, UGREATER_ENTRY
        CODEPTR ZEROEQ_CODE
        PUBLIC  ZEROEQ_CODE
        .a16
        .i16
                LDA     0,X
                BNE     @false
                LDA     #FORTH_TRUE
                STA     0,X
                NEXT
@false:         STZ     0,X
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; 0< ( a -- flag )
;------------------------------------------------------------------------------
        HEADER  "0<", ZEROLESS_ENTRY, ZEROLESS_CFA, 0, ZEROEQ_ENTRY
        CODEPTR ZEROLESS_CODE
        PUBLIC  ZEROLESS_CODE
        .a16
        .i16
                LDA     0,X
                BPL     @false
                LDA     #FORTH_TRUE
                STA     0,X
                NEXT
@false:         STZ     0,X
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; 0> ( a -- flag )
;------------------------------------------------------------------------------
        HEADER  "0>", ZEROGT_ENTRY, ZEROGT_CFA, 0, ZEROLESS_ENTRY
        CODEPTR ZEROGT_CODE
        PUBLIC  ZEROGT_CODE
        .a16
        .i16
                LDA     0,X
                BEQ     @false
                BPL     @true
@false:         STZ     0,X
                NEXT
@true:          LDA     #FORTH_TRUE
                STA     0,X
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; 0<> ( a -- flag )
;------------------------------------------------------------------------------
        HEADER  "0<>", ZERONE_ENTRY, ZERONE_CFA, 0, ZEROGT_ENTRY
        CODEPTR ZERONE_CODE
        PUBLIC  ZERONE_CODE
        .a16
        .i16
                LDA     0,X
                BEQ     @return
                LDA     #FORTH_TRUE
                STA     0,X
@return:        NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; D= ( d1_lo d1_hi d2_lo d2_hi -- flag )
; True if both cells equal.
;------------------------------------------------------------------------------
        HEADER  "D=", DEQ_ENTRY, DEQ_CFA, 0, ZERONE_ENTRY
        CODEPTR DEQ_CODE
        PUBLIC  DEQ_CODE
        .a16
        .i16
                LDA     a:6,X           ; d1_lo
                CMP     a:2,X           ; d2_lo
                BNE     @false
                LDA     a:4,X           ; d1_hi
                CMP     a:0,X           ; d2_hi
                BNE     @false
                LDA     #FORTH_TRUE
                BRA     @return
@false:
                LDA     #FORTH_FALSE
@return:        DROP                    ; drop 3 cells
                DROP
                DROP
                PUT                     ; Put flag in 4th cell
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; D0= ( ud_lo ud_hi -- flag ) true if double is zero
; https://forth-standard.org/standard/double/DZeroEqual
;------------------------------------------------------------------------------
        HEADER  "D0=", DZEROEQ_ENTRY, DZEROEQ_CFA, 0, DEQ_ENTRY
        CODEPTR DOCOL
        .word   OR_CFA
        .word   ZEROEQ_CFA
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; D0< ( ud_lo ud_hi -- flag ) true if double is negative
; https://forth-standard.org/standard/double/DZeroless
;------------------------------------------------------------------------------
        HEADER  "D0<", DZEROLESS_ENTRY, DZEROLESS_CFA, 0, DZEROEQ_ENTRY
        CODEPTR DOCOL
        .word   NIP_CFA
        .word   ZEROLESS_CFA
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; DU< ( ud1_lo ud1_hi ud2_lo ud2_hi -- flag )
; Unsigned 32-bit less than.
;------------------------------------------------------------------------------
        HEADER  "DU<", DULESS_ENTRY, DULESS_CFA, 0, DZEROLESS_ENTRY
        CODEPTR DULESS_CODE
        PUBLIC  DULESS_CODE
        .a16
        .i16
                ; Compare high cells first
                LDA     a:4,X           ; ud1_hi
                CMP     a:0,X           ; ud2_hi
                BCC     @true           ; ud1_hi < ud2_hi unsigned
                BNE     @false          ; ud1_hi > ud2_hi
                ; High cells equal, compare low cells
                LDA     a:6,X           ; ud1_lo
                CMP     a:2,X           ; ud2_lo
                BCC     @true
@false:
                LDA     #FORTH_FALSE
                BRA     @return
                NEXT
@true:
                LDA     #FORTH_TRUE
@return:        DROP                    ; drop 3 cells
                DROP
                DROP
                PUT                     ; Put flag in 4th cell
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; D< ( d1_lo d1_hi d2_lo d2_hi -- flag )
; Signed 32-bit less than. Compare high cells with overflow-aware signed
; compare; only if high cells are equal fall through to unsigned low cell
; compare.
;------------------------------------------------------------------------------
        HEADER  "D<", DLESS_ENTRY, DLESS_CFA, 0, DULESS_ENTRY
        CODEPTR DLESS_CODE
        PUBLIC  DLESS_CODE
        .a16
        .i16
                ; Compare high cells (signed)
                LDA     a:4,X           ; d1_hi
                SEC
                SBC     a:0,X           ; d1_hi - d2_hi
                BEQ     @equal_hi       ; high cells equal, check low
                BVS     @overflow
                BMI     @true           ; negative, no overflow -> d1 < d2
                BRA     @false
@overflow:
                BPL     @true           ; overflow + positive -> d1 < d2
                BRA     @false
@equal_hi:
                ; High cells equal: unsigned compare of low cells
                LDA     a:6,X           ; d1_lo
                CMP     a:2,X           ; d2_lo
                BCC     @true
@false:
                LDA     #FORTH_FALSE
                BRA     @return
@true:
                LDA     #FORTH_TRUE
@return:        DROP                    ; drop 3 cells
                DROP
                DROP
                PUT                     ; Put flag in 4th cell
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; DMAX ( d1 d2 -- d ) larger of two doubles
; https://forth-standard.org/standard/double/DMAX
;------------------------------------------------------------------------------
        HEADER  "DMAX", DMAX_ENTRY, DMAX_CFA, 0, DLESS_ENTRY
        CODEPTR DOCOL
        .word   TWOOVER_CFA
        .word   TWOOVER_CFA
        .word   DLESS_CFA
        .word   ZBRANCH_CFA
        .word   DMAX_SKIP
        .word   TWOSWAP_CFA
DMAX_SKIP:
        .word   TWODROP_CFA
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; DMIN ( d1 d2 -- d ) smaller of two doubles
; https://forth-standard.org/standard/double/DMIN
;------------------------------------------------------------------------------
        HEADER  "DMIN", DMIN_ENTRY, DMIN_CFA, 0, DMAX_ENTRY
        CODEPTR DOCOL
        .word   TWOOVER_CFA
        .word   TWOOVER_CFA
        .word   DLESS_CFA
        .word   ZBRANCH_CFA
        .word   DMIN_ELSE
        .word   TWODROP_CFA
        .word   BRANCH_CFA
        .word   DMIN_THEN
DMIN_ELSE:
        .word   TWOSWAP_CFA
        .word   TWODROP_CFA
DMIN_THEN:
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; WITHIN ( n lo hi -- flag ) true if lo <= n < hi
;------------------------------------------------------------------------------
        HEADER  "WITHIN", WITHIN_ENTRY, WITHIN_CFA, 0, DMIN_ENTRY
        CODEPTR DOCOL
        .word   OVER_CFA
        .word   MINUS_CFA
        .word   TOR_CFA
        .word   MINUS_CFA
        .word   RFROM_CFA
        .word   ULESS_CFA
        .word   EXIT_CFA

;==============================================================================
; SECTION 5: LOGIC CONSTANTS AND PRIMITIVES
;==============================================================================

;------------------------------------------------------------------------------
; TRUE ( -- TRUE )
;------------------------------------------------------------------------------
        HEADER  "TRUE", TRUE_ENTRY, TRUE_CFA, 0, WITHIN_ENTRY
        CODEPTR TRUE_CODE
        PUBLIC  TRUE_CODE
        .a16
        .i16
                LDA     #FORTH_TRUE
                PUSH
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; FALSE ( -- FALSE )
;------------------------------------------------------------------------------
        HEADER  "FALSE", FALSE_ENTRY, FALSE_CFA, 0, TRUE_ENTRY
        CODEPTR FALSE_CODE
        PUBLIC  FALSE_CODE
        .a16
        .i16
                LDA     #FORTH_FALSE
                PUSH
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; AND ( a b -- a&b )
;------------------------------------------------------------------------------
        HEADER  "AND", AND_ENTRY, AND_CFA, 0, FALSE_ENTRY
        CODEPTR AND_CODE
        PUBLIC  AND_CODE
        .a16
        .i16
                POP
                AND     0,X
                PUT
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; OR ( a b -- a|b )
;------------------------------------------------------------------------------
        HEADER  "OR", OR_ENTRY, OR_CFA, 0, AND_ENTRY
        CODEPTR OR_CODE
        PUBLIC  OR_CODE
        .a16
        .i16
                POP
                ORA     0,X
                PUT
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; XOR ( a b -- a^b )
;------------------------------------------------------------------------------
        HEADER  "XOR", XOR_ENTRY, XOR_CFA, 0, OR_ENTRY
        CODEPTR XOR_CODE
        PUBLIC  XOR_CODE
        .a16
        .i16
                POP
                EOR     0,X
                PUT
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; INVERT ( a -- ~a )
;------------------------------------------------------------------------------
        HEADER  "INVERT", INVERT_ENTRY, INVERT_CFA, 0, XOR_ENTRY
        CODEPTR INVERT_CODE
        PUBLIC  INVERT_CODE
        .a16
        .i16
                PEEK
                EOR     #$FFFF
                PUT
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; LSHIFT ( a u -- a<<u )
;------------------------------------------------------------------------------
        HEADER  "LSHIFT", LSHIFT_ENTRY, LSHIFT_CFA, 0, INVERT_ENTRY
        CODEPTR LSHIFT_CODE
        PUBLIC  LSHIFT_CODE
        .a16
        .i16
                LDA     0,X             ; shift count
                INX
                INX
                PHY                     ; Save IP (TAY below clobbers it)
                TAY
                BEQ     @done
                LDA     0,X
@loop:          ASL     A
                DEY
                BNE     @loop
                STA     0,X
@done:          PLY                     ; Restore IP
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; RSHIFT ( a u -- a>>u ) logical shift right
;------------------------------------------------------------------------------
        HEADER  "RSHIFT", RSHIFT_ENTRY, RSHIFT_CFA, 0, LSHIFT_ENTRY
        CODEPTR RSHIFT_CODE
        PUBLIC  RSHIFT_CODE
        .a16
        .i16
                LDA     0,X
                INX
                INX
                PHY                     ; Save IP (TAY below clobbers it)
                TAY
                BEQ     @done
                LDA     0,X
@loop:          LSR     A
                DEY
                BNE     @loop
                STA     0,X
@done:          PLY                     ; Restore IP
                NEXT
        ENDPUBLIC

;==============================================================================
; SECTION 6: MEMORY PRIMITIVES
;==============================================================================

;------------------------------------------------------------------------------
; @ ( addr -- val ) fetch cell
;------------------------------------------------------------------------------
        HEADER  "@", FETCH_ENTRY, FETCH_CFA, 0, RSHIFT_ENTRY
        CODEPTR FETCH_CODE
        PUBLIC  FETCH_CODE
        .a16
        .i16
                LDA     0,X             ; addr
                STA     SCRATCH0
                LDA     (SCRATCH0)      ; fetch 16-bit value
                STA     0,X
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; ! ( val addr -- ) store cell
;------------------------------------------------------------------------------
        HEADER  "!", STORE_ENTRY, STORE_CFA, 0, FETCH_ENTRY
        CODEPTR STORE_CODE
        PUBLIC  STORE_CODE
        .a16
        .i16
                LDA     0,X             ; addr
                STA     SCRATCH0
                INX
                INX
                LDA     0,X             ; val
                INX
                INX
                STA     (SCRATCH0)
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; C@ ( addr -- byte ) fetch byte
;------------------------------------------------------------------------------
        HEADER  "C@", CFETCH_ENTRY, CFETCH_CFA, 0, STORE_ENTRY
        CODEPTR CFETCH_CODE
        PUBLIC  CFETCH_CODE
        .a16
        .i16
                LDA     0,X
                STA     SCRATCH0
                SEP     #$20
                .a8
                LDA     (SCRATCH0)
                REP     #$20
                .a16
                AND     #$00FF
                STA     0,X
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; C! ( byte addr -- ) store byte
;------------------------------------------------------------------------------
        HEADER  "C!", CSTORE_ENTRY, CSTORE_CFA, 0, CFETCH_ENTRY
        CODEPTR CSTORE_CODE
        PUBLIC  CSTORE_CODE
        .a16
        .i16
                LDA     0,X             ; addr
                STA     SCRATCH0
                INX
                INX
                LDA     0,X             ; byte
                INX
                INX
                SEP     #$20
                .a8
                STA     (SCRATCH0)
                REP     #$20
                .a16
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; 2@ ( a-addr -- x1 x2 ) Fetch the cell pair x1 x2 stored at a-addr. x2 is
; stored at a-addr and x1 at the next consecutive cell. It is equivalent to
; the sequence DUP CELL+ @ SWAP @.
; https://forth-standard.org/standard/core/TwoFetch
;------------------------------------------------------------------------------
        HEADER  "2@", TWOFETCH_ENTRY, TWOFETCH_CFA, 0, CSTORE_ENTRY
        CODEPTR TWOFETCH_CODE
        PUBLIC  TWOFETCH_CODE
        .a16
        .i16
                PEEK                    ; peek addr → SCRATCH0
                STA     SCRATCH0
                CLC
                ADC     #CELL_SIZE      ; addr+2 → SCRATCH1 (carry now clear)
                STA     SCRATCH1
                LDA     (SCRATCH1)      ; high cell of d
                PUT
                LDA     (SCRATCH0)      ; low cell of d
                PUSH
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; 2! ( x1 x2 a-addr -- ) Store the cell pair x1 x2 at a-addr, with x2 at
; a-addr and x1 at the next consecutive cell. It is equivalent to the sequence
; SWAP OVER ! CELL+ !.
; https://forth-standard.org/standard/core/TwoStore
;------------------------------------------------------------------------------
        HEADER  "2!", TWOSTORE_ENTRY, TWOSTORE_CFA, 0, TWOFETCH_ENTRY
        CODEPTR TWOSTORE_CODE
        PUBLIC  TWOSTORE_CODE
        .a16
        .i16
                LDA     0,X             ; peek addr → SCRATCH0
                STA     SCRATCH0
                CLC
                ADC     #CELL_SIZE      ; addr+2 → SCRATCH1 (carry now clear)
                STA     SCRATCH1
                LDA     2,X             ; low cell of d
                STA     (SCRATCH0)      ; store at addr
                LDA     4,X             ; high cell of d
                STA     (SCRATCH1)      ; store at addr+2
                TXA
                ADC     #3*CELL_SIZE    ; drop 3 cells (carry still clear from above)
                TAX
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; ALIGNED ( addr -- a-addr ) a-addr is the first aligned address greater than
; or equal to addr.
; https://forth-standard.org/standard/core/ALIGNED
;------------------------------------------------------------------------------
        HEADER  "ALIGNED", ALIGNED_ENTRY, ALIGNED_CFA, 0, TWOSTORE_ENTRY
        CODEPTR DOCOL
        .word   ONEPLUS_CFA
        .word   LIT_CFA
        .word   $FFFE
        .word   AND_CFA
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; MOVE ( src dst u -- ) copy u bytes from src to dst
;------------------------------------------------------------------------------
        HEADER  "MOVE", MOVE_ENTRY, MOVE_CFA, 0, ALIGNED_ENTRY
        CODEPTR MOVE_CODE
        PUBLIC  MOVE_CODE
        .a16
        .i16
                LOC_SRCPTR = 1
                LOC_DSTPTR = 3
                PHY                     ; Save IP
                LDA     0,X             ; pop u (byte count) to Y
                INX
                INX
                TAY
                LDA     0,X             ; pop dst to LOC_DSTPTR
                INX
                INX
                PHA
                LDA     0,X             ; pop src to LOC_SRCPTR
                INX
                INX
                PHA
                TYA                     ; Test for zero count = no-op
                BEQ     @done
                DEY                     ; Change count to an index
@loop:
                SEP     #$20
                .a8
                LDA     (LOC_SRCPTR,S),Y
                STA     (LOC_DSTPTR,S),Y
                REP     #$20
                .a16
                DEY
                BPL     @loop           ; loop terminates at -1 to copy 0 byte as well.
@done:          PLA                     ; Drop stack locals
                PLA
                PLY                     ; Restore IP
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; FILL ( addr u byte -- ) fill u bytes starting at addr with byte
;------------------------------------------------------------------------------
        HEADER  "FILL", FILL_ENTRY, FILL_CFA, 0, MOVE_ENTRY
        CODEPTR FILL_CODE
        PUBLIC  FILL_CODE
        .a16
        .i16
                LOC_DSTPTR = 1
                LOC_BYTE = 3
                PHY                     ; Save IP
                LDA     0,X             ; pop fill byte to LOC_BYTE
                INX
                INX
                PHA
                LDA     0,X             ; pop u (byte count) to Y
                INX
                INX
                TAY
                LDA     0,X             ; pop addr to LOC_DTSPTR
                INX
                INX
                PHA
                TYA                     ; Test for zero count = no-op
                BEQ     @done
                DEY                     ; Change count to an index
@loop:
                SEP     #$20
                .a8
                LDA     LOC_BYTE,S
                STA     (LOC_DSTPTR,S),Y
                REP     #$20
                .a16
                DEY
                BPL     @loop
@done:          PLA                     ; Drop stack locals
                PLA
                PLY                     ; Restore IP
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; ERASE ( addr u -- ) fill u bytes starting at addr with zero
;------------------------------------------------------------------------------
        HEADER  "ERASE", ERASE_ENTRY, ERASE_CFA, 0, FILL_ENTRY
        CODEPTR DOCOL
        .word   ZERO_CFA
        .word   FILL_CFA                ; compile LIT
        .word   EXIT_CFA

;==============================================================================
; SECTION 7: UART I/O PRIMITIVES
;==============================================================================

;------------------------------------------------------------------------------
; EMIT ( char -- ) transmit character via HAL
;------------------------------------------------------------------------------
        HEADER  "EMIT", EMIT_ENTRY, EMIT_CFA, 0, ERASE_ENTRY
        CODEPTR EMIT_CODE
        PUBLIC  EMIT_CODE
        .a16
        .i16
                LDA     0,X             ; Char to send
                INX
                INX
                JSR     hal_putch       ; HAL handles UART details
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; KEY ( -- char ) receive character (blocking) via HAL
;------------------------------------------------------------------------------
        HEADER  "KEY", KEY_ENTRY, KEY_CFA, 0, EMIT_ENTRY
        CODEPTR KEY_CODE
        PUBLIC  KEY_CODE
        .a16
        .i16
                JSR     hal_getch       ; Blocking receive, result in A
                DEX
                DEX
                STA     0,X
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; KEY? ( -- flag ) non-blocking check for available input via HAL
;------------------------------------------------------------------------------
        HEADER  "KEY?", KEYQ_ENTRY, KEYQ_CFA, 0, KEY_ENTRY
        CODEPTR KEYQ_CODE
        PUBLIC  KEYQ_CODE
        .a16
        .i16
                ; Check lookahead buffer first
                JSR     hal_cready      ; Returns $FFFF or $0000 in A,
                DEX
                DEX
                STA     0,X
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; TYPE ( addr u -- ) transmit u characters from addr via HAL
;------------------------------------------------------------------------------
        HEADER  "TYPE", TYPE_ENTRY, TYPE_CFA, 0, KEYQ_ENTRY
        CODEPTR TYPE_CODE
        PUBLIC  TYPE_CODE
        .a16
        .i16
                PHY
                LDY     0,X             ; u
                INX
                INX
                LDA     0,X             ; addr
                INX
                INX
                PHX
                PHA
                TYX                     ; Zero count = no-op
                BEQ     @done           ; not after INX which clobbers z flag)
                LDY     #0000
@loop:
                SEP     #MEM16
                .A8
                LDA     (1,S),Y         ; Fetch byte
                REP     #MEM16
                .A16
                AND     #$00FF
                JSR     hal_putch
                INY                     ; Advance pointer
                DEX
                BNE     @loop
@done:          PLA                     ; Clean up stack frame
                PLX
                PLY
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; CPUTS ( addr -- ) transmits a NULL terminated stringfrom addr via HAL
;------------------------------------------------------------------------------
        HEADER  "CPUTS", CPUTS_ENTRY, CPUTS_CFA, 0, TYPE_ENTRY
        CODEPTR CPUTS_CODE
        PUBLIC  CPUTS_CODE
        .a16
        .i16
                LDA     0,X
                INX
                INX
                JSR     hal_cputs
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; CR ( -- ) emit carriage return + line feed via HAL
;------------------------------------------------------------------------------
        HEADER  "CR", CR_ENTRY, CR_CFA, 0, CPUTS_ENTRY
        CODEPTR CR_CODE
        PUBLIC  CR_CODE
        .a16
        .i16
                LDA     #C_RETURN       ; Carriage return
                JSR     hal_putch
                LDA     #L_FEED         ; Line feed
                JSR     hal_putch
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; SPACE ( -- ) emit a single space via HAL
;------------------------------------------------------------------------------
        HEADER  "SPACE", SPACE_ENTRY, SPACE_CFA, 0, CR_ENTRY
        CODEPTR SPACE_CODE
        PUBLIC  SPACE_CODE
        .a16
        .i16
                LDA     #SPACE
                JSR     hal_putch
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; SPACES ( n -- ) emit n spaces via HAL
;------------------------------------------------------------------------------
        HEADER  "SPACES", SPACES_ENTRY, SPACES_CFA, 0, SPACE_ENTRY
        CODEPTR SPACES_CODE
        PUBLIC  SPACES_CODE
        .a16
        .i16
                PHY
                LDA     0,X             ; n
                INX
                INX
                TAY
                BEQ     @done           ; Zero = no-op
@loop:
                LDA     #SPACE
                JSR     hal_putch
                DEY
                BNE     @loop
@done:          PLY
                NEXT
        ENDPUBLIC

;==============================================================================
; SECTION 8: INNER INTERPRETER SUPPORT WORDS
;==============================================================================

;------------------------------------------------------------------------------
; EXIT ( -- ) return from current colon definition
; https://forth-standard.org/standard/core/EXIT
;------------------------------------------------------------------------------
        HEADER  "EXIT", EXIT_ENTRY, EXIT_CFA, 0, SPACES_ENTRY
        CODEPTR EXIT_CODE
        PUBLIC  EXIT_CODE
        .a16
        .i16
                PLY                     ; Pop saved IP to restore IP in Y
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; EXECUTE ( xt -- ) execute word by execution token
;------------------------------------------------------------------------------
        HEADER  "EXECUTE", EXECUTE_ENTRY, EXECUTE_CFA, 0, EXIT_ENTRY
        CODEPTR EXECUTE_CODE
        PUBLIC  EXECUTE_CODE
        .a16
        .i16
                LDA     0,X             ; xt = CFA
                INX
                INX
                STA     W               ; W = CFA
                LDA     (W)             ; Fetch code pointer
                STA     SCRATCH0
                JMP     (SCRATCH0)      ; Jump (word will NEXT itself)
        ENDPUBLIC

;------------------------------------------------------------------------------
; LIT ( -- n ) push inline literal (compiled word, not user-callable)
;------------------------------------------------------------------------------
        HEADER  "LIT", LIT_ENTRY, LIT_CFA, F_HIDDEN, EXECUTE_ENTRY
        CODEPTR LIT_CODE
        PUBLIC  LIT_CODE
        .a16
        .i16
                IFETCH                  ; Fetch literal value at IP++
                PUSH                    ; Push literal
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; LITERAL ( n -- ) compile-time, compiles n as a literal into current definition;------------------------------------------------------------------------------
        HEADER  "LITERAL", LITERAL_ENTRY, LITERAL_CFA, F_IMMEDIATE, LIT_ENTRY
        CODEPTR DOCOL
        .word   LIT_CFA
        .word   LIT_CFA
        .word   COMMA_CFA              ; compile LIT
        .word   COMMA_CFA              ; compile n
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; 2LIT ( -- d_lo d_hi ) runtime, pushes inline 32-bit double literal
; Fetches two consecutive cells from the instruction stream: low then high.
;------------------------------------------------------------------------------
        HEADER  "2LIT", TWOLIT_ENTRY, TWOLIT_CFA, F_HIDDEN, LITERAL_ENTRY
        CODEPTR TWOLIT_CODE
        PUBLIC  TWOLIT_CODE
        .a16
        .i16
                IFETCH                  ; A = d_lo, IP advanced
                PUSH                    ; push d_lo
                IFETCH                  ; A = d_hi, IP advanced
                PUSH                    ; push d_hi (TOS)
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; 2LITERAL ( d_lo d_hi -- ) compile-time immediate, compiles a double literal
; into the current definition as 2LIT followed by two inline cells.
; Stack on entry is ANS double convention: NOS=d_lo, TOS=d_hi.
;------------------------------------------------------------------------------
        HEADER  "2LITERAL", TWOLITERAL_ENTRY, TWOLITERAL_CFA, F_IMMEDIATE, TWOLIT_ENTRY
        CODEPTR DOCOL
        .word   SWAP_CFA               ; ( d_hi d_lo ) - store low cell first
        .word   LIT_CFA
        .word   TWOLIT_CFA
        .word   COMMA_CFA              ; compile 2LIT
        .word   COMMA_CFA              ; compile d_lo
        .word   COMMA_CFA              ; compile d_hi
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; BRANCH ( -- ) unconditional branch (compiled word)
; The cell following BRANCH contains the branch offset (signed)
;------------------------------------------------------------------------------
        HEADER  "BRANCH", BRANCH_ENTRY, BRANCH_CFA, F_HIDDEN, TWOLITERAL_ENTRY
        CODEPTR BRANCH_CODE
        PUBLIC  BRANCH_CODE
        .a16
        .i16
                LDA     0,Y             ; Fetch offset at IP
                ; IP (Y) currently points to offset cell
                ; Branch target = IP + 2 + offset
                ; But offset is stored as absolute address for simplicity:
                TAY                     ; IP = branch target (absolute)
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; 0BRANCH ( flag -- ) branch if flag is zero (compiled word)
;------------------------------------------------------------------------------
        HEADER  "0BRANCH", ZBRANCH_ENTRY, ZBRANCH_CFA, F_HIDDEN, BRANCH_ENTRY
        CODEPTR ZBRANCH_CODE
        PUBLIC  ZBRANCH_CODE
        .a16
        .i16
                LDA     0,X             ; pop flag
                INX
                INX
                CMP     #$0000          ; Test flag (INX clobbers zero flag,
                BNE     @no_branch      ; so use CMP not BEQ/BNE directly)
                LDA     0,Y             ; Fetch branch target
                TAY                     ; IP = target
                NEXT
@no_branch:
                INY                     ; Skip branch target cell
                INY
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; (DO) ( limit index -- ) (R: -- limit index) runtime for DO
;------------------------------------------------------------------------------
        HEADER  "(DO)", DODO_ENTRY, DODO_CFA, F_HIDDEN, ZBRANCH_ENTRY
        CODEPTR DODO_CODE
        PUBLIC  DODO_CODE
        .a16
        .i16
                LDA     0,Y             ; Load leave target
                PHA                     ; Push leave target onto return stack
                INY                     ; Advance past leave target
                INY
                LDA     2,X             ; limit
                PHA                     ; Push limit onto return stack
                LDA     0,X             ; index
                PHA                     ; Push index onto return stack
                INX
                INX
                INX
                INX
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; (LOOP) ( -- ) (R: limit index -- | limit index+1)
; runtime for LOOP - increments index, branches back if not done
;------------------------------------------------------------------------------
        HEADER  "(LOOP)", DOLOOP_ENTRY, DOLOOP_CFA, F_HIDDEN, DODO_ENTRY
        CODEPTR DOLOOP_CODE
        PUBLIC  DOLOOP_CODE
        .a16
        .i16
                PLA                     ; index
                INC     A               ; index+1
                STA     SCRATCH0
                PLA                     ; limit
                CMP     SCRATCH0        ; limit == index+1?
                BEQ     @done           ; Loop finished
                PHA                     ; Push limit back
                LDA     SCRATCH0
                PHA                     ; Push index+1 back
                LDA     0,Y             ; Branch target
                TAY                     ; IP = loop top
                NEXT
@done:                                  ; Drop limit, don't push index back
                PLA                     ; Drop leave target
                INY                     ; Skip branch target
                INY
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; (+LOOP) ( n -- ) (R: limit index -- | limit index+n)
; runtime for +LOOP
;------------------------------------------------------------------------------
        HEADER  "(+LOOP)", DOPLUSLOOP_ENTRY, DOPLUSLOOP_CFA, F_HIDDEN, DOLOOP_ENTRY
        CODEPTR DOPLUSLOOP_CODE
        PUBLIC  DOPLUSLOOP_CODE
        .a16
        .i16
                LOC_IP      = 1         ; saved IP (our PHY)
                LOC_INDEX   = 3         ; index
                LOC_LIMIT   = 5         ; limit
                LOC_LEAVE   = 7         ; leave target
                PHY                     ; Save IP

                ; Pop step from parameter stack
                LDA     0,X
                INX
                INX
                STA     SCRATCH1        ; step

                ; old_diff = index - limit
                LDA     LOC_INDEX,S
                SEC
                SBC     LOC_LIMIT,S
                STA     SCRATCH0        ; old_diff

                ; new_index = index + step, update frame
                LDA     LOC_INDEX,S
                CLC
                ADC     SCRATCH1
                STA     LOC_INDEX,S     ; new_index stored back into frame

                ; new_diff = new_index - limit
                SEC
                SBC     LOC_LIMIT,S

                ; Sign change or zero crossing
                EOR     SCRATCH0
                BMI     @done           ; Sign changed → done

                ; Continue
                PLY                     ; Restore IP (points to branch target)
                LDA     0,Y             ; Fetch branch target
                TAY                     ; IP = loop top
                NEXT
@done:
                PLY                     ; Restore IP
                PLA                     ; Discard index
                PLA                     ; Discard limit
                PLA                     ; Discard leave-target
                INY                     ; Skip branch target cell
                INY
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; UNLOOP ( -- ) (R: limit index -- ) discard DO loop parameters
;------------------------------------------------------------------------------
        HEADER  "UNLOOP", UNLOOP_ENTRY, UNLOOP_CFA, 0, DOPLUSLOOP_ENTRY
        CODEPTR UNLOOP_CODE
        PUBLIC  UNLOOP_CODE
        .a16
        .i16
                PLA                     ; Discard index
                PLA                     ; Discard limit
                PLA                     ; Discard leave target
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; I ( -- n ) (R: limit index -- limit index) copy loop index
;------------------------------------------------------------------------------
        HEADER  "I", I_ENTRY, I_CFA, 0, UNLOOP_ENTRY
        CODEPTR I_CODE
        PUBLIC  I_CODE
        .a16
        .i16
                ; Return stack: TOS=index NOS=limit
                LDA     1,S             ; Index I
                DEX
                DEX
                STA     0,X
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; J ( -- n ) copy outer loop index
;------------------------------------------------------------------------------
        HEADER  "J", J_ENTRY, J_CFA, 0, I_ENTRY
        CODEPTR J_CODE
        PUBLIC  J_CODE
        .a16
        .i16
        LOC_J     = 7                   ; outer index
        LOC_LEAVE = 5                   ; inner leave target
        LOC_LIMIT = 3                   ; inner limit
        LOC_I     = 1                   ; inner index
                LDA     LOC_J,S         ; Peek J from RSP
                DEX
                DEX
                STA     0,X             ; Push outer index to param stack
                NEXT
        ENDPUBLIC

;==============================================================================
; SECTION 9: DICTIONARY PRIMITIVES
;==============================================================================

;------------------------------------------------------------------------------
; ALIGN ( -- )
; Align dictionary pointer (DP) to next even address if not already aligned.
;------------------------------------------------------------------------------
        HEADER  "ALIGN", ALIGN_ENTRY, ALIGN_CFA, 0, J_ENTRY
        CODEPTR ALIGN_CODE
        PUBLIC  ALIGN_CODE
        .a16
        .i16
                PHY
                LDY     #U_DP
                LDA     (UP),Y          ; fetch DP
                INC     A               ; round up
                AND     #$FFFE          ; align to even
                STA     (UP),Y          ; write back
                PLY
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; HERE ( -- addr ) current dictionary pointer
;------------------------------------------------------------------------------
        HEADER  "HERE", HERE_ENTRY, HERE_CFA, 0, ALIGN_ENTRY
        CODEPTR HERE_CODE
        PUBLIC  HERE_CODE
        .a16
        .i16
                PHY
                LDY     #U_DP
                LDA     (UP),Y          ; Fetch DP
                PLY
                DEX
                DEX
                STA     0,X
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; ALLOT ( n -- ) advance dictionary pointer by n bytes
;------------------------------------------------------------------------------
        HEADER  "ALLOT", ALLOT_ENTRY, ALLOT_CFA, 0, HERE_ENTRY
        CODEPTR ALLOT_CODE
        PUBLIC  ALLOT_CODE
        .a16
        .i16
                PHY
                LDY     #U_DP
                LDA     (UP),Y          ; Fetch DP indirect
                CLC
                ADC     0,X             ; Advance to DP + n
                STA     (UP),Y          ; Store new DP
                PLY
                INX                     ; Drop n
                INX
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; BUFFER: ( u "name" -- ) create a buffer of u bytes
;------------------------------------------------------------------------------
        HEADER  "BUFFER:", BUFFERCOL_ENTRY, BUFFERCOL_CFA, 0, ALLOT_ENTRY
        CODEPTR DOCOL
        .word   CREATE_CFA
        .word   ALLOT_CFA
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; , ( val -- ) compile cell into dictionary
;------------------------------------------------------------------------------
        HEADER  ",", COMMA_ENTRY, COMMA_CFA, 0, BUFFERCOL_ENTRY
        CODEPTR COMMA_CODE
        PUBLIC  COMMA_CODE
        .a16
        .i16
                PHY
                LDY     #U_DP
                LDA     (UP),Y          ; DP → SCRATCH0
                STA     SCRATCH0
                CLC                     ; DP += CELL_SIZE
                ADC     #CELL_SIZE
                STA     (UP),Y          ; Write updated DP back
                LDA     0,X             ; Pop val off parameter stack
                INX
                INX
                STA     (SCRATCH0)      ; Store val at DP
                PLY
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; C, ( byte -- ) compile byte into dictionary
;------------------------------------------------------------------------------
        HEADER  "C,", CCOMMA_ENTRY, CCOMMA_CFA, 0, COMMA_ENTRY
        CODEPTR CCOMMA_CODE
        PUBLIC  CCOMMA_CODE
        .a16
        .i16
                PHY
                LDY     #U_DP
                LDA     (UP),Y          ; DP → SCRATCH1
                STA     SCRATCH1
                INC     A               ; DP += 1
                STA     (UP),Y          ; Write updated DP back
                LDA     0,X             ; Pop byte off parameter stack
                INX
                INX
                SEP     #$20
                .a8
                STA     (SCRATCH1)      ; Store byte at DP pointer
                REP     #$20
                .a16
                PLY
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; CURDEF ( -- addr ) address of current definition pointer in user area.
;------------------------------------------------------------------------------
        HEADER  "CURDEF", CURDEF_ENTRY, CURDEF_CFA, 0, CCOMMA_ENTRY
        CODEPTR CURDEF_CODE
        PUBLIC  CURDEF_CODE
        .a16
        .i16
                LDA     UP
                CLC
                ADC     #U_CURDEF
                DEX
                DEX
                STA     0,X
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; DP ( -- addr ) address of DP variable in user area
;------------------------------------------------------------------------------
        HEADER  "DP", DP_ENTRY, DP_CFA, 0, CURDEF_ENTRY
        CODEPTR DP_CODE
        PUBLIC  DP_CODE
        .a16
        .i16
                LDA     UP
                CLC
                ADC     #U_DP
                DEX
                DEX
                STA     0,X
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; LATEST ( -- addr ) address of LATEST variable in user area
;------------------------------------------------------------------------------
        HEADER  "LATEST", LATEST_ENTRY, LATEST_CFA, 0, DP_ENTRY
        CODEPTR LATEST_CODE
        PUBLIC  LATEST_CODE
        .a16
        .i16
                LDA     UP
                CLC
                ADC     #U_LATEST
                DEX
                DEX
                STA     0,X
                NEXT
        ENDPUBLIC

;==============================================================================
; SECTION 10: USER AREA ACCESSORS
;==============================================================================

;------------------------------------------------------------------------------
; BASE ( -- addr ) address of BASE variable
;------------------------------------------------------------------------------
        HEADER  "BASE", BASE_ENTRY, BASE_CFA, 0, LATEST_ENTRY
        CODEPTR BASE_CODE
        PUBLIC  BASE_CODE
        .a16
        .i16
                LDA     UP
                CLC
                ADC     #U_BASE
                DEX
                DEX
                STA     0,X
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; STATE ( -- addr ) address of STATE variable
;------------------------------------------------------------------------------
        HEADER  "STATE", STATE_ENTRY, STATE_CFA, 0, BASE_ENTRY
        CODEPTR STATE_CODE
        PUBLIC  STATE_CODE
        .a16
        .i16
                LDA     UP
                CLC
                ADC     #U_STATE
                DEX
                DEX
                STA     0,X
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; >IN ( -- addr ) address of >IN variable
;------------------------------------------------------------------------------
        HEADER  ">IN", TOIN_ENTRY, TOIN_CFA, 0, STATE_ENTRY
        CODEPTR TOIN_CODE
        PUBLIC  TOIN_CODE
        .a16
        .i16
                LDA     UP
                CLC
                ADC     #U_TOIN
                DEX
                DEX
                STA     0,X
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; SOURCE ( -- addr len ) current input source
;------------------------------------------------------------------------------
        HEADER  "SOURCE", SOURCE_ENTRY, SOURCE_CFA, 0, TOIN_ENTRY
        CODEPTR SOURCE_CODE
        PUBLIC  SOURCE_CODE
        .a16
        .i16
                PHY
                ; Push TIB address
                LDY     #U_TIB
                LDA     (UP),Y
                DEX
                DEX
                STA     0,X
                ; Push source length
                LDY     #U_SOURCELEN
                LDA     (UP),Y
                DEX
                DEX
                STA     0,X
                PLY
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; #TIB ( -- addr ) address of source length variable
;------------------------------------------------------------------------------
        HEADER  "#TIB", HASHTIB_ENTRY, HASHTIB_CFA, 0, SOURCE_ENTRY
        CODEPTR HASHTIB_CODE
        PUBLIC  HASHTIB_CODE
        .a16
        .i16
                LDA     UP
                CLC
                ADC     #U_SOURCELEN
                DEX
                DEX
                STA     0,X
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; 'TIB ( -- addr ) address of TIB pointer variable
;------------------------------------------------------------------------------
        HEADER  "'TIB", TICKTIB_ENTRY, TICKTIB_CFA, 0, HASHTIB_ENTRY
        CODEPTR TICKTIB_CODE
        PUBLIC  TICKTIB_CODE
        .a16
        .i16
                LDA     UP
                CLC
                ADC     #U_TIB
                DEX
                DEX
                STA     0,X
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; PAD ( -- addr ) address of scratch pad area.
;------------------------------------------------------------------------------
        HEADER  "PAD", PAD_ENTRY, PAD_CFA, 0, TICKTIB_ENTRY
        CODEPTR PAD_CODE
        PUBLIC  PAD_CODE
        .a16
        .i16
                PHY
                LDY     #U_PAD
                LDA     (UP),Y
                DEX
                DEX
                STA     0,X
                PLY
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; HLD ( -- addr ) pointer within the scratch pad area.
;------------------------------------------------------------------------------
        HEADER  "HLD", HLD_ENTRY, HLD_CFA, 0, PAD_ENTRY
        CODEPTR HLD_CODE
        PUBLIC  HLD_CODE
        .a16
        .i16
                LDA     UP
                CLC
                ADC     #U_HLD
                DEX
                DEX
                STA     0,X
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; CHECKPOINT ( -- ) save DP and LATEST for definition rollback
;------------------------------------------------------------------------------
        HEADER  "CHECKPOINT", CHECKPOINT_ENTRY, CHECKPOINT_CFA, 0, HLD_ENTRY
        CODEPTR CHECKPOINT_CODE
        PUBLIC  CHECKPOINT_CODE
        .a16
        .i16
                JSR     CHECKPOINT_IMPL
                NEXT
        ENDPUBLIC

        .proc CHECKPOINT_IMPL
        .a16
        .i16
                PHY                     ; save IP
                LDY     #U_DP
                LDA     (UP),Y
                LDY     #U_SAVEDP
                STA     (UP),Y          ; SAVE-DP = DP

                LDY     #U_LATEST
                LDA     (UP),Y
                LDY     #U_SAVELATEST
                STA     (UP),Y          ; SAVE-LATEST = LATEST
                PLY                     ; restore IP
                RTS
        .endproc

;------------------------------------------------------------------------------
; ROLLBACK ( -- ) restore DP and LATEST from checkpoint, clear checkpoint
; No-op if no checkpoint is active (SAVE-DP = 0)
;------------------------------------------------------------------------------
        HEADER  "ROLLBACK", ROLLBACK_ENTRY, ROLLBACK_CFA, 0, CHECKPOINT_ENTRY
        CODEPTR ROLLBACK_CODE
        PUBLIC  ROLLBACK_CODE
        .a16
        .i16
                JSR     ROLLBACK_IMPL
                NEXT
        ENDPUBLIC

        .proc ROLLBACK_IMPL
        .a16
        .i16
                PHY                     ; save IP
                LDY     #U_SAVEDP
                LDA     (UP),Y
                BEQ     @done           ; no checkpoint active

                LDY     #U_DP
                STA     (UP),Y          ; DP = SAVE-DP

                LDY     #U_SAVELATEST
                LDA     (UP),Y
                LDY     #U_LATEST
                STA     (UP),Y          ; LATEST = SAVE-LATEST

                LDA     #0
                LDY     #U_SAVEDP
                STA     (UP),Y
                LDY     #U_SAVELATEST
                STA     (UP),Y
@done:
                PLY                     ; restore IP
                RTS
        .endproc

;------------------------------------------------------------------------------
; COMMIT ( -- ) clear checkpoint after successful definition
;------------------------------------------------------------------------------
        HEADER  "COMMIT", COMMIT_ENTRY, COMMIT_CFA, 0, ROLLBACK_ENTRY
        CODEPTR COMMIT_CODE
        PUBLIC  COMMIT_CODE
        .a16
        .i16
                PHY
                LDA     #0
                LDY     #U_SAVEDP
                STA     (UP),Y
                LDY     #U_SAVELATEST
                STA     (UP),Y
                PLY
                NEXT
        ENDPUBLIC

;==============================================================================
; SECTION 11: STRING AND PARSE WORDS
;==============================================================================

;------------------------------------------------------------------------------
; COUNT ( addr -- addr+1 len ) counted string to addr/len
;------------------------------------------------------------------------------
        HEADER  "COUNT", COUNT_ENTRY, COUNT_CFA, 0, HLD_ENTRY
        CODEPTR COUNT_CODE
        PUBLIC  COUNT_CODE
        .a16
        .i16
                LDA     0,X             ; Copy addr to scratch pointer
                STA     SCRATCH0
                SEP     #$20            ; Enter byte transfer mode
                .a8
                LDA     (SCRATCH0)      ; Length byte is at start of string
                REP     #$20
                .a16
                AND     #$00FF          ; Mask off B part of accumulator
                INC     0,X             ; addr+1 on TOS (in place, no load/store)
                DEX
                DEX
                STA     0,X             ; Push length
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; (S") runtime ( -- c-addr u )
; IP points to length cell followed by string bytes.
; Pushes c-addr and u, advances IP past string data.
;------------------------------------------------------------------------------
DOSQUOTE_ENTRY:
        .word   COUNT_ENTRY            ; Link field
        .byte   F_HIDDEN | 4           ; Flags + length (4 chars)
        .byte   "(S", $22, ")"         ; '(' 'S' '"' ')'
        .align  2
DOSQUOTE_CFA:
        CODEPTR DOSQUOTE_CODE
        PUBLIC  DOSQUOTE_CODE
        .a16
        .i16
                LDA     0,Y             ; fetch u
                STA     SCRATCH0        ; save u
                INY
                INY                     ; IP -> first char

                DEX
                DEX
                TYA
                STA     a:0,X           ; push c-addr = IP

                DEX
                DEX
                LDA     SCRATCH0        ; restore u
                STA     a:0,X           ; push u

                ; Advance IP past string: IP + u, aligned to even
                TYA                     ; A = IP (c-addr)
                CLC
                ADC     SCRATCH0        ; IP + u
                INC     A               ; round up
                AND     #$FFFE          ; align to even
                TAY                     ; IP updated
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; S" ( " test\"" -- c-addr u ) parses string terminated by a quote in input
; buffer and returns a a pointer and character count.
;------------------------------------------------------------------------------
SQUOTE_ENTRY:
        .word   DOSQUOTE_ENTRY          ; Link field
        .byte   F_IMMEDIATE | 2         ; Flags + length (2 chars)
        .byte   "S", $22                ; 'S' '"'
        .align  2
SQUOTE_CFA:
        CODEPTR DOCOL

        ; --- parse the string (both modes need it) ---
        .word   LIT_CFA
        .word   '"'
        .word   PARSE_CFA               ; ( c-addr u )
        ; --- check STATE ---
        .word   STATE_CFA
        .word   FETCH_CFA
        .word   ZBRANCH_CFA
        .word   SQUOTE_INTERP

        ; --- compile mode ---
        .word   LIT_CFA
        .word   DOSQUOTE_CFA
        .word   COMMA_CFA               ; compile (S")
        .word   TWODUP_CFA              ; ( c-addr u c-addr u )
        .word   NIP_CFA                 ; ( c-addr u u )
        .word   COMMA_CFA               ; compile u as length cell
                                        ; ( c-addr u )
        .word   ZERO_CFA
        .word   DODO_CFA                ; runtime DO  ( limit index -- )
        .word   0                       ; unused leave target
SQUOTE_CLOOP:
        .word   DUP_CFA
        .word   I_CFA
        .word   PLUS_CFA
        .word   CFETCH_CFA
        .word   CCOMMA_CFA
        .word   DOLOOP_CFA
        .word   SQUOTE_CLOOP
        .word   DROP_CFA
        .word   ALIGN_CFA
        .word   EXIT_CFA

        ; --- interpret mode ---
SQUOTE_INTERP:                          ; ( c-addr u )
        .word   TWODUP_CFA              ; ( c-addr u c-addr u )
        .word   PAD_CFA                 ; ( c-addr u c-addr u pad )
        .word   ROT_CFA                 ; ( c-addr u u pad c-addr )
        .word   SWAP_CFA                ; ( c-addr u u c-addr pad )
        .word   ROT_CFA                 ; ( c-addr u c-addr pad u )
        .word   MOVE_CFA                ; ( c-addr u )
        .word   NIP_CFA                 ; ( u )
        .word   PAD_CFA                 ; ( u pad )
        .word   SWAP_CFA                ; ( pad u )
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; (.") ( -- )
; Runtime code for ."
;------------------------------------------------------------------------------
DODOTQUOTE_ENTRY:
        .word   SQUOTE_ENTRY            ; Link field
        .byte   F_HIDDEN | 3            ; Flags + length (3 chars)
        .byte   $28, $2E, $22           ; '(' '.' '"'
        .align  2
DODOTQUOTE_CFA:
        CODEPTR DODOTQUOTE_CODE
        PUBLIC  DODOTQUOTE_CODE
        .a16
        .i16
                ; Y = IP, points to length cell inline in caller's thread
                LDA     0,Y             ; fetch u
                STA     SCRATCH0        ; save u
                INY
                INY                     ; IP now points to first char byte

                ; Push ( c-addr u ) then call TYPE
                DEX
                DEX
                TYA
                STA     a:0,X           ; push c-addr = IP

                DEX
                DEX
                LDA     SCRATCH0
                STA     a:0,X           ; push u

                ; Advance IP past string bytes, aligned to even
                TYA                     ; A = IP
                CLC
                ADC     SCRATCH0        ; IP + u
                INC     A               ; round up
                AND     #$FFFE          ; align to even
                TAY                     ; IP updated

                ; Call TYPE via trampoline
                PHY                     ; save updated IP
                LDY     #RTS_CFA_LIST
                JSR     TYPE_CODE
                PLY                     ; restore IP
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; ." ( " test\"" -- ) parses text in the input buffer and outputs to console.
; https://forth-standard.org/standard/core/Dotq
;------------------------------------------------------------------------------
DOTQUOTE_ENTRY:
        .word   DODOTQUOTE_ENTRY        ; Link field
        .byte   F_IMMEDIATE | 2         ; Flags + length (2 chars)
        .byte   $2E, $22                ; ."
        .align  2
DOTQUOTE_CFA:
        CODEPTR DOCOL

        ; --- parse the string (both modes need it) ---
        .word   LIT_CFA
        .word   '"'
        .word   PARSE_CFA               ; ( c-addr u )

        ; --- check STATE ---
        .word   STATE_CFA
        .word   FETCH_CFA
        .word   ZBRANCH_CFA
        .word   DOTQUOTE_INTERP

        ; --- compile mode ---
        .word   LIT_CFA
        .word   DODOTQUOTE_CFA          ; compile (.")
        .word   COMMA_CFA
        .word   TWODUP_CFA              ; ( c-addr u c-addr u )
        .word   NIP_CFA                 ; ( c-addr u u )
        .word   COMMA_CFA               ; compile u
        .word   ZERO_CFA
        .word   DODO_CFA                ; loop u times
        .word   0                       ; unused leave target
DOTQUOTE_CLOOP:
        .word   DUP_CFA
        .word   I_CFA
        .word   PLUS_CFA
        .word   CFETCH_CFA
        .word   CCOMMA_CFA
        .word   DOLOOP_CFA
        .word   DOTQUOTE_CLOOP
        .word   DROP_CFA
        .word   ALIGN_CFA
        .word   EXIT_CFA

        ; --- interpret mode ---
DOTQUOTE_INTERP:                        ; ( c-addr u )
        .word   TYPE_CFA                ; print string directly
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; (ABORT") ( i * x x1 -- | i * x ) ( R: j * x -- | j * x )
; POP x1 and if any bit is not zero, display the msg and perform an abort
; sequence that includes the function of ABORT.
; https://forth-standard.org/standard/core/ABORTq
;------------------------------------------------------------------------------
DOABORTQUOTE_ENTRY:
        .word   DOTQUOTE_ENTRY          ; Link field
        .byte   F_HIDDEN | 8            ; Flags + length (7 chars)
        .byte   "(ABORT", $22, ")"      ; (ABORT")
        .align  2
DOABORTQUOTE_CFA:
        CODEPTR DOABORTQUOTE_CODE
        PUBLIC  DOABORTQUOTE_CODE
        .a16
        .i16
                ; Pop flag
                LDA     a:0,X
                INX
                INX

                ; If false skip over inline string
                CMP     #0
                BEQ     @skip

                ; True: fetch u from inline string header
                LDA     0,Y             ; fetch u
                STA     SCRATCH0        ; save u
                INY
                INY                     ; IP -> first char

                ; Push ( c-addr u )
                DEX
                DEX
                TYA
                STA     a:0,X           ; c-addr = IP

                DEX
                DEX
                LDA     SCRATCH0
                STA     a:0,X           ; u

                ; Advance IP past string bytes, aligned to even
                TYA                     ; A = IP
                CLC
                ADC     SCRATCH0        ; IP + u
                INC     A               ; round up
                AND     #$FFFE          ; align to even
                TAY                     ; IP updated

                ; Print string via TYPE trampoline
                PHY                     ; save updated IP
                LDY     #RTS_CFA_LIST
                JSR     TYPE_CODE
                PLY                     ; restore IP (not strictly needed)

                ; Print newline
                LDA     #C_RETURN
                JSR     hal_putch
                LDA     #L_FEED
                JSR     hal_putch

                ; ABORT never returns
                JMP     ABORT_CODE

@skip:
                ; Skip over inline string
                LDA     0,Y             ; fetch u
                STA     SCRATCH0
                INY
                INY                     ; past length cell
                TYA
                CLC
                ADC     SCRATCH0        ; IP + u
                INC     A               ; round up
                AND     #$FFFE          ; align to even
                TAY
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; ABORTQ Compilation: ( "msg<quote>" -- )
; Parse the msg delimited by a ". Append the run-time semantics given below to
; the current definition.
; Run-time: ( i * x x1 -- | i * x ) ( R: j * x -- | j * x )
; POP x1 and if any bit is not zero, display the msg and perform an abort
; sequence that includes the function of ABORT.
; https://forth-standard.org/standard/core/ABORTq
;------------------------------------------------------------------------------
ABORTQUOTE_ENTRY:
        .word   DOABORTQUOTE_ENTRY      ; Link field
        .byte   F_IMMEDIATE | 6         ; Flags + length (6 chars)
        .byte   "ABORT", $22            ; ABORT"
        .align  2
ABORTQUOTE_CFA:
        CODEPTR DOCOL
        .word   STATE_CFA
        .word   FETCH_CFA
        .word   ZEROEQ_CFA              ; true if interpreting
        .word   ZBRANCH_CFA
        .word   ABORTQUOTE_COMPILE      ; skip error if compiling
        .word   COMPILE_ONLY_ERROR_CFA  ; a specific error
ABORTQUOTE_COMPILE:
        .word   LIT_CFA
        .word   '"'
        .word   PARSE_CFA               ; ( c-addr u )
        .word   LIT_CFA
        .word   DOABORTQUOTE_CFA        ; compile (ABORT")
        .word   COMMA_CFA
        .word   TWODUP_CFA              ; ( c-addr u c-addr u )
        .word   NIP_CFA                 ; ( c-addr u u )
        .word   COMMA_CFA               ; compile u
        .word   ZERO_CFA
        .word   DODO_CFA                ; U 0 DO
        .word   0                       ; unused leave target
ABORTQUOTE_CLOOP:
        .word   DUP_CFA
        .word   I_CFA
        .word   PLUS_CFA
        .word   CFETCH_CFA              ; fetch the character a I
        .word   CCOMMA_CFA              ; compile it into the definition
        .word   DOLOOP_CFA
        .word   ABORTQUOTE_CLOOP
        .word   DROP_CFA
        .word   ALIGN_CFA               ; word align the definition
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; .( "text" ) Parse and display the text delimited by .( and )
; https://forth-standard.org/standard/core/Dotp
;------------------------------------------------------------------------------
        HEADER  ".(", DOTPAREN_ENTRY, DOTPAREN_CFA, F_IMMEDIATE, ABORTQUOTE_ENTRY
        CODEPTR DOCOL
        .word   LIT_CFA
        .word   ')'
        .word   PARSE_CFA               ; ( c-addr u ) raw, no uppercasing
        .word   TYPE_CFA                ; ( c-addr ) discard length
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; CHAR ( "<spaces>name" -- char ) skip leading space delimiters. Parse name
; delimited by a space. Put the value of its first character onto the stack.
; https://forth-standard.org/standard/core/CHAR
;------------------------------------------------------------------------------
        HEADER  "CHAR", CHAR_ENTRY, CHAR_CFA, 0, DOTPAREN_ENTRY
        CODEPTR DOCOL
        .word   BL_CFA
        .word   PARSE_CFA               ; ( c-addr u ) raw, no uppercasing
        .word   DROP_CFA                ; ( c-addr ) discard length
        .word   CFETCH_CFA              ; ( char ) first character
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; CHARS ( n -- n ) NOP on byte addressed system.
; https://forth-standard.org/standard/core/CHARS
;------------------------------------------------------------------------------
        HEADER  "CHARS", CHARS_ENTRY, CHARS_CFA, 0, CHAR_ENTRY
        CODEPTR DOCOL
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; CHAR+ ( c-addr -- c-addr+1 ) add the size in address units of a character
; to c-addr. This is a byte addressed ASCII only Forth, so that's 1.
; https://forth-standard.org/standard/core/CHARPlus
;------------------------------------------------------------------------------
        HEADER  "CHAR+", CHARPLUS_ENTRY, CHARPLUS_CFA, 0, CHARS_ENTRY
        CODEPTR DOCOL
        .word   ONEPLUS_CFA
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; [CHAR] Compilation: ( "<spaces>name" -- )
; Skip leading space delimiters. Parse name delimited by a space. Append the
; run-time semantics given below to the current definition.
; Run-time: ( -- char )
; Place char, the value of the first character of name, on the stack.
; https://forth-standard.org/standard/core/BracketCHAR
;------------------------------------------------------------------------------
        HEADER  "[CHAR]", BRACKCHAR_ENTRY, BRACKCHAR_CFA, F_IMMEDIATE, CHARPLUS_ENTRY
        CODEPTR DOCOL
        .word   CHAR_CFA                ; ( char )
        .word   LITERAL_CFA
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; BL ( -- ' ' )
; https://forth-standard.org/standard/core/BL
;------------------------------------------------------------------------------
        HEADER  "BL", BL_ENTRY, BL_CFA, 0, BRACKCHAR_ENTRY
        CODEPTR DOCOL
        .word   LIT_CFA
        .word   ' '
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; CELL ( -- 2 )
;------------------------------------------------------------------------------
        HEADER  "CELL", CELL_ENTRY, CELL_CFA, 0, BL_ENTRY
        CODEPTR DOCOL
        .word   LIT_CFA
        .word   CELL_SIZE
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; CELLS ( n -- 2 * n )
;------------------------------------------------------------------------------
        HEADER  "CELLS", CELLS_ENTRY, CELLS_CFA, 0, CELL_ENTRY
        CODEPTR DOCOL
        .word   LIT_CFA
        .word   CELL_SIZE
        .word   STAR_CFA
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; CELL+ ( a-addr1 -- a-addr2 ) Add the size in address units of a cell to
; a-addr1, giving a-addr2.
;------------------------------------------------------------------------------
        HEADER  "CELL+", CELLPLUS_ENTRY, CELLPLUS_CFA, 0, CELLS_ENTRY
        CODEPTR DOCOL
        .word   LIT_CFA
        .word   CELL_SIZE
        .word   PLUS_CFA
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; SKIP-CHAR ( char -- ) scans the TIB skipping instances of char and updates
; TOIN in the user area.
;------------------------------------------------------------------------------
        HEADER  "SKIP-CHAR", SKIPCHAR_ENTRY, SKIPCHAR_CFA, 0, CELLPLUS_ENTRY
        CODEPTR SKIPCHAR_CODE
        PUBLIC  SKIPCHAR_CODE
        .a16
        .i16
                PHY

                ; Cache TIB base
                LDY     #U_TIB
                LDA     (UP),Y
                STA     SCRATCH0

                ; Cache source length
                LDY     #U_SOURCELEN
                LDA     (UP),Y
                STA     SCRATCH1

                ; Load >IN
                LDY     #U_TOIN
                LDA     (UP),Y
                TAY

                SEP     #$20
                .a8
@skip_loop:
                CPY     SCRATCH1        ; >IN >= source length?
                BCS     @done           ; end of input

                ; Fetch char at scan pointer
                LDA     (SCRATCH0),Y
                CMP     0,X             ; matches delimiter?
                BNE     @done           ; no → stop skipping

                INY                     ; >IN++
                BRA     @skip_loop
@done:
                REP     #$20            ; Ensure 16-bit accumulator
                .a16

                ; Write updated >IN back to user area
                TYA
                LDY     #U_TOIN
                STA     (UP),Y

                INX                     ; Drop char from parameter stack
                INX
                PLY
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; PLACE ( c-addr u dest -- ) copy addr/len string to dest as counted string
; with uppercase conversion.
;------------------------------------------------------------------------------
        HEADER  "PLACE", PLACE_ENTRY, PLACE_CFA, 0, SKIPCHAR_ENTRY
        CODEPTR PLACE_CODE
        PUBLIC  PLACE_CODE
        .a16
        .i16
                LOC_SRC     = 1         ; source address
                LOC_COUNT   = 3         ; character count
                LOC_DEST    = 5         ; destination address

                PHY

                LDA     0,X             ; dest (TOS)
                PHA                     ; LOC_DEST
                LDA     2,X             ; u (NOS)
                PHA                     ; LOC_COUNT
                LDA     4,X             ; c-addr (3OS)
                PHA                     ; LOC_SRC

                ; drop all three params from parameter stack
                INX
                INX
                INX
                INX
                INX
                INX

                ; Store count byte at dest
                LDY     #0
                LDA     LOC_COUNT,S
                SEP     #$20
                .a8
                STA     (LOC_DEST,S),Y  ; count byte at dest+0
                REP     #$20
                .a16

                ; Advance dest to dest+1 for char copy
                LDA     LOC_DEST,S
                INC     A
                STA     LOC_DEST,S

                SEP     #$20
                .a8
@copy_loop:
                TYA
                CMP     LOC_COUNT,S
                BCS     @done

                LDA     (LOC_SRC,S),Y   ; fetch src char
                ; Uppercase conversion
                CMP     #'a'
                BCC     @not_lower
                CMP     #'z'+1
                BCS     @not_lower
                AND     #$DF
@not_lower:
                STA     (LOC_DEST,S),Y  ; store to dest+1+Y
                INY
                BRA     @copy_loop

@done:
                REP     #$20
                .a16
                PLA                     ; drop LOC_SRC
                PLA                     ; drop LOC_COUNT
                PLA                     ; drop LOC_DEST
                PLY
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; PARSE ( char -- c-addr u )
;------------------------------------------------------------------------------
        HEADER  "PARSE", PARSE_ENTRY, PARSE_CFA, 0, PLACE_ENTRY
        CODEPTR PARSE_CODE
        PUBLIC  PARSE_CODE
        .a16
        .i16

        LOC_CHAR    = 1         ; delimiter char
        LOC_TIB     = 3         ; TIB base address
        LOC_TOIN    = 5         ; >IN at entry
        LOC_CURPTR  = 7         ; current scan pointer
        LOC_ENDADDR = 9         ; TIB + SOURCE-LEN
        LOC_UP      = 11        ; cached UP
        LOC_SIZE    = LOC_UP + 1

                PHD
                PHY

                TSC
                SEC
                SBC     #LOC_SIZE
                TCS
                TCD

                ;--------------------------------------------------------------
                ; Peek delimiter
                ;--------------------------------------------------------------
                LDA     a:0,X
                AND     #$00FF
                STA     LOC_CHAR

                ;--------------------------------------------------------------
                ; Cache UP, then load TIB, >IN, SOURCE-LEN
                ;--------------------------------------------------------------
                LDA     a:UP
                STA     LOC_UP

                LDY     #U_TIB
                LDA     (LOC_UP),Y
                STA     LOC_TIB

                LDY     #U_TOIN
                LDA     (LOC_UP),Y
                STA     LOC_TOIN

                ; CURPTR = TIB + >IN
                LDA     LOC_TIB
                CLC
                ADC     LOC_TOIN
                STA     LOC_CURPTR

                ; ENDADDR = TIB + SOURCE-LEN
                LDY     #U_SOURCELEN
                LDA     (LOC_UP),Y
                CLC
                ADC     LOC_TIB
                STA     LOC_ENDADDR

                ;--------------------------------------------------------------
                ; Scan loop
                ;--------------------------------------------------------------
@scan_loop:
                LDA     LOC_CURPTR
                CMP     LOC_ENDADDR
                BCS     @end_of_input

                ; Fetch char at CURPTR
                SEP     #$20
                .a8
                LDA     (LOC_CURPTR)    ; fetch byte
                REP     #$20
                .a16
                AND     #$00FF

                CMP     LOC_CHAR
                BEQ     @found

                INC     LOC_CURPTR
                BRA     @scan_loop

@found:
                INC     LOC_CURPTR      ; advance past delimiter
                ; u = CURPTR - 1 - (TIB + TOIN)
                LDA     LOC_CURPTR
                DEC     A               ; ptr before delimiter
                SEC
                SBC     LOC_TIB
                SEC
                SBC     LOC_TOIN     ; u = offset from TIB+TOIN
                BRA     @update_in

@end_of_input:
                ; u = SOURCE-LEN - TOIN = ENDADDR - TIB - STARTIN
                LDA     LOC_ENDADDR
                SEC
                SBC     LOC_TIB
                SEC
                SBC     LOC_TOIN

@update_in:
                PHA                     ; save u

                ; Write CURPTR back as >IN offset: >IN = CURPTR - TIB
                LDA     LOC_CURPTR
                SEC
                SBC     LOC_TIB
                LDY     #U_TOIN
                STA     (LOC_UP),Y

                ; c-addr = TIB + STARTIN
                LDA     LOC_TIB
                CLC
                ADC     LOC_TOIN

                STA     a:0,X           ; overwrite TOS with c-addr

                PLA                     ; restore u
                DEX
                DEX
                STA     a:0,X           ; push u (TOS)

                TSC
                CLC
                ADC     #LOC_SIZE
                TCS
                PLY
                PLD
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; PARSE-NAME ( "<spaces>name<space>" -- c-addr u )
; https://forth-standard.org/standard/core/PARSE-NAME
;------------------------------------------------------------------------------
        HEADER  "PARSE-NAME", PARSENAME_ENTRY, PARSENAME_CFA, 0, PARSE_ENTRY
        CODEPTR DOCOL
        .word   BL_CFA
        .word   SKIPCHAR_CFA            ; skip leading spaces
        .word   BL_CFA
        .word   PARSE_CFA               ; parse space-delimited token
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; WORD ( char -- addr ) parse word delimited by char from input
; Returns counted string at HERE
;------------------------------------------------------------------------------
	HEADER  "WORD", WORD_ENTRY, WORD_CFA, 0, PARSENAME_ENTRY
        CODEPTR DOCOL
        .word   DUP_CFA                 ; ( char char )
        .word   SKIPCHAR_CFA            ; skip leading delimiters
        .word   PARSE_CFA               ; ( char -- c-addr u )
        .word   HERE_CFA                ; ( c-addr u here )
        .word   PLACE_CFA               ; ( ) copy to HERE as counted string
        .word   HERE_CFA                ; ( here )
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; \ ( -- ) consumes all input to the end of line.
;------------------------------------------------------------------------------
        HEADER  "\", BACKSLASH_ENTRY, BACKSLASH_CFA, F_IMMEDIATE, WORD_ENTRY
        CODEPTR DOCOL
        .word   SOURCE_CFA              ; ( c-addr u )
        .word   NIP_CFA                 ; ( u )
        .word   TOIN_CFA                ; ( u &>IN )
        .word   STORE_CFA               ; >IN = u
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; { ( -- ) consumes all input until )
;------------------------------------------------------------------------------
	HEADER  "(", PAREN_ENTRY, PAREN_CFA, F_IMMEDIATE, BACKSLASH_ENTRY
        CODEPTR DOCOL
        .word   LIT_CFA
        .word   ')'
        .word   PARSE_CFA               ; ( c-addr u )
        .word   TWODROP_CFA             ; discard
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; DECIMAL ( -- ) set numeric base to 10
;------------------------------------------------------------------------------
        HEADER  "DECIMAL", DECIMAL_ENTRY, DECIMAL_CFA, 0, PAREN_ENTRY
        CODEPTR DOCOL
DECIMAL_BODY:
        .word   LIT_CFA
        .word   10
        .word   BASE_CFA
        .word   STORE_CFA
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; HEX ( -- ) set numeric base to 16
;------------------------------------------------------------------------------
        HEADER  "HEX", HEX_ENTRY, HEX_CFA, 0, DECIMAL_ENTRY
        CODEPTR DOCOL
HEX_BODY:
        .word   LIT_CFA
        .word   16
        .word   BASE_CFA
        .word   STORE_CFA
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; >NUMBER ( ud c-addr u -- ud c-addr u )
; Converts as many characters as possible from string into ud accumulator.
; Stops at first unconvertible character or when u reaches zero.
; ud is a true 32-bit double: NOS2=ud_lo, NOS1=ud_hi (ANS convention).
;------------------------------------------------------------------------------
        HEADER  ">NUMBER", TONUMBER_ENTRY, TONUMBER_CFA, 0, HEX_ENTRY
        CODEPTR TONUMBER_CODE
        PUBLIC  TONUMBER_CODE
        .a16
        .i16
                JSR     TONUMBER_IMPL
                NEXT
        ENDPUBLIC

        .proc TONUMBER_IMPL
        LOC_U       = 1         ; character count
        LOC_ADDR    = 3         ; current char pointer
        LOC_UDHI    = 5         ; high cell of ud
        LOC_UDLO    = 7         ; low cell of ud
        LOC_BASE    = 9         ; cached BASE
        LOC_SIZE    = LOC_BASE + 1

                PHD
                PHY

                TSC
                SEC
                SBC     #LOC_SIZE
                TCS
                TCD

                ;--------------------------------------------------------------
                ; Cache BASE
                ;--------------------------------------------------------------
                LDA     a:UP
                STA     LOC_ADDR        ; borrow LOC_ADDR to hold UP temporarily
                LDY     #U_BASE
                LDA     (LOC_ADDR),Y
                STA     LOC_BASE

                ;--------------------------------------------------------------
                ; Load stack args into frame
                ; Stack on entry: ( ud_lo ud_hi c-addr u ) TOS=u
                ;--------------------------------------------------------------
                LDA     a:0,X           ; u
                STA     LOC_U
                LDA     a:2,X           ; c-addr
                STA     LOC_ADDR
                LDA     a:4,X           ; ud_hi
                STA     LOC_UDHI
                LDA     a:6,X           ; ud_lo
                STA     LOC_UDLO

                ;--------------------------------------------------------------
                ; Main conversion loop
                ;--------------------------------------------------------------
@digit_loop:
                LDA     LOC_U
                BNE     @skip
                JMP     @done           ; u = 0, done
@skip:
                ; Fetch character
                SEP     #$20
                .a8
                LDA     (LOC_ADDR)
                REP     #$20
                .a16
                AND     #$00FF

                ; Lowercase to uppercase conversion
                CMP     #'a'
                BCC     @not_lower
                CMP     #'z' + 1
                BCS     @not_lower
                AND     #$FFDF          ; clear bit 5 -> uppercase
@not_lower:
                ; Convert to digit value
                CMP     #'0'
                BCC     @done           ; < '0' -> stop
                CMP     #'9' + 1
                BCC     @is_decimal
                CMP     #'A'
                BCC     @done           ; between '9' and 'A' -> stop
                CMP     #'F' + 1
                BCS     @done           ; > 'F' -> stop
                SEC
                SBC     #'A' - 10       ; A->10 ... F->15
                BRA     @check_base
@is_decimal:
                SEC
                SBC     #'0'            ; '0'->0 ... '9'->9

@check_base:
                CMP     LOC_BASE
                BCS     @done           ; digit >= BASE -> stop

                ;--------------------------------------------------------------
                ; ud = ud * BASE + digit  (true 32-bit)
                ;
                ; Step 1: ud_lo * BASE via UM* -> (prod_lo prod_hi)
                ; Step 2: ud_hi * BASE via UM* -> low word only
                ; Step 3: prod_hi += ud_hi * BASE low word
                ; Step 4: prod_lo += digit, propagate carry into prod_hi
                ;--------------------------------------------------------------
                PHA                     ; save digit on hw stack
                ; --- Step 1: ud_lo * BASE via UM* ---
                LDA     LOC_UDLO
                DEX
                DEX
                STA     a:0,X           ; push ud_lo
                LDA     LOC_BASE
                DEX
                DEX
                STA     a:0,X           ; push BASE

                PHD
                LDA     #$0000
                TCD
                LDY     #RTS_CFA_LIST
                JSR     UMSTAR_CODE     ; ( prod_lo prod_hi )
                PLD                     ; D -> frame

                ; --- Step 2: ud_hi * BASE via UM* ---
                LDA     LOC_UDHI        ; D -> frame, safe to use LOC_ names
                DEX
                DEX
                STA     a:0,X           ; push ud_hi
                LDA     LOC_BASE
                DEX
                DEX
                STA     a:0,X           ; push BASE

                PHD
                LDA     #$0000
                TCD
                LDY     #RTS_CFA_LIST
                JSR     UMSTAR_CODE     ; ( prod_lo prod_hi ud_hi*BASE_lo ud_hi*BASE_hi )
                PLD                     ; D -> frame

                ; Discard ud_hi*BASE high word (ANS: no overflow beyond 32 bits)
                INX
                INX

                ; --- Step 3: prod_hi += ud_hi * BASE low word ---
                CLC
                LDA     a:0,X           ; ud_hi*BASE_lo (TOS)
                INX
                INX                     ; drop it
                ADC     a:0,X           ; prod_hi (now TOS)
                INX
                INX                     ; drop prod_hi
                STA     LOC_UDHI        ; store updated ud_hi into frame

                ; --- Step 4: prod_lo += digit ---
                PLA                     ; restore digit
                CLC
                ADC     a:0,X           ; prod_lo (now TOS)
                INX
                INX                     ; drop prod_lo
                STA     LOC_UDLO        ; store updated ud_lo into frame
                BCC     @no_carry
                INC     LOC_UDHI        ; carry from low into high
@no_carry:
                ; Advance pointer, decrement count
                INC     LOC_ADDR
                DEC     LOC_U
                JMP     @digit_loop

                ;--------------------------------------------------------------
                ; Done: write results back to parameter stack
                ; Stack on exit: ( ud_lo ud_hi c-addr u ) TOS=u
                ;--------------------------------------------------------------
@done:
                LDA     LOC_UDLO
                STA     a:6,X
                LDA     LOC_UDHI
                STA     a:4,X
                LDA     LOC_ADDR
                STA     a:2,X
                LDA     LOC_U
                STA     a:0,X

                TSC
                CLC
                ADC     #LOC_SIZE
                TCS
                PLY
                PLD
                RTS
        .endproc

;------------------------------------------------------------------------------
; NUMBER? ( c-addr -- n true | d_lo d_hi true | c-addr false )
; Handles prefixes: - (negative), $ (hex), # (decimal), % (binary)
; Trailing '.' marks a double literal: returns ( d_lo d_hi true ).
; Single number returns ( n true ).
; Failure returns ( c-addr false ).
; Restores BASE after conversion.
;------------------------------------------------------------------------------
        HEADER  "NUMBER?", NUMBERQ_ENTRY, NUMBERQ_CFA, 0, TONUMBER_ENTRY
        CODEPTR NUMBERQ_CODE
        PUBLIC  NUMBERQ_CODE
        .a16
        .i16

        LOC_ADDR     = 1        ; original c-addr (for fail return)
        LOC_PTR      = 3        ; current char pointer
        LOC_COUNT    = 5        ; remaining character count
        LOC_SIGN     = 7        ; 0=positive, $FFFF=negative
        LOC_BASE     = 9        ; saved original BASE
        LOC_TMPBASE  = 11       ; working base for this conversion
        LOC_UP       = 13       ; local UP to avoid refetching
        LOC_ISDOUBLE = 15       ; $FFFF if double (trailing '.'), 0 if single
        LOC_SIZE     = LOC_ISDOUBLE + 1

                PHD
                PHY

                TSC
                SEC
                SBC     #LOC_SIZE
                TCS
                TCD

                ;--------------------------------------------------------------
                ; Save original addr, load length, set up pointer
                ;--------------------------------------------------------------
                LDA     a:0,X           ; c-addr
                STA     LOC_ADDR
                INC     A               ; Advance ptr to first char
                STA     LOC_PTR

                SEP     #$20
                .a8
                LDA     (LOC_ADDR)      ; length byte
                REP     #$20
                .a16
                AND     #$00FF
                BNE     @has_chars
                JMP     @fail_return    ; empty string -> fail
@has_chars:
                STA     LOC_COUNT

                ;--------------------------------------------------------------
                ; Cache BASE, init working base, sign, double flag
                ;--------------------------------------------------------------
                LDA     a:UP
                STA     LOC_UP
                LDY     #U_BASE
                LDA     (LOC_UP),Y
                STA     LOC_BASE
                STA     LOC_TMPBASE
                STZ     LOC_SIGN
                STZ     LOC_ISDOUBLE

                ;--------------------------------------------------------------
                ; Check for '-' prefix
                ;--------------------------------------------------------------
                SEP     #$20
                .a8
                LDA     (LOC_PTR)
                REP     #$20
                .a16
                AND     #$00FF

                CMP     #'-'
                BNE     @check_dollar
                DEC     LOC_SIGN        ; -1 = FORTH_TRUE to mark negative
                INC     LOC_PTR
                DEC     LOC_COUNT
                BNE     @skip
                JMP     @fail_return    ; '-' alone is not valid
@skip:          SEP     #$20
                .a8
                LDA     (LOC_PTR)       ; peek next char for base prefix check
                REP     #$20
                .a16
                AND     #$00FF
@check_dollar:
                CMP     #'$'
                BNE     @check_hash
                LDA     #16
                STA     LOC_TMPBASE
                BRA     @advance_prefix

@check_hash:
                CMP     #'#'
                BNE     @check_percent
                LDA     #10
                STA     LOC_TMPBASE
                BRA     @advance_prefix

@check_percent:
                CMP     #'%'
                BNE     @no_prefix
                LDA     #2
                STA     LOC_TMPBASE

@advance_prefix:
                INC     LOC_PTR
                DEC     LOC_COUNT
                BNE     @no_prefix
                JMP     @fail_return    ; prefix alone is not valid
@no_prefix:
                ;--------------------------------------------------------------
                ; Check for trailing '.' (double literal marker).
                ; If the LAST character of the remaining string is '.',
                ; set IS_DOUBLE and reduce count by 1 to exclude it.
                ;--------------------------------------------------------------
                LDY     LOC_COUNT
                DEY                     ; index of last char
                SEP     #$20
                .a8
                LDA     (LOC_PTR),Y     ; fetch last char
                REP     #$20
                .a16
                AND     #$00FF
                CMP     #'.'
                BNE     @no_dot
                DEC     LOC_ISDOUBLE    ; -1 = FORTH_TRUE
                DEC     LOC_COUNT       ; exclude the '.' from conversion
                BEQ     @fail_return    ; '.' alone or prefix + '.' is invalid
@no_dot:
		;--------------------------------------------------------------
                ; Write working BASE into user area for >NUMBER
                ;--------------------------------------------------------------
                LDY     #U_BASE
                LDA     LOC_TMPBASE
                STA     (LOC_UP),Y

                ;--------------------------------------------------------------
                ; Set up stack for >NUMBER: ( 0 0 c-addr u )
                ; TOS=u, NOS=c-addr, NOS2=ud_hi=0, NOS3=ud_lo=0
                ;--------------------------------------------------------------
                LDA     #0
                STA     a:0,X           ; ud_lo (reuse existing TOS slot)
                DEX
                DEX
                STA     a:0,X           ; ud_hi
                LDA     LOC_PTR         ; c-addr (first digit)
                DEX
                DEX
                STA     a:0,X
                LDA     LOC_COUNT       ; u
                DEX
                DEX
                STA     a:0,X           ; TOS = u

                JSR     TONUMBER_IMPL   ; ( ud_lo ud_hi c-addr u )

                ;--------------------------------------------------------------
                ; Restore original BASE
                ;--------------------------------------------------------------
                LDY     #U_BASE
                LDA     LOC_BASE
                STA     (LOC_UP),Y

                ;--------------------------------------------------------------
                ; Check u = 0 (all chars consumed = success)
                ;--------------------------------------------------------------
                LDA     a:0,X           ; u remaining
                TAY
                INX                     ; drop u
                INX
                INX                     ; drop c-addr
                INX                     ; Stack now: ( ud_lo ud_hi )
                TYA
                BNE     @fail_cleanup   ; unconverted chars -> fail

                LDA     LOC_ISDOUBLE
                BNE     @apply_sign

                ; Single: ud_hi must be zero for a valid single-cell number.
                ; If ud_hi != 0 the number overflowed a cell -> fail.
                LDA     a:0,X           ; ud_hi
                BNE     @fail_overflow

@apply_sign:    LDA     LOC_SIGN        ; Apply sign to 32-bit result
                BEQ     @positive

                ; Negate 32-bit: invert both cells, add 1 to low cell
                LDA     a:2,X           ; ud_lo
                EOR     #$FFFF
                STA     a:2,X
                LDA     a:0,X           ; ud_hi
                EOR     #$FFFF
                STA     a:0,X
                INC     a:2,X           ; ud_lo + 1
                BNE     @positive
                INC     a:0,X           ; carry into ud_hi
@positive:
                ;--------------------------------------------------------------
                ; Return result
                ; Double: leave ( ud_lo ud_hi ) on stack, push TRUE
                ; Single: drop ud_hi, leave ud_lo, push TRUE
                ;--------------------------------------------------------------
                LDA     LOC_ISDOUBLE
                BNE     @return_double

                ; Drop ud_hi, leave ud_lo as n
                INX
                INX
                ; Fall through to load flag and return
@return_double:
                ; Stack: ( ud_lo ud_hi ) — leave as-is
                LDA     #FORTH_TRUE
                BRA     @return

@fail_overflow: ; Number too large for single cell but no '.' given -> fail.
@fail_cleanup:  ; >NUMBER left u non-zero. Drop ud_hi
                INX                     ; Drop both ud_hi cell
                INX
@fail_return:
                LDA     LOC_ADDR
                STA     a:0,X
                LDA     #FORTH_FALSE
@return:
                DEX
                DEX
                STA     a:0,X           ; push flag

                TSC
                CLC
                ADC     #LOC_SIZE
                TCS
                PLY
                PLD
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; NUMBER ( c-addr -- n )
; Calls NUMBER? and throws on failure.
;------------------------------------------------------------------------------
        HEADER  "NUMBER", NUMBER_ENTRY, NUMBER_CFA, 0, NUMBERQ_ENTRY
        CODEPTR DOCOL
        .word   NUMBERQ_CFA             ; ( n true | c-addr false )
        .word   ZBRANCH_CFA
        .word   NUMBER_ERR
        .word   EXIT_CFA
NUMBER_ERR:
        .word   UNDEFINED_WORD_CFA      ; or a more specific error

;------------------------------------------------------------------------------
; COMPARE
; On entry:  PSP (X) has 4 cells: u2 addr2 u1 addr1 (TOS first)
; On exit:   PSP (X) has 1 cell:  result
; see: https://forth-standard.org/standard/string/COMPARE
;------------------------------------------------------------------------------
        HEADER  "COMPARE", COMPARE_ENTRY, COMPARE_CFA, 0, NUMBER_ENTRY
        CODEPTR COMPARE_CODE
        PUBLIC  COMPARE_CODE
        .a16
        .i16

        LOC_ADDR1       = 1             ; hw stack offset for addr1
        LOC_ADDR2       = 3             ; hw stack offset for addr2
        ; saved IP lives at 5,S (pushed by PHY before the two PHAs)

                PHY                     ; Save IP; hw stack: [saved_IP]

                ;----------------------------------------------------------
                ; Pop all four arguments from the parameter stack.
                ; Save u1 -> TMPB, u2 -> SCRATCH1 for the length comparison
                ; after the byte loop. Both addresses go onto the hw stack
                ; as locals so (LOC,S),Y indirect indexed addressing works.
                ;----------------------------------------------------------
                LDA     0,X             ; u2
                STA     SCRATCH1        ; SCRATCH1 = u2 (preserved for length cmp)
                INX
                INX

                LDA     0,X             ; addr2
                INX
                INX
                PHA                     ; hw stack: [addr2][saved_IP]
                                        ; -> addr2 now at LOC_ADDR2 = 3,S

                LDA     0,X             ; u1
                STA     TMPB            ; TMPB = u1 (preserved for length cmp)
                INX
                INX

                LDA     0,X             ; addr1
                INX
                INX
                PHA                     ; hw stack: [addr1][addr2][saved_IP]
                                        ; -> addr1 now at LOC_ADDR1 = 1,S

                ;----------------------------------------------------------
                ; Compute MIN(u1, u2) -> TMPA (the byte-loop trip count).
                ; u1 is in TMPB, u2 is in SCRATCH1.
                ; CMP is unsigned - lengths are always non-negative.
                ;----------------------------------------------------------
                LDA     TMPB            ; u1
                CMP     SCRATCH1        ; unsigned: u1 - u2, sets C
                BCS     @min_is_u2      ; C set  -> u1 >= u2  -> min = u2
                STA     TMPA            ; C clear -> u1 <  u2  -> min = u1
                BRA     @loop_start
@min_is_u2:
                LDA     SCRATCH1        ; min = u2
                STA     TMPA

@loop_start:
                ;----------------------------------------------------------
                ; Byte comparison loop.
                ; Y is the byte index (0-based).
                ; TMPA is the remaining byte count (counts down).
                ; Uses (LOC_ADDR1,S),Y and (LOC_ADDR2,S),Y -- these are
                ; 65816 stack-relative indirect indexed addressing modes,
                ; the same technique used in MOVE_CODE and FILL_CODE.
                ;----------------------------------------------------------
                LDY     #0

                LDA     TMPA
                BEQ     @length_check   ; MIN = 0 -> skip loop, compare lengths

@byte_loop:
                ;------------------------------------------------------
                ; Fetch one byte from each string in 8-bit mode.
                ; SCRATCH0 is a zero-page cell; storing a byte there in
                ; 8-bit mode is safe (only the low byte is written).
                ;------------------------------------------------------
                SEP     #$20            ; A = 8-bit
                .a8
                LDA     (LOC_ADDR1,S),Y ; byte from string1
                STA     SCRATCH0        ; save for comparison
                LDA     (LOC_ADDR2,S),Y ; byte from string2
                CMP     SCRATCH0        ; str2[Y] - str1[Y]  (unsigned)
                REP     #$20            ; A = 16-bit (before any branch)
                .a16

                BEQ     @next_byte      ; bytes equal -> continue
                BCC     @str1_greater   ; str2[Y] < str1[Y]  -> str1 > str2
                ; else  str2[Y] > str1[Y] -> str1 < str2
                LDA     #$FFFF          ; result = -1
                BRA     @store_result

@str1_greater:
                LDA     #$0001          ; result = +1
                BRA     @store_result

@next_byte:
                INY                     ; advance byte index
                DEC     TMPA            ; one fewer byte to compare
                BNE     @byte_loop      ; loop until TMPA = 0

                ;----------------------------------------------------------
                ; All MIN(u1,u2) bytes matched. Compare lengths.
                ; u1 is in TMPB, u2 is in SCRATCH1.
                ;----------------------------------------------------------
@length_check:
                LDA     TMPB            ; u1
                CMP     SCRATCH1        ; u1 - u2  (unsigned)
                BEQ     @equal          ; u1 == u2 -> strings are equal
                BCS     @str1_longer    ; u1 >  u2 -> str1 longer -> str1 > str2
                LDA     #$FFFF          ; u1 <  u2 -> str1 shorter -> str1 < str2
                BRA     @store_result
@str1_longer:
                LDA     #$0001
                BRA     @store_result
@equal:
                LDA     #$0000

@store_result:
                ;----------------------------------------------------------
                ; Tear down hw stack locals, restore IP, push result.
                ;----------------------------------------------------------
                PLY                     ; discard addr1
                PLY                     ; discard addr2
                PLY                     ; Restore IP

                DEX
                DEX
                STA     0,X             ; Push result onto parameter stack
                NEXT
        ENDPUBLIC

;==============================================================================
; SECTION 12: SYSTEM WORDS (QUIT, ABORT)
; These are colon definitions compiled as ITC word lists in ROM
;==============================================================================

;------------------------------------------------------------------------------
; BYE ( -- ) halt the system
;------------------------------------------------------------------------------
        HEADER  "BYE", BYE_ENTRY, BYE_CFA, 0, COMPARE_ENTRY
        CODEPTR BYE_CODE
        PUBLIC  BYE_CODE
        .a16
        .i16
                ; --- Reset return stack ---
                LDA     RSP_INIT        ; Reload from entry value.
                TCS
                RTL		        ; Return to ROM monitor or HAL INIT
        ENDPUBLIC

;------------------------------------------------------------------------------
; ABORT ( -- ) reset both stacks, STATE, and jump to QUIT
;
; ABORT must be a machine-code primitive, NOT a colon definition.
; This is because it wipes the return stack, so there is no valid
; return address to save or restore via DOCOL/EXIT.
; Instead it directly loads QUIT_BODY into IP (Y) and dispatches
; with NEXT, jumping into QUIT's body as if already executing.
;
; ANS Forth specification:
;   "Empty the data stack and perform the function of QUIT,
;    which includes emptying the return stack."
;------------------------------------------------------------------------------
        HEADER  "ABORT", ABORT_ENTRY, ABORT_CFA, 0, BYE_ENTRY
        CODEPTR ABORT_CODE
        PUBLIC  ABORT_CODE
        .a16
        .i16
                ; --- Reset parameter stack ---
                LDX     #PSP_INIT       ; Stack grows down from here.

                ; --- Reset return stack ---
                LDA     RSP_INIT        ; Reload from entry value.
                TCS

                ; --- Reset STATE and >IN to 0 ---
                ; STZ (indirect) is not supported on 65816.
                ; Store UP in SCRATCH0, use Y as offset into user area.
                LDA     #FORTH_FALSE
                LDY     #U_STATE
                STA     (UP),Y          ; STATE = 0 (interpret)
                LDY     #U_TOIN
                STA     (UP),Y          ; >IN = 0

                ; --- Rollback any partial definition ---
                JSR     ROLLBACK_IMPL   ; restore DP and LATEST if checkpoint active
                ; --- Jump into QUIT's body directly via NEXT ---
                ; Cannot JSR/RTS because the return stack was just wiped.
                ; Loading QUIT_BODY into IP (Y) and calling NEXT causes
                ; the inner interpreter to begin executing QUIT's word list.
                LDY     #QUIT_BODY      ; IP = start of QUIT body
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; QUIT ( -- ) outer interpreter loop
; Resets return stack, reads and interprets input forever
;------------------------------------------------------------------------------
        HEADER  "QUIT", QUIT_ENTRY, QUIT_CFA, 0, ABORT_ENTRY
        CODEPTR DOCOL

        .export QUIT_BODY
QUIT_BODY:
        ; Reset return stack (set S to RSP_INIT)
        ; This is done by the machine-code entry in FORTH_INIT
        ; From inside Forth we compile a call to RSP-RESET primitive
        .word   RSP_RESET_CFA           ; Reset return stack
        .word   STATE_CFA               ; Push STATE addr
        .word   ZERO_CFA                ; 0 = interpret
        .word   STORE_CFA               ; STATE = 0

        ; Main REPL loop
QUIT_LOOP:
        .word   SOURCE_CFA              ; Get TIB address and length
        .word   DROP_CFA                ; Only the address iss required.
        .word   LIT_CFA
        .word   TIB_SIZE                ; Max input length
        .word   ACCEPT_CFA              ; Read line → ( len )
        .word   HASHTIB_CFA
        .word   STORE_CFA               ; Store length in user area
        .word   ZERO_CFA
        .word   TOIN_CFA
        .word   STORE_CFA               ; >IN = 0
        .word   INTERPRET_CFA           ; Interpret the input line
        .word   STATE_CFA
        .word   FETCH_CFA
        .word   ZEROEQ_CFA              ; STATE = 0 (interpret mode)?
        .word   ZBRANCH_CFA
        .word   QUIT_LOOP               ; Loop back (compiling: no prompt)
        .word   DOT_PROMPT_CFA          ; Print " ok"
        .word   BRANCH_CFA
        .word   QUIT_LOOP

;------------------------------------------------------------------------------
; Helper primitives needed by QUIT
;------------------------------------------------------------------------------

; RSP-RESET - reset the hardware (return) stack pointer
        HEADER  "RSP-RESET", RSP_RESET_ENTRY, RSP_RESET_CFA, F_HIDDEN, QUIT_ENTRY
        CODEPTR RSP_RESET_CODE
        PUBLIC  RSP_RESET_CODE
        .a16
        .i16
                LDA     RSP_INIT
                TCS                     ; S = RSP_INIT
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; ACCEPT ( addr maxlen -- actual )
;
; Read a line from the UART into the buffer at addr, up to maxlen characters.
; Returns actual character count (not including the terminating CR).
;
; Supported control characters:
;   CR  ($0D) - end of input
;   BS  ($08) - backspace: erase last character if any
;   DEL ($7F) - same as BS
;   All other characters stored if buffer not full, echoed to terminal.
;
; Stack on entry (X = PSP):
;   0,X = maxlen
;   2,X = addr
;
; Stack on exit:
;   0,X = actual (character count)
;------------------------------------------------------------------------------
        HEADER  "ACCEPT", ACCEPT_ENTRY, ACCEPT_CFA, 0, RSP_RESET_ENTRY
        CODEPTR ACCEPT_CODE
        PUBLIC  ACCEPT_CODE
        .a16
        .i16

        ; Stack frame locals (DP points here after TCD):
        LOC_MAXLEN  = 1                 ; maximum character count
        LOC_BUF     = 3                 ; buffer base address
        LOC_COUNT   = 5                 ; current character count
        LOC_CHAR    = 7                 ; last received character
        LOC_SIZE    = LOC_CHAR + 1      ; = 8 bytes reserved
        ;   (saved IP  = 9,  pushed by PHY before frame reserved)
        ;   (saved DP  = 11, pushed by PHD before PHY)

                PHD                     ; Save DP
                PHY                     ; Save IP

                TSC                     ; Reserve stack frame
                SEC
                SBC     #LOC_SIZE
                TCS
                TCD                     ; DP -> stack frame

                ; Pop arguments from parameter stack using absolute addressing
                LDA     a:0,X           ; maxlen
                STA     LOC_MAXLEN
                LDA     a:2,X           ; addr
                STA     LOC_BUF
                ; Drop both cells from parameter stack
                TXA
                CLC
                ADC     #4
                TAX

                STZ     LOC_COUNT       ; char count = 0

                ;--------------------------------------------------------------
                ; Main character receive loop
                ;--------------------------------------------------------------
@getchar:
                JSR     hal_getch       ; Blocking receive; char returned in A
                AND     #$00FF          ; Mask to byte
                STA     LOC_CHAR        ; Save received character

                CMP     #C_RETURN       ; CR -> end of line
                BEQ     @done

                CMP     #BKSP           ; BS -> backspace
                BEQ     @backspace
                CMP     #DEL            ; DEL -> backspace
                BEQ     @backspace

                ; Normal character: store if buffer not full
                LDA     LOC_COUNT
                CMP     LOC_MAXLEN      ; count >= maxlen?
                BCS     @getchar        ; Buffer full, discard char

                ; Store character in buffer at BUF[count]
                ; Use Y as byte index; IP already saved in frame
                LDY     LOC_COUNT
                SEP     #$20            ; 8-bit stores
                .a8
                LDA     LOC_CHAR
                STA     (LOC_BUF),Y     ; BUF[count] = char
                REP     #$20
                .a16

                JSR     hal_putch       ; Echo character

                INC     LOC_COUNT
                BRA     @getchar

                ;--------------------------------------------------------------
                ; Backspace: erase last character if any
                ;--------------------------------------------------------------
@backspace:
                TAY
                BEQ     @getchar        ; Nothing to delete
                DEC     LOC_COUNT
                LDA     #BKSP
                JSR     hal_putch
                LDA     #SPACE          ; Space (erase on terminal)
                JSR     hal_putch
                LDA     #BKSP           ; BS again (reposition cursor)
                JSR     hal_putch
                BRA     @getchar

                ;--------------------------------------------------------------
                ; CR received: echo CR+LF, push count, tear down and return
                ;--------------------------------------------------------------
@done:
                LDA     #C_RETURN
                JSR     hal_putch
                LDA     #L_FEED
                JSR     hal_putch

@return:
                LDA     LOC_COUNT       ; actual character count = result
                DEX                     ; Push result onto parameter stack
                DEX
                STA     a:0,X

                ; Tear down frame, restore IP and DP
                TSC
                CLC
                ADC     #LOC_SIZE
                TCS
                PLY                     ; Restore IP
                PLD                     ; Restore DP

                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; FIND ( addr -- addr 0 | xt 1 | xt -1 )
;
; Search the dictionary for the counted string at addr.
;
; Returns:
;   addr  0   word not found; addr is the original counted string address
;   xt    1   word found, not immediate
;   xt   -1   word found, immediate ($FFFF)
;
; Dictionary entry layout (produced by HEADER macro):
;   +0  link field   (2 bytes) pointer to previous entry, 0 = end of chain
;   +2  flags|len    (1 byte)  F_HIDDEN=$40, F_IMMEDIATE=$80, F_LENMASK=$1F
;   +3  name chars   (len bytes)
;       .align 2
;       CFA:         code pointer (2 bytes) <- execution token
;------------------------------------------------------------------------------
        HEADER  "FIND", FIND_ENTRY, FIND_CFA, 0, ACCEPT_ENTRY
        CODEPTR FIND_CODE
        PUBLIC  FIND_CODE
        .a16
        .i16

        ; Stack frame locals (DP points here after TCD):
        LOC_ADDR    = 1         ; input lp string addr (preserved for not-found)
        LOC_LEN     = 3         ; name length from search string (cached)
        LOC_ENTRY   = 5         ; current dictionary entry pointer
        LOC_NAMEPTR = 7         ; pointer to name chars in current entry
        LOC_FLAGS   = 9         ; flags|len byte of current entry
        LOC_CFA     = 11        ; CFA of matched entry
        LOC_RESULT  = 13        ; result flag (1 or -1)
        LOC_SIZE    = LOC_RESULT + 1    ; = 14 bytes
        ;   (saved IP at LOC_SIZE+1,S pushed by PHY)
        ;   (saved DP at LOC_SIZE+3,S pushed by PHD)

                PHD                     ; Save DP
                PHY                     ; Save IP

                TSC                     ; Reserve stack frame
                SEC
                SBC     #LOC_SIZE
                TCS
                TCD                     ; DP -> stack frame

                ;--------------------------------------------------------------
                ; Load LATEST to start dictionary walk
                ;--------------------------------------------------------------
                LDA     a:UP
                STA     LOC_ADDR        ; Use LOC_ADDR before it is initialized
                LDY     #U_LATEST
                LDA     (LOC_ADDR),Y    ; LATEST -> first entry to check
                STA     LOC_ENTRY

                ;--------------------------------------------------------------
                ; Load input addr from TOS, cache name length
                ;--------------------------------------------------------------
                LDA     a:0,X           ; addr (counted string)
                STA     LOC_ADDR

                SEP     #$20            ; 8-bit fetch
                .a8
                LDA     (LOC_ADDR)      ; length byte of search string
                REP     #$20
                .a16
                AND     #$00FF
                STA     LOC_LEN         ; cache search name length

                ;--------------------------------------------------------------
                ; Main dictionary walk loop
                ;--------------------------------------------------------------
@next_entry:
                LDA     LOC_ENTRY
                BEQ     @not_found      ; Link = 0 -> end of chain

                ;--------------------------------------------------------------
                ; Fetch flags|len byte at entry+2, check hidden
                ;--------------------------------------------------------------
                LDA     LOC_ENTRY
                CLC
                ADC     #CELL_SIZE      ; Point to flags|len byte
                STA     LOC_NAMEPTR     ; Temporarily use LOC_NAMEPTR as ptr

                SEP     #$20
                .a8
                LDA     (LOC_NAMEPTR)   ; flags|len byte
                REP     #$20
                .a16
                AND     #$00FF
                STA     LOC_FLAGS       ; Save full flags|len

                ; Check hidden flag
                AND     #F_HIDDEN
                BNE     @follow_link    ; Hidden -> skip this entry

                ; Check name length match
                LDA     LOC_FLAGS
                AND     #F_LENMASK      ; Isolate length field
                CMP     LOC_LEN         ; Compare with search length
                BNE     @follow_link    ; Lengths differ -> no match

                ;--------------------------------------------------------------
                ; Lengths match: compare name bytes
                ; LOC_NAMEPTR currently points to flags|len byte;
                ; advance by 1 to point to first name character.
                ; Search string chars start at LOC_ADDR+1.
                ;--------------------------------------------------------------
                INC     LOC_NAMEPTR     ; Now points to entry name chars

                LDA     LOC_ADDR
                INC     A               ; Point past length byte
                STA     LOC_CFA         ; Borrow LOC_CFA as search char ptr

                LDY     #0              ; Byte index
@cmp_loop:
                SEP     #$20
                .a8
                LDA     (LOC_NAMEPTR),Y ; Entry name byte
                CMP     (LOC_CFA),Y     ; Search string byte
                REP     #$20
                .a16
                BNE     @follow_link    ; Mismatch -> try next entry

                INY
                CPY     LOC_LEN         ; Compared all bytes?
                BNE     @cmp_loop       ; No -> continue

                ;--------------------------------------------------------------
                ; Full name match. Compute CFA.
                ; CFA = entry + 2 (link) + 1 (flags|len) + namelen, .align 2
                ; i.e. (entry + 3 + namelen) rounded up to next even address.
                ;--------------------------------------------------------------
                LDA     LOC_ENTRY
                CLC
                ADC     #3              ; Skip link(2) + flags|len(1)
                ADC     LOC_LEN         ; Skip name bytes
                INC     A               ; Round up: if odd, +1 makes even;
                AND     #$FFFE          ; if even, +1 then mask gives same even
                STA     LOC_CFA         ; LOC_CFA = CFA (execution token)

                ; Determine result flag from F_IMMEDIATE
                LDA     LOC_FLAGS
                AND     #F_IMMEDIATE
                BEQ     @normal_word
                LDA     #FORTH_TRUE     ; Immediate -> -1
                BRA     @store_result
@normal_word:
                LDA     #1              ; Normal -> 1
@store_result:
                STA     LOC_RESULT

                ; Push xt then flag
                LDA     LOC_CFA
                STA     a:0,X           ; Replace addr on TOS with xt
                LDA     LOC_RESULT
                BRA     @return

                ;--------------------------------------------------------------
                ; Follow link to next entry
                ;--------------------------------------------------------------
@follow_link:
                LDA     (LOC_ENTRY)     ; Fetch link field (at offset 0)
                STA     LOC_ENTRY
                BRA     @next_entry

                ;--------------------------------------------------------------
                ; Not found: leave original addr on stack, push 0
                ;--------------------------------------------------------------
@not_found:
                ; addr is still at a:0,X (untouched)
                LDA     #FORTH_FALSE    ; 0

                ;--------------------------------------------------------------
                ; Single return path
                ;--------------------------------------------------------------
@return:
                DEX                     ; Push flag onto parameter stack
                DEX
                STA     a:0,X
                TSC                     ; Tear down frame
                CLC
                ADC     #LOC_SIZE
                TCS
                PLY                     ; Restore IP
                PLD                     ; Restore DP
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; COMPILE-ONLY-ERROR - compiled into compile only words to give an error when
; used interactively.
;------------------------------------------------------------------------------
        HEADER  "COMPILE-ONLY-ERROR", COMPILE_ONLY_ERROR_ENTRY, COMPILE_ONLY_ERROR_CFA, F_HIDDEN, FIND_ENTRY
        CODEPTR DOCOL
        .word   LIT_CFA
        .word   compile_only_msg
        .word   CPUTS_CFA
        .word   ABORT_CFA
        .word   EXIT_CFA

compile_only_msg:
        .byte "error: compile-only word",C_RETURN,L_FEED,0

;------------------------------------------------------------------------------
; UNDEFINED-WORD ( addr -- ) print error message and abort
; Called when INTERPRET cannot find or convert a word.
;------------------------------------------------------------------------------
        HEADER  "UNDEFINED-WORD", UNDEFINED_WORD_ENTRY, UNDEFINED_WORD_CFA, 0, COMPILE_ONLY_ERROR_ENTRY
        CODEPTR UNDEFINED_WORD_CODE
        PUBLIC  UNDEFINED_WORD_CODE
        .a16
        .i16
                LDA     #@error_undef
                JSR     hal_cputs
                LDA     a:0,X
                DEX
                DEX
                JSR     hal_lpputs
                LDA     #@crlf
                JSR     hal_cputs
                JMP     ABORT_CODE
@error_undef:   .asciiz "error: Undefined word "
@crlf:          .byte $0D, $0A, $00
        ENDPUBLIC

;------------------------------------------------------------------------------
; INTERPRET ( -- ) parse and execute/compile words from input
;------------------------------------------------------------------------------
        HEADER  "INTERPRET", INTERPRET_ENTRY, INTERPRET_CFA, 0, UNDEFINED_WORD_ENTRY
        CODEPTR DOCOL

INTERPRET_BODY:
INTERPRET_LOOP:
        ; Parse next space-delimited word from input
        .word   BL_CFA                  ; space delimiter
        .word   WORD_CFA                ; ( addr ) counted string at HERE

        ; Check for empty word - if length 0, input exhausted
        .word   DUP_CFA                 ; ( addr addr )
        .word   CFETCH_CFA              ; ( addr len )
        .word   ZEROEQ_CFA              ; ( addr flag )
        .word   ZBRANCH_CFA
        .word   INTERPRET_NOTEMPTY
        .word   DROP_CFA                ; ( ) discard addr
        .word   EXIT_CFA                ; done

INTERPRET_NOTEMPTY:
        ; Try to find the word in the dictionary
        .word   FIND_CFA                ; ( addr 0 | xt 1 | xt -1 )

        ; Was it found?
        .word   DUP_CFA                 ; ( addr 0 0 | xt 1 1 | xt -1 -1 )
        .word   ZEROEQ_CFA              ; ( addr 0 true | xt 1 false | xt -1 false )
        .word   ZBRANCH_CFA
        .word   INTERPRET_FOUND

        ; Not found - drop the zero and try NUMBER
        .word   DROP_CFA                ; ( addr )
        .word   NUMBER_CFA              ; ( n | throws addr )

        ; It's a number - check STATE
        .word   STATE_CFA               ; ( n addr-of-STATE )
        .word   FETCH_CFA               ; ( n state )
        .word   ZEROEQ_CFA              ; ( n flag ) true if interpreting
        .word   ZBRANCH_CFA
        .word   INTERPRET_COMPILE_LIT
        ; Interpreting: number is already on stack, just loop
        .word   BRANCH_CFA
        .word   INTERPRET_LOOP

INTERPRET_COMPILE_LIT:
        ; Compiling: emit LIT followed by the number
        .word   LIT_CFA
        .word   LIT_CFA                 ; push the CFA of LIT
        .word   COMPILECOMMA_CFA        ; compile LIT into definition
        .word   COMPILECOMMA_CFA        ; compile the number value itself
        .word   BRANCH_CFA
        .word   INTERPRET_LOOP

INTERPRET_FOUND:
        ; ( xt 1 | xt -1 ) - check STATE
        .word   STATE_CFA               ; ( xt flag addr-of-STATE )
        .word   FETCH_CFA               ; ( xt flag state )
        .word   ZEROEQ_CFA              ; ( xt flag true-if-interpreting )
        .word   ZBRANCH_CFA
        .word   INTERPRET_COMPILE_WORD

        ; Interpreting: execute regardless of immediate flag
        .word   DROP_CFA                ; ( xt ) discard flag
        .word   EXECUTE_CFA
        .word   BRANCH_CFA
        .word   INTERPRET_LOOP

INTERPRET_COMPILE_WORD:
        ; Compiling: execute if immediate (-1), compile if normal (1)
        .word   LIT_CFA
        .word   $FFFF                   ; -1 = immediate
        .word   EQUAL_CFA               ; ( xt flag ) true if immediate
        .word   ZBRANCH_CFA
        .word   INTERPRET_COMPILE_NORMAL
        ; Immediate: execute it
        .word   EXECUTE_CFA
        .word   BRANCH_CFA
        .word   INTERPRET_LOOP

INTERPRET_COMPILE_NORMAL:
        ; Normal word in compile mode: compile its xt
        .word   COMPILECOMMA_CFA
        .word   BRANCH_CFA
        .word   INTERPRET_LOOP

;------------------------------------------------------------------------------
; EVALUATE ( ix c-addr u -- jx ) takes a string and interprets it as if it
; had been typed at the keyboard. It temporarily replaces the input source
; with the given string, runs the interpreter, then restores the original
; input source.
;------------------------------------------------------------------------------
        HEADER  "EVALUATE", EVALUATE_ENTRY, EVALUATE_CFA, 0, INTERPRET_ENTRY
        CODEPTR DOCOL
        ; Save current source state onto return stack
        .word   TOIN_CFA
        .word   FETCH_CFA              ; ( c-addr u toin )
        .word   SOURCE_CFA             ; ( c-addr u toin tib sourcelen )
        .word   TOR_CFA                ; R: ( sourcelen )
        .word   TOR_CFA                ; R: ( sourcelen tib )
        .word   TOR_CFA                ; R: ( sourcelen tib toin )
        ; Set up new source ( c-addr u )
        .word   HASHTIB_CFA
        .word   STORE_CFA              ; #TIB = u ( )
        .word   TICKTIB_CFA
        .word   STORE_CFA              ; 'TIB = c-addr ( c-addr u )
        .word   ZERO_CFA
        .word   TOIN_CFA
        .word   STORE_CFA              ; >IN = 0
        ; Interpret the string
        .word   INTERPRET_CFA
        ; Restore source state
        .word   RFROM_CFA
        .word   TOIN_CFA
        .word   STORE_CFA              ; restore >IN
        .word   RFROM_CFA
        .word   TICKTIB_CFA
        .word   STORE_CFA              ; restore 'TIB
        .word   RFROM_CFA
        .word   HASHTIB_CFA
        .word   STORE_CFA              ; restore #TIB
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; . (DOT) ( n -- ) print signed number
;------------------------------------------------------------------------------
        HEADER  ".", DOT_ENTRY, DOT_CFA, 0, EVALUATE_ENTRY
        CODEPTR DOT_CODE
        PUBLIC  DOT_CODE
        .a16
        .i16
                LDA     0,X
                INX
                INX
                ; Print trailing space
                STA     SCRATCH0
                JSR     print_sdec
                ; Print trailing space
                LDA     #SPACE
                JSR     hal_putch
                NEXT

print_sdec:
                LDA     SCRATCH0
                CMP     #0
                BPL     print_udec
                ; Negative: negate value, then print minus sign
                EOR     #$FFFF
                INC     A
                STA     SCRATCH0
                LDA     #'-'
                JSR     hal_putch
print_udec:
                ; Print SCRATCH0 as unsigned decimal via repeated division
                ; Digits pushed onto hardware stack in reverse, then printed
                NUM_MSB = 4             ; Offsets to locals
                NUM_LSB = 3
                BCD = 2
                BASE = 1

                PHD                     ; save direct page register
                PHY                     ; Save IP (Y used as digit counter)

                LDA     SCRATCH0
                PHA                     ; Establish working area
                LDY     #U_BASE
                LDA     (UP),Y          ; BASE (10 or 16)
                PHA
	        TSC                     ; Xfer RSP to direct page reg
                TCD                     ; stack local space is now direct page.

                OFF16MEM                ; Switch to byte mode.

                LDA     #0              ; null delimiter for print loop
                PHA
@while:	                                ; divide TOS by base
                STZ     BCD             ; clr BCD
                LDY     #16             ; {>} = loop counter
@foreachbit:
                ASL     NUM_LSB         ; TOS is gradually replaced
                ROL     NUM_MSB         ; with the quotient
                ROL     BCD             ; BCD result is gradually replaced
                LDA     BCD             ; with the remainder
                SEC
                SBC     BASE            ; partial BCD >= base ?
                BCC     @else
                STA     BCD             ; yes: update the partial result
                INC     NUM_LSB         ; set low bit in partial quotient
@else:
                DEY
                BNE     @foreachbit     ; loop 16 times
                LDA     BCD
                CMP     #10
                BCC     @decdigit
                ADC     #6              ; 'A'-10-1+carry
@decdigit:      ADC     #'0'            ; convert BCD result to ASCII
                PHA                     ; stack digits in ascending
                LDA     NUM_LSB         ; order ('0' for zero)
                ORA     NUM_MSB
                BNE     @while          ; } until TOS is 0
@print:
                PLA
@loop:
                JSR     hal_putch       ; print digits in descending order
                PLA                     ; until null delimiter is encountered
                BNE     @loop
                ON16MEM                 ; exit byte mode
                PLA                     ; clean up working area
                PLA
                PLY                     ; restore registers and return
                PLD
                RTS
	ENDPUBLIC

;------------------------------------------------------------------------------
; U. ( n -- ) print unsigned number
;------------------------------------------------------------------------------
        HEADER  "U.", UDOT_ENTRY, UDOT_CFA, 0, DOT_ENTRY
        CODEPTR UDOT_CODE
        PUBLIC  UDOT_CODE
        .a16
        .i16
                LDA     0,X
                INX
                INX
                STA     SCRATCH0
                JSR     DOT_CODE::print_udec
                LDA     #SPACE
                JSR     hal_putch
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; D. ( d_lo d_hi -- ) print signed 32-bit double followed by space
;------------------------------------------------------------------------------
        HEADER  "D.", DDOT_ENTRY, DDOT_CFA, 0, UDOT_ENTRY
        CODEPTR DOCOL
        .word   TUCK_CFA                ; ( d_hi d_lo d_hi ) save sign
        .word   DABS_CFA                ; ( d_hi ud_lo ud_hi ) absolute value
        .word   LESSHASH_CFA            ; <# begin pictured output
        .word   HASHS_CFA               ; #S convert all digits
        .word   ROT_CFA                 ; ( ud_str d_hi ) bring sign to TOS
        .word   SIGN_CFA                ; add '-' if negative
        .word   HASHGT_CFA              ; #> ( c-addr u )
        .word   TYPE_CFA                ; print
        .word   SPACE_CFA               ; trailing space
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; .HEX ( n -- ) print hexadecimal number
;------------------------------------------------------------------------------
        HEADER  ".HEX", DOTHEX_ENTRY, DOTHEX_CFA, 0, DDOT_ENTRY
        CODEPTR DOTHEX_CODE
        PUBLIC  DOTHEX_CODE
        .a16
        .i16
                ; Print TOS as 4-digit hex
                LDA     0,X
                INX
                INX
                JSR     hal_putchex
                LDA     #SPACE
                JSR     hal_putch
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; .S ( -- ) print stack contents non-destructively using ANS Forth format
; e.g. <depth> NOS_N ... NOS TOS ok N
;------------------------------------------------------------------------------
        HEADER  ".S", DOTS_ENTRY, DOTS_CFA, 0, DOTHEX_ENTRY
        CODEPTR DOTS_CODE
        PUBLIC  DOTS_CODE
        .a16
        .i16
                PHX                     ; Save PSP

                JSR     DEPTH_CODE::calc_depth
                BEQ     @ds_done        ; no items on stack, we're done.

                STA     SCRATCH0        ; print "<depth> "
                LDA     #'<'
                JSR     hal_putch
                JSR     DOT_CODE::print_sdec
                LDA     #'>'
                JSR     hal_putch
                LDA     #SPACE
                JSR     hal_putch
                LDX     #PSP_INIT

@print_loop:    TXA                     ; Print stack items bottom to top.
                CMP     1,S
                BEQ     @ds_done
                DEX
                DEX
                LDA     0,X
                STA     SCRATCH0
                JSR     DOT_CODE::print_sdec
                LDA     #SPACE
                JSR     hal_putch
                BRA     @print_loop
@ds_done:
                PLX                     ; Restore PSP
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; DOT-PROMPT - print " ok" prompt (hidden, used by QUIT)
;------------------------------------------------------------------------------
        HEADER  "DOT-PROMPT", DOT_PROMPT_ENTRY, DOT_PROMPT_CFA, F_HIDDEN, DOTS_ENTRY
        CODEPTR DOT_PROMPT_CODE
        PUBLIC  DOT_PROMPT_CODE
        .a16
        .i16
                LDA     #@prompt
                JSR     hal_cputs

                ; Print stack depth if nonzero
                JSR     DEPTH_CODE::calc_depth
                PHA
                BEQ     @skip           ; no items on stack.
                STA     SCRATCH0
                JSR     DOT_CODE::print_sdec

@skip:          LDA     #@crlf
                JSR     hal_cputs
                PLA
                BMI     @underflow
                NEXT
@underflow:     JMP     PSP_UNDERFLOW_HANDLER
@prompt:        .asciiz " ok "
@crlf:          .byte C_RETURN, L_FEED, 0
        ENDPUBLIC

;------------------------------------------------------------------------------
; HEADER>CFA ( entry -- addr ) extracts the CFA field from a header.
;------------------------------------------------------------------------------
        HEADER  "HEADER>CFA", HEADERCFA_ENTRY, HEADERCFA_CFA, 0, DOT_PROMPT_ENTRY
        CODEPTR DOCOL
        .word   DUP_CFA                ; ( header header )
        .word   CELLPLUS_CFA           ; ( header header+2 )
        .word   CFETCH_CFA             ; ( header flags/len )
        .word   LIT_CFA
        .word   F_LENMASK
        .word   AND_CFA                ; ( header namelen )
        .word   SWAP_CFA               ; ( namelen header )
        .word   LIT_CFA
        .word   3
        .word   PLUS_CFA               ; ( namelen header+3 )
        .word   PLUS_CFA               ; ( header+3+namelen )
        .word   ONEPLUS_CFA            ; ( +1 )
        .word   LIT_CFA
        .word   $FFFE
        .word   AND_CFA                ; ( cfa aligned )
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; HEADER>NAME ( entry -- c-addr u ) extracts the name field from a header.
;------------------------------------------------------------------------------
        HEADER  "HEADER>NAME", HEADERNAME_ENTRY, HEADERNAME_CFA, 0, HEADERCFA_ENTRY
        CODEPTR DOCOL
        .word   DUP_CFA                 ; ( entry entry )
        .word   CELLPLUS_CFA            ; ( entry entry+2 )
        .word   CFETCH_CFA              ; ( entry flags+len )
        .word   LIT_CFA
        .word   F_LENMASK
        .word   AND_CFA                 ; ( entry u )
        .word   SWAP_CFA                ; ( u entry )
        .word   LIT_CFA
        .word   3
        .word   PLUS_CFA                ; ( u entry+3 ) = c-addr
        .word   SWAP_CFA                ; ( c-addr u )
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; CFA>NAME ( cfa -- c-addr u flag ) walks the dictionary, finds a CFA, and
; extracts the name field from a header.
;------------------------------------------------------------------------------
        HEADER  "CFA>NAME", CFANAME_ENTRY, CFANAME_CFA, 0, HEADERNAME_ENTRY
        CODEPTR DOCOL
        .word   LATEST_CFA
        .word   FETCH_CFA              ; ( cfa entry )

CFANAME_LOOP:
        .word   DUP_CFA                ; ( cfa entry entry )
        .word   ZBRANCH_CFA
        .word   CFANAME_NOTFOUND

        .word   TOR_CFA                ; ( cfa ) R: ( entry )
        .word   DUP_CFA                ; ( cfa cfa ) R: ( entry )
        .word   RFETCH_CFA             ; ( cfa cfa entry ) R: ( entry )
        .word   HEADERCFA_CFA          ; ( cfa cfa entry-cfa ) R: ( entry )
        .word   EQUAL_CFA              ; ( cfa flag ) R: ( entry )
        .word   RFROM_CFA              ; ( cfa flag entry ) R: ( )
        .word   SWAP_CFA               ; ( cfa entry flag )
        .word   ZBRANCH_CFA
        .word   CFANAME_NEXT

        ; Match found
        .word   NIP_CFA                ; ( entry )
        .word   HEADERNAME_CFA         ; ( c-addr u )
        .word   LIT_CFA
        .word   $FFFF
        .word   EXIT_CFA

CFANAME_NEXT:
        ; No match - follow link
        .word   FETCH_CFA              ; ( cfa link )
        .word   BRANCH_CFA
        .word   CFANAME_LOOP

CFANAME_NOTFOUND:
        .word   TWODROP_CFA            ; ( )
        .word   LIT_CFA
        .word   $0000
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; >BODY ( xt -- a-addr ) CFA to body, skips past the code pointer cell
;------------------------------------------------------------------------------
        HEADER  ">BODY", TOBODY_ENTRY, TOBODY_CFA, 0, CFANAME_ENTRY
        CODEPTR DOCOL
        .word   CELLPLUS_CFA
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; WORDS ( -- ) list all non-hidden words in the dictionary
;------------------------------------------------------------------------------
        HEADER  "WORDS", WORDS_ENTRY, WORDS_CFA, 0, TOBODY_ENTRY
        CODEPTR DOCOL

WORDS_BODY:
        .word   LATEST_CFA              ; ( addr-of-LATEST-var )
        .word   FETCH_CFA               ; ( entry )
WORDS_LOOP:
        .word   DUP_CFA                 ; ( entry entry )
        .word   CELLPLUS_CFA            ; ( entry entry+2 )
        .word   CFETCH_CFA              ; ( entry flags+len )
        .word   LIT_CFA
        .word   F_HIDDEN
        .word   AND_CFA                 ; ( entry flags+len & F_HIDDEN )
        .word   ZEROEQ_CFA              ; ( entry flag ) true if not hidden
        .word   ZBRANCH_CFA
        .word   WORDS_SKIP
        .word   DUP_CFA                 ; ( entry entry )
        .word   HEADERNAME_CFA          ; ( entry c-addr u )
        .word   TYPE_CFA                ; ( entry )
        .word   SPACE_CFA
WORDS_SKIP:
        .word   FETCH_CFA               ; ( prev-entry ) follow link
        .word   DUP_CFA
        .word   ZEROEQ_CFA
        .word   ZBRANCH_CFA
        .word   WORDS_LOOP
        .word   DROP_CFA
        .word   CR_CFA
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; (CREATE) ( addr -- ) build dictionary header from counted string at addr.
;
; addr is the address of a counted string as returned by WORD:
;   addr+0 = length byte
;   addr+1..n = name characters (already uppercased by WORD)
;
; Header layout written to dictionary at current DP (HERE):
;   +0  LINK    (2 bytes) = old LATEST
;   +2  FL|LEN  (1 byte)  = F_HIDDEN | namelen
;   +3  NAME    (n bytes) = name characters
;   +3+n [pad]  (0-1 byte) align to even boundary
;
; Updates LATEST to point to new entry and DP to point past header.
; Does NOT write a code pointer - caller is responsible for that.
; Sets F_HIDDEN so the new word is invisible until ; or REVEAL clears it.
;
; The name is shifted up 2 bytes in place using a backwards copy
; (high index to low index) to avoid overlap corruption.
; LOC_SRC = addr+1 (first name char in WORD output)
; LOC_DST = addr+3 (first name char in final header)
;------------------------------------------------------------------------------
        HEADER  "(CREATE)", DOCREATE_ENTRY, DOCREATE_CFA, F_HIDDEN, WORDS_ENTRY
        CODEPTR DOCREATE_CODE
        PUBLIC  DOCREATE_CODE
        .a16
        .i16
        LOC_NAMELEN = 1                 ; name length (2 bytes)
        LOC_ENTRY   = LOC_NAMELEN + 2   ; original addr = new entry address (2 bytes)
        LOC_LATEST  = LOC_ENTRY + 2     ; old LATEST value (2 bytes)
        LOC_DP      = LOC_LATEST + 2    ; current dictionary pointer (2 bytes)
        LOC_SRC     = LOC_DP + 2        ; source pointer addr+1 (2 bytes)
        LOC_DST     = LOC_SRC + 2       ; dest pointer addr+3 (2 bytes)
        LOC_UP      = LOC_DST + 2       ; user area base pointer (2 bytes)
        LOC_SIZE    = LOC_UP + 2

                PHD                     ; Save DP
                PHY                     ; Save IP

                JSR     CHECKPOINT_IMPL ; Exception handling checkpoint

                TSC                     ; Reserve stack frame
                SEC
                SBC     #LOC_SIZE
                TCS
                TCD                     ; DP -> stack frame

                LDA     a:UP            ; Fetch UP using absolute addressing
                STA     LOC_UP

                ; --- Pop addr from parameter stack into LOC_ENTRY ---
                LDA     a:0,X           ; addr of counted string (from WORD)
                INX
                INX
                STA     LOC_ENTRY       ; save as new entry address

                ; --- Fetch current DP (HERE) ---
                LDY     #U_DP
                LDA     (LOC_UP),Y
                STA     LOC_DP

                ; --- Fetch current LATEST ---
                LDY     #U_LATEST
                LDA     (LOC_UP),Y
                STA     LOC_LATEST

                ; --- Read length byte from addr+0 ---
                LDY     #0
                SEP     #$20
                .a8
                LDA     (LOC_ENTRY),Y   ; length byte at addr+0
                REP     #$20
                .a16
                AND     #$00FF
                STA     LOC_NAMELEN

                ; --- Set up src and dst pointers for name shift ---
                LDA     LOC_ENTRY
                INC     A
                STA     LOC_SRC         ; LOC_SRC = addr+1 (first name char)
                CLC
                ADC     #CELL_SIZE
                STA     LOC_DST         ; LOC_DST = addr+3 (dest in header)

                ; --- Shift name chars from addr+1 to addr+3 ---
                ; Backwards copy (high index to low) avoids overlap corruption
                LDY     LOC_NAMELEN
                BEQ     @name_shifted
                DEY                     ; Y = namelen-1 (zero based)
@shift_loop:
                SEP     #$20
                .a8
                LDA     (LOC_SRC),Y     ; read src[Y]
                STA     (LOC_DST),Y     ; write dst[Y]
                REP     #$20
                .a16
                DEY
                BPL     @shift_loop     ; loop until Y goes negative
@name_shifted:

                ; --- Write FLAGS|LEN at addr+2 ---
                LDY     #CELL_SIZE
                LDA     LOC_NAMELEN
                ORA     #F_HIDDEN
                SEP     #$20
                .a8
                STA     (LOC_ENTRY),Y   ; addr[2] = F_HIDDEN|namelen
                REP     #$20
                .a16

                ; --- Write LINK field at addr+0 ---
                LDY     #0
                LDA     LOC_LATEST
                STA     (LOC_ENTRY),Y   ; addr[0..1] = old LATEST

                ; --- Advance LOC_DP past link(2) + flags(1) + name(n) ---
                LDA     LOC_ENTRY
                CLC
                ADC     #3
                ADC     LOC_NAMELEN
                STA     LOC_DP

                ; --- Align LOC_DP to even boundary ---
                LDA     LOC_DP
                AND     #1
                BEQ     @aligned
                INC     LOC_DP
@aligned:

                ; --- Update user area ---

                ; CURDEF = CFA of new definition (current LOC_DP)
                LDY     #U_CURDEF
                LDA     LOC_DP
                STA     (LOC_UP),Y

                ; LATEST = address of new entry header (original addr)
                LDY     #U_LATEST
                LDA     LOC_ENTRY
                STA     (LOC_UP),Y

                ; DP = updated dictionary pointer (pointing past header,
                ; ready for caller to write code pointer)
                LDY     #U_DP
                LDA     LOC_DP
                STA     (LOC_UP),Y

                ; --- Tear down frame ---
                TSC
                CLC
                ADC     #LOC_SIZE
                TCS
                PLY                     ; Restore IP
                PLD                     ; Restore DP
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; REVEAL ( -- ) clear F_HIDDEN on the most recent dictionary entry and commit
;------------------------------------------------------------------------------
        HEADER  "REVEAL", REVEAL_ENTRY, REVEAL_CFA, 0, DOCREATE_ENTRY
        CODEPTR DOCOL
        .word   LATEST_CFA
        .word   FETCH_CFA              ; ( entry )
        .word   CELLPLUS_CFA           ; ( entry+2 ) skip link field
        .word   DUP_CFA                ; ( entry+2 entry+2 )
        .word   CFETCH_CFA             ; ( entry+2 flags )
        .word   LIT_CFA
        .word   $00BF                  ; $FF ^ F_HIDDEN = $BF
        .word   AND_CFA                ; ( entry+2 flags&~F_HIDDEN )
        .word   SWAP_CFA               ; ( flags entry+2 )
        .word   CSTORE_CFA             ; store cleared flags back
        .word   COMMIT_CFA             ; clear checkpoint
        .word   EXIT_CFA

;==============================================================================
; SECTION 13: Compiler words to create words
;==============================================================================

;------------------------------------------------------------------------------
; : ( -- ) parse name, create dictionary header, enter compile mode
;------------------------------------------------------------------------------
        HEADER  ":", COLON_ENTRY, COLON_CFA, 0, REVEAL_ENTRY
        CODEPTR DOCOL
COLON_BODY:
        .word   BL_CFA
        .word   WORD_CFA                ; ( addr ) parse name from input
        .word   DOCREATE_CFA            ; ( ) build header, update LATEST and DP
        .word   LIT_CFA
        .word   DOCOL                   ; code pointer for colon definitions
        .word   COMMA_CFA               ; write DOCOL at CFA
        .word   RBRACKET_CFA            ; STATE = 1 (compile mode)
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; ; ( -- ) close colon definition: compile EXIT, reveal, interpret mode
; Immediate word - executes during compilation.
; https://forth-standard.org/standard/core/Semi
;------------------------------------------------------------------------------
        HEADER  ";", SEMICOLON_ENTRY, SEMICOLON_CFA, F_IMMEDIATE, COLON_ENTRY
        CODEPTR DOCOL
SEMICOLON_BODY:
        .word   LIT_CFA
        .word   EXIT_CFA                ; compile EXIT into definition
        .word   COMMA_CFA
        .word   REVEAL_CFA              ; clear F_HIDDEN
        .word   LBRACKET_CFA            ; STATE = 0 (interpret mode)
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; VARIABLE ( "name" -- ) parse name, create variable definition
; Runtime: pushes address of body cell onto stack
;------------------------------------------------------------------------------
        HEADER  "VARIABLE", VARIABLE_ENTRY, VARIABLE_CFA, 0, SEMICOLON_ENTRY
        CODEPTR DOCOL
VARIABLE_BODY:
        .word   BL_CFA
        .word   WORD_CFA                ; ( addr ) parse name
        .word   DOCREATE_CFA            ; ( ) build header
        .word   LIT_CFA
        .word   DOVAR                   ; code pointer for variables
        .word   COMMA_CFA               ; write DOVAR at CFA
        .word   ZERO_CFA
        .word   COMMA_CFA               ; allot and initialize one cell
        .word   REVEAL_CFA              ; clear F_HIDDEN
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; CONSTANT ( n "name" -- ) parse name, create constant definition
; Runtime: pushes stored value onto stack
;------------------------------------------------------------------------------
        HEADER  "CONSTANT", CONSTANT_ENTRY, CONSTANT_CFA, 0, VARIABLE_ENTRY
        CODEPTR DOCOL
CONSTANT_BODY:
        .word   BL_CFA
        .word   WORD_CFA                ; ( n addr ) parse name
        .word   DOCREATE_CFA            ; ( n ) build header
        .word   LIT_CFA
        .word   DOCON                   ; code pointer for constants
        .word   COMMA_CFA               ; write DOCON at CFA
        .word   COMMA_CFA               ; store constant value in body
        .word   REVEAL_CFA              ; clear F_HIDDEN
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; VALUE ( n "name" -- ) create a named value initialized to n
; Runtime: pushes stored value onto stack
;------------------------------------------------------------------------------
        HEADER  "VALUE", VALUE_ENTRY, VALUE_CFA, 0, CONSTANT_ENTRY
        CODEPTR DOCOL
        .word   BL_CFA
        .word   WORD_CFA                ; ( n addr ) parse name
        .word   DOCREATE_CFA            ; ( n ) build header
        .word   LIT_CFA
        .word   DOVAL                   ; code pointer for values
        .word   COMMA_CFA               ; write DOVAL at CFA
        .word   COMMA_CFA               ; store initial value in body
        .word   REVEAL_CFA              ; clear F_HIDDEN
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; TO ( n "name" -- ) store n into VALUE or 2VALUE
; Aborts if target word is not a VALUE or 2VALUE.
;------------------------------------------------------------------------------
        HEADER  "TO", TO_ENTRY, TO_CFA, F_IMMEDIATE, VALUE_ENTRY
        CODEPTR DOCOL
        .word   BL_CFA
        .word   WORD_CFA                ; ( n addr )
        .word   FIND_CFA                ; ( n xt flag )
        .word   DROP_CFA                ; ( n xt )
        .word   DUP_CFA                 ; ( n xt xt )
        .word   FETCH_CFA               ; ( n xt codeptr )
        .word   DUP_CFA                 ; ( n xt codeptr codeptr )
        .word   LIT_CFA
        .word   DOVAL
        .word   EQUAL_CFA               ; ( n xt codeptr is-val? )
        .word   OVER_CFA                ; ( n xt codeptr is-val? codeptr )
        .word   LIT_CFA
        .word   DO2VAL
        .word   EQUAL_CFA               ; ( n xt codeptr is-val? is-2val? )
        .word   OR_CFA                  ; ( n xt codeptr is-val-or-2val? )
        .word   ZBRANCH_CFA
        .word   TO_ERROR
        ; Valid VALUE or 2VALUE — check which one
        .word   LIT_CFA
        .word   DOVAL
        .word   EQUAL_CFA               ; ( n xt is-val? )
        .word   ZBRANCH_CFA
        .word   TO_DOUBLE
        ; Single VALUE path
        .word   CELLPLUS_CFA            ; ( n body )
        .word   STATE_CFA
        .word   FETCH_CFA
        .word   ZBRANCH_CFA
        .word   TO_INTERPRET_SINGLE
        ; Compile single store
        .word   LITERAL_CFA             ; compile LIT body
        .word   LIT_CFA
        .word   STORE_CFA
        .word   COMMA_CFA               ; compile !
        .word   EXIT_CFA
TO_INTERPRET_SINGLE:
        .word   STORE_CFA               ; store n at body
        .word   EXIT_CFA
TO_DOUBLE:
        ; 2VALUE path
        .word   CELLPLUS_CFA            ; ( d_lo d_hi body )
        .word   STATE_CFA
        .word   FETCH_CFA
        .word   ZBRANCH_CFA
        .word   TO_INTERPRET_DOUBLE
        ; Compile double store
        .word   LITERAL_CFA             ; compile LIT body
        .word   LIT_CFA
        .word   TWOSTORE_CFA
        .word   COMMA_CFA               ; compile 2!
        .word   EXIT_CFA
TO_INTERPRET_DOUBLE:
        .word   TWOSTORE_CFA            ; store d at body
        .word   EXIT_CFA
TO_ERROR:
        .word   LIT_CFA
        .word   FORTH_TRUE
        .word   DOABORTQUOTE_CFA
        .word   11
        .byte   "not a VALUE"
        .align  2
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; 2VARIABLE ( d "name" -- ) parse name, create variable double definition
; https://forth-standard.org/standard/double/TwoVARIABLE
;------------------------------------------------------------------------------
        HEADER  "2VARIABLE", TWOVARIABLE_ENTRY, TWOVARIABLE_CFA, 0, TO_ENTRY
        CODEPTR DOCOL
        .word   CREATE_CFA            ; ( n ) build header
        .word   ZERO_CFA
        .word   COMMA_CFA               ; write DOVAR at CFA
        .word   ZERO_CFA
        .word   COMMA_CFA               ; allot and initialize one cell
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; 2CONSTANT ( d "name" -- ) parse name, create constant double definition
; Runtime: pushes stored value onto stack
; https://forth-standard.org/standard/double/TwoCONSTANT
;------------------------------------------------------------------------------
        HEADER  "2CONSTANT", TWOCONSTANT_ENTRY, TWOCONSTANT_CFA, 0, TWOVARIABLE_ENTRY
        CODEPTR DOCOL
        .word   CREATE_CFA              ; ( n ) build header
        .word   COMMA_CFA               ; store constant low value in body
        .word   COMMA_CFA               ; store constant high value in body
        .word   DODOES_CFA
        .word   TWOFETCH_CFA
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; 2VALUE ( x1 x2 "<spaces>name" -- ) Skip leading space delimiters. Parse name
; delimited by a space. Create a definition for name with the execution
; semantics of 2@, with an initial value of x1 x2.
; https://forth-standard.org/standard/double/TwoVALUE
;------------------------------------------------------------------------------
        HEADER  "2VALUE", TWOVALUE_ENTRY, TWOVALUE_CFA, 0, TWOCONSTANT_ENTRY
        CODEPTR DOCOL
        .word   BL_CFA
        .word   WORD_CFA                ; ( d_lo d_hi addr )
        .word   DOCREATE_CFA            ; ( d_lo d_hi )
        .word   LIT_CFA
        .word   DO2VAL
        .word   COMMA_CFA              ; write DO2VAL at CFA
        .word   COMMA_CFA              ; store d_lo at CFA+2
        .word   COMMA_CFA              ; store d_hi at CFA+4
        .word   REVEAL_CFA
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; [ ( -- ) enter interpretation state (immediate)
; Sets STATE = 0
; https://forth-standard.org/standard/core/Bracket
;------------------------------------------------------------------------------
        HEADER  "[", LBRACKET_ENTRY, LBRACKET_CFA, F_IMMEDIATE, TWOVALUE_ENTRY
        CODEPTR LBRACKET_CODE
        PUBLIC  LBRACKET_CODE
        .a16
        .i16
                PHY                     ; Save IP
                LDY     #U_STATE
                LDA     #FORTH_FALSE
                STA     (UP),Y          ; STATE = 0 (interpret)
                PLY                     ; Restore IP
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; ] ( -- ) enter compilation state
; Sets STATE = 1 (compile)
; https://forth-standard.org/standard/right-bracket
;------------------------------------------------------------------------------
        HEADER  "]", RBRACKET_ENTRY, RBRACKET_CFA, 0, LBRACKET_ENTRY
        CODEPTR RBRACKET_CODE
        PUBLIC  RBRACKET_CODE
        .a16
        .i16
                PHY                     ; Save IP
                LDY     #U_STATE
                LDA     #FORTH_TRUE
                STA     (UP),Y          ; STATE = 1 (compile)
                PLY                     ; Restore IP
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; COMPILE, ( xt -- ) compile xt into the current definition
; In ITC Forth, compiling a word is just storing its CFA at HERE.
; Functionally identical to , (COMMA) for this implementation.
; https://forth-standard.org/standard/core/COMPILEComma
;------------------------------------------------------------------------------
        HEADER  "COMPILE,", COMPILECOMMA_ENTRY, COMPILECOMMA_CFA, 0, RBRACKET_ENTRY
        CODEPTR COMMA_CODE              ; Reuse COMMA_CODE directly

;------------------------------------------------------------------------------
; POSTPONE ( "<spaces>name" -- ) Skip leading space delimiters. Parse name
; delimited by a space. Find name. Append the compilation semantics of name to
; the current definition. An ambiguous condition exists if name is not found.
; https://forth-standard.org/standard/core/POSTPONE
;------------------------------------------------------------------------------
        HEADER  "POSTPONE", POSTPONE_ENTRY, POSTPONE_CFA, F_IMMEDIATE, COMPILECOMMA_ENTRY
        CODEPTR DOCOL
        .word   PARSENAME_CFA          ; ( c-addr u )
        .word   HERE_CFA
        .word   PLACE_CFA              ; uppercase copy at HERE
        .word   HERE_CFA
        .word   FIND_CFA               ; ( xt 1|-1 | here 0 )
        .word   DUP_CFA                ; ( xt flag flag | here 0 0 )
        .word   ZBRANCH_CFA
        .word   POSTPONE_NOTFOUND
        .word   LIT_CFA
        .word   1
        .word   EQUAL_CFA              ; ( xt flag ) true if non-immediate
        .word   ZBRANCH_CFA
        .word   POSTPONE_IMMEDIATE
        ; Non-immediate: compile LIT xt COMPILE,
        .word   LITERAL_CFA            ; compile LIT xt
        .word   LIT_CFA
        .word   COMPILECOMMA_CFA
        .word   COMMA_CFA              ; compile COMPILE,
        .word   EXIT_CFA
POSTPONE_IMMEDIATE:
        ; Immediate: just compile the xt directly
        .word   COMPILECOMMA_CFA
        .word   EXIT_CFA
POSTPONE_NOTFOUND:
        .word   TWODROP_CFA
        .word   LIT_CFA
        .word   postpone_notfound_msg
        .word   CPUTS_CFA
        .word   ABORT_CFA
        .word   EXIT_CFA

postpone_notfound_msg:
        .byte   "POSTPONE: word not found", $0D, $0A, $00

;------------------------------------------------------------------------------
; [COMPILE] ( "<spaces>name" -- ) deprecated, but included for compatibility.
; It's essentially the same as POSTPONE
; https://forth-standard.org/standard/core/BracketCOMPILE
;------------------------------------------------------------------------------
        HEADER  "[COMPILE]", BRCOMPILE_ENTRY, BRCOMPILE_CFA, F_IMMEDIATE, POSTPONE_ENTRY
        CODEPTR DOCOL
        .word   BL_CFA
        .word   WORD_CFA
        .word   FIND_CFA
        .word   DROP_CFA
        .word   COMPILECOMMA_CFA
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; IMMEDIATE ( -- ) Make the most recent definition an immediate word. An
; ambiguous condition exists if the most recent definition does not have a
; name or if it was defined as a SYNONYM.
; https://forth-standard.org/standard/core/IMMEDIATE
;------------------------------------------------------------------------------
        HEADER  "IMMEDIATE", IMMEDIATE_ENTRY, IMMEDIATE_CFA, 0, BRCOMPILE_ENTRY
        CODEPTR DOCOL
        .word   LATEST_CFA
        .word   FETCH_CFA              ; ( header-addr )
        .word   CELLPLUS_CFA           ; ( flags-addr )
        .word   DUP_CFA                ; ( flags-addr flags-addr )
        .word   CFETCH_CFA             ; ( flags-addr flags )
        .word   LIT_CFA
        .word   F_IMMEDIATE
        .word   OR_CFA                 ; ( flags-addr flags|F_IMMEDIATE )
        .word   SWAP_CFA               ; ( flags|F_IMMEDIATE flags-addr )
        .word   CSTORE_CFA             ; store updated flags
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; CREATE ( -- ) parse name, create dictionary entry with DOVAR behavior
; Runtime: created word pushes address of its body onto stack
;------------------------------------------------------------------------------
        HEADER  "CREATE", CREATE_ENTRY, CREATE_CFA, 0, IMMEDIATE_ENTRY
        CODEPTR DOCOL
CREATE_BODY:
        .word   BL_CFA
        .word   WORD_CFA                ; ( addr ) parse name
        .word   DOCREATE_CFA            ; ( ) build header
        .word   LIT_CFA
        .word   DOVAR                   ; code pointer
        .word   COMMA_CFA               ; write DOVAR at CFA
        .word   ZERO_CFA                ; placeholder for DOES> code address
        .word   COMMA_CFA               ; reserve CFA+2 cell
        .word   REVEAL_CFA              ; clear F_HIDDEN
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; (DOES>) ( -- ) runtime helper compiled by DOES>
; Patches the most recently CREATED word to use DODOES behavior.
; W points to this word's CFA. IP (Y) points to the DOES> code.
;------------------------------------------------------------------------------
        HEADER  "(DOES>)", DODOES_ENTRY, DODOES_CFA, F_HIDDEN, CREATE_ENTRY
        CODEPTR DODOES_CODE
        PUBLIC  DODOES_CODE
        .a16
        .i16
                PHY                     ; Save IP

                ; Fetch LATEST - points to most recently CREATEd word
                LDY     #U_LATEST
                LDA     (UP),Y          ; LATEST = entry address

                ; Find CFA: entry + 2 (link) + 1 (flags) + namelen + padding
                ; Easier: walk forward from LATEST+2 (flags byte)
                ; to find the CFA using the name length
                CLC
                ADC     #CELL_SIZE      ; point to flags byte
                STA     SCRATCH0
                SEP     #$20
                .a8
                LDA     (SCRATCH0)      ; flags|len byte
                REP     #$20
                .a16
                AND     #F_LENMASK      ; isolate name length
                CLC
                ADC     SCRATCH0        ; flags addr + namelen
                INC     A               ; +1 for flags byte itself

                ; A = tentative CFA address
                STA     SCRATCH0        ; save CFA address
                AND     #1              ; test alignment
                BEQ     @aligned
                INC     SCRATCH0        ; pad if odd
@aligned:
                ; SCRATCH0 = CFA address
                LDA     #DODOES
                STA     (SCRATCH0)      ; patch CFA = DODOES

                ; Store DOES> code address (current IP) at CFA+2
                PLA                     ; restore IP = DOES> code address
                LDY     #CELL_SIZE
                STA     (SCRATCH0),Y    ; store DOES> code address

                ; EXIT the defining word - return to caller
                PLY                     ; pop outer saved IP from DOCOL
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; DOES> ( -- ) immediate: compile (DOES>) into current definition
;------------------------------------------------------------------------------
        HEADER  "DOES>", DOES_ENTRY, DOES_CFA, F_IMMEDIATE, DODOES_ENTRY
        CODEPTR DOCOL
DOES_BODY:
        .word   LIT_CFA
        .word   DODOES_CFA
        .word   COMPILECOMMA_CFA        ; compile (DOES>) into definition
        .word   EXIT_CFA                ; return from DOES> itself

;------------------------------------------------------------------------------
; ' ( -- xt ) implicit input from TIB. Skips leading space delimiters. Parse
; the name delimited by a space. Finds name and return xt, the execution token
; for name. An ambiguous condition exists if name is not found.
; https://forth-standard.org/standard/core/Tick
;------------------------------------------------------------------------------
        HEADER  "'", TICK_ENTRY, TICK_CFA, 0, DOES_ENTRY
        CODEPTR DOCOL
        .word   BL_CFA                  ; Space delimeter
        .word   WORD_CFA                ; ( addr )
        .word   FIND_CFA                ; ( addr 0 | xt 1 | xt -1 )
        .word   ZBRANCH_CFA
        .word   TICK_ERR                ; branch to error if not found
        .word   EXIT_CFA                ; ( xt )
TICK_ERR:
        .word   UNDEFINED_WORD_CFA      ; Issue error and reset stack.

;------------------------------------------------------------------------------
; ['] Interpretation: Undefined. Compilation: ( "<spaces>name" -- )
; Skip leading space delimiters. Parse name delimited by a space. Find name.
; Run-time: ( -- xt )
; Place name's execution token xt on the stack. The execution token returned by
; the compiled phrase "['] X" is the same value returned by "' X" outside of
; compilation state.
; https://forth-standard.org/standard/core/BracketTick
;------------------------------------------------------------------------------
        HEADER  "[']", BRACKETTICK_ENTRY, BRACKETTICK_CFA, F_IMMEDIATE, TICK_ENTRY
        CODEPTR DOCOL
        .word   TICK_CFA                ; execute ' -> xt on stack
        .word   LITERAL_CFA
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; ?PAIRS ( n1 n2 -- ) abort if n1 <> n2 or stack underflow
;------------------------------------------------------------------------------
        HEADER  "?PAIRS", QPAIRS_ENTRY, QPAIRS_CFA, F_IMMEDIATE, BRACKETTICK_ENTRY
        CODEPTR DOCOL
        .word   DEPTH_CFA
        .word   LIT_CFA
        .word   2
        .word   LESS_CFA               ; DEPTH < 2 ?
        .word   DOABORTQUOTE_CFA
        .word   30
        .byte   "mismatched control structure", C_RETURN, L_FEED
        .align  2
        .word   NOTEQUAL_CFA           ; n1 <> n2 ?
        .word   DOABORTQUOTE_CFA
        .word   30
        .byte   "mismatched control structure", C_RETURN, L_FEED
        .align  CELL_SIZE
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; IF Interpretation: Undefined. Compilation: ( C: -- orig CS_IF_ELSE_THEN )
; Compile ZBRANCH with forward reference placeholder.
; https://forth-standard.org/standard/core/IF
;------------------------------------------------------------------------------
        HEADER  "IF", IF_ENTRY, IF_CFA, F_IMMEDIATE, QPAIRS_ENTRY
        CODEPTR DOCOL
        .word   LIT_CFA
        .word   ZBRANCH_CFA
        .word   COMMA_CFA              ; compile ZBRANCH
        .word   HERE_CFA               ; ( orig ) placeholder address
        .word   ZERO_CFA
        .word   COMMA_CFA              ; compile placeholder
        .word   LIT_CFA
        .word   CS_IF_ELSE_THEN        ; push security number
        .word   EXIT_CFA               ; stack: ( orig CS_IF_ELSE_THEN )

;------------------------------------------------------------------------------
; THEN Interpretation: Undefined. Compilation: ( C: orig CS_IF_ELSE_THEN -- )
; Resolve the IF or ELSE forward reference.
; https://forth-standard.org/standard/core/THEN
;------------------------------------------------------------------------------
        HEADER  "THEN", THEN_ENTRY, THEN_CFA, F_IMMEDIATE, IF_ENTRY
        CODEPTR DOCOL
        .word   LIT_CFA
        .word   CS_IF_ELSE_THEN
        .word   QPAIRS_CFA             ; verify security number
        .word   HERE_CFA               ; ( orig here )
        .word   SWAP_CFA               ; ( here orig )
        .word   STORE_CFA              ; backpatch placeholder
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; ELSE Interpretation: Undefined. Compilation: ( C: orig1 CS_IF_ELSE_THEN
;                                                  -- orig2 CS_IF_ELSE_THEN )
; Resolve IF's placeholder, compile BRANCH with new placeholder.
; https://forth-standard.org/standard/core/ELSE
;------------------------------------------------------------------------------
        HEADER  "ELSE", ELSE_ENTRY, ELSE_CFA, F_IMMEDIATE, THEN_ENTRY
        CODEPTR DOCOL
        .word   LIT_CFA
        .word   CS_IF_ELSE_THEN
        .word   QPAIRS_CFA             ; verify security number
        .word   LIT_CFA
        .word   BRANCH_CFA
        .word   COMMA_CFA              ; compile BRANCH
        .word   HERE_CFA               ; ( orig2 ) new placeholder address
        .word   ZERO_CFA
        .word   COMMA_CFA              ; compile placeholder
        .word   SWAP_CFA               ; ( orig2 orig1 )
        .word   HERE_CFA               ; ( orig2 orig1 here )
        .word   SWAP_CFA               ; ( orig2 here orig1 )
        .word   STORE_CFA              ; backpatch IF's placeholder
        .word   LIT_CFA
        .word   CS_IF_ELSE_THEN        ; push security number for THEN
        .word   EXIT_CFA               ; stack: ( orig2 CS_IF_ELSE_THEN )

;------------------------------------------------------------------------------
; (OF) ( n val -- n | ) runtime OF comparison
; match:    drop both, skip branch target, continue into OF body
; no match: drop val, leave n, branch to after ENDOF
;------------------------------------------------------------------------------
        HEADER  "(OF)", DOOF_ENTRY, DOOF_CFA, F_HIDDEN, ELSE_ENTRY
        CODEPTR DOOF_CODE
        PUBLIC  DOOF_CODE
        .a16
        .i16
                LDA     0,X             ; pop val (TOS)
                INX
                INX
                CMP     0,X             ; peek n (NOS)
                BNE     @nomatch

                ; Match: drop n
                INX
                INX
                INY                     ; skip branch target
                INY
                NEXT

@nomatch:
                ; No match: drop val, leave n, branch to after ENDOF
                LDA     0,Y             ; fetch branch target
                TAY                     ; IP = branch target
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; CASE ( -- 0 CS_NUM )
; Compiles a BRANCH that points just past itself (no-op on entry)
;------------------------------------------------------------------------------
        HEADER  "CASE", CASE_ENTRY, CASE_CFA, F_IMMEDIATE, DOOF_ENTRY
        CODEPTR DOCOL
        .word   ZERO_CFA               ; Initialize the OF ENDOF count
        .word   LIT_CFA                ; Push the compiler security number
        .word   CS_CASE_ENDCASE
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; OF Compile time: ( N CS_CASE_ENDCASE -- N+1 CS_OF_ENDOF OA )
;------------------------------------------------------------------------------
        HEADER  "OF", OF_ENTRY, OF_CFA, F_IMMEDIATE, CASE_ENTRY
        CODEPTR DOCOL
        .word   LIT_CFA
        .word   CS_CASE_ENDCASE
        .word   QPAIRS_CFA             ; Test compiler security number
        .word   ONEPLUS_CFA            ; Increment branch resolution count
        .word   LIT_CFA
        .word   CS_OF_ENDOF            ; Push new compiler security number
        .word   LIT_CFA
        .word   DOOF_CFA
        .word   COMMA_CFA              ; compile (OF)
        .word   HERE_CFA               ; OA = address of (OF)'s placeholder
        .word   ZERO_CFA
        .word   COMMA_CFA              ; compile unresolved branch target
        .word   EXIT_CFA               ; stack: ( CS+1 N+1 OA )

;------------------------------------------------------------------------------
; ENDOF ( N+1 CS_OF_ENDOF OA -- BA N+1 CS_CASE_ENDCASE )
; Compile Check CS NUM, BRANCH to ENDCASE, resolve OA to HERE
;------------------------------------------------------------------------------
        HEADER  "ENDOF", ENDOF_ENTRY, ENDOF_CFA, F_IMMEDIATE, OF_ENTRY
        CODEPTR DOCOL
        .word   TOR_CFA                ; ( N+1 CS_OF_ENDOF ) RS: ( OA )
        .word   LIT_CFA
        .word   CS_OF_ENDOF
        .word   QPAIRS_CFA             ; CS number sanity check
        .word   TOR_CFA                ; ( ) RS: ( OA N+1 )
        .word   LIT_CFA
        .word   BRANCH_CFA
        .word   COMMA_CFA              ; compile BRANCH
        .word   HERE_CFA               ; ( BA ) RS: ( OA N+1 )
        .word   ZERO_CFA               ; Branch placeholder
        .word   COMMA_CFA              ; compile BA as branch target
        .word   RFROM_CFA              ; ( BA N+1 ) RS: ( OA N+1 )
        .word   HERE_CFA               ; ( BA N+1 HERE ) RS: ( OA )
        .word   RFROM_CFA              ; ( BA N+1 HERE OA )
        .word   STORE_CFA              ; resolve OA to HERE ( BA N+1 )
        .word   LIT_CFA
        .word   CS_CASE_ENDCASE        ; ( BA N+1 CS_CASE_END_CASE )
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; ENDCASE ( BAn ... BA N CS_NUM -- )
; DROP BA, compile DROP, resolve CA to HERE
;------------------------------------------------------------------------------
        HEADER  "ENDCASE", ENDCASE_ENTRY, ENDCASE_CFA, F_IMMEDIATE, ENDOF_ENTRY
        CODEPTR DOCOL
        .word   LIT_CFA
        .word   DROP_CFA
        .word   COMMA_CFA              ; compile DROP to discard n at runtime
        .word   LIT_CFA
        .word   CS_CASE_ENDCASE
        .word   QPAIRS_CFA             ; Test compiler security number.
        .word   ZERO_CFA               ; ( BAn ... BA N 0 )
        .word   DODO_CFA
        .word   ENDCASE_LEAVE
ENDCASE_CLOOP:
        .word   HERE_CFA               ; ( BAn HERE )
        .word   SWAP_CFA               ; ( HERE BAn )
        .word   STORE_CFA              ; resolve BAn) to HERE
        .word   DOLOOP_CFA
        .word   ENDCASE_CLOOP
ENDCASE_LEAVE:
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; BEGIN Interpretation: Undefined. Compilation: ( C: -- dest CS_BEGIN_AGAIN )
; https://forth-standard.org/standard/core/BEGIN
;------------------------------------------------------------------------------
        HEADER  "BEGIN", BEGIN_ENTRY, BEGIN_CFA, F_IMMEDIATE, ENDCASE_ENTRY
        CODEPTR DOCOL
        .word   HERE_CFA               ; push current DP as loop top
        .word   LIT_CFA
        .word   CS_BEGIN_AGAIN         ; push security number
        .word   EXIT_CFA               ; stack: ( dest CS_BEGIN_AGAIN )

;------------------------------------------------------------------------------
; UNTIL Interpretation: Undefined. Compilation: ( C: dest CS_BEGIN_AGAIN -- )
; https://forth-standard.org/standard/core/UNTIL
;------------------------------------------------------------------------------
        HEADER  "UNTIL", UNTIL_ENTRY, UNTIL_CFA, F_IMMEDIATE, BEGIN_ENTRY
        CODEPTR DOCOL
        .word   LIT_CFA
        .word   CS_BEGIN_AGAIN
        .word   QPAIRS_CFA             ; verify security number
        .word   LIT_CFA
        .word   ZBRANCH_CFA
        .word   COMMA_CFA              ; compile ZBRANCH
        .word   COMMA_CFA              ; compile loop top address
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; AGAIN Interpretation: Undefined. Compilation: ( C: dest CS_BEGIN_AGAIN -- )
;------------------------------------------------------------------------------
        HEADER  "AGAIN", AGAIN_ENTRY, AGAIN_CFA, F_IMMEDIATE, UNTIL_ENTRY
        CODEPTR DOCOL
        .word   LIT_CFA
        .word   CS_BEGIN_AGAIN
        .word   QPAIRS_CFA             ; verify security number
        .word   LIT_CFA
        .word   BRANCH_CFA
        .word   COMMA_CFA              ; compile BRANCH
        .word   COMMA_CFA              ; compile BEGIN address as target
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; WHILE ( C: dest CS_BEGIN_AGAIN -- orig CS_WHILE_REPEAT dest CS_BEGIN_AGAIN )
; https://forth-standard.org/standard/core/WHILE
;------------------------------------------------------------------------------
        HEADER  "WHILE", WHILE_ENTRY, WHILE_CFA, F_IMMEDIATE, AGAIN_ENTRY
        CODEPTR DOCOL
        ; Stack: ( dest CS_BEGIN_AGAIN )
        .word   LIT_CFA
        .word   CS_BEGIN_AGAIN
        .word   QPAIRS_CFA             ; verify CS_BEGIN_AGAIN, stack: ( dest )
        .word   LIT_CFA
        .word   ZBRANCH_CFA
        .word   COMMA_CFA              ; compile ZBRANCH
        .word   HERE_CFA               ; ( dest orig )
        .word   ZERO_CFA
        .word   COMMA_CFA              ; ( dest orig ) placeholder compiled
        .word   LIT_CFA
        .word   CS_WHILE_REPEAT        ; ( dest orig CS_WHILE_REPEAT )
        .word   ROT_CFA                ; ( orig CS_WHILE_REPEAT dest )
        .word   LIT_CFA
        .word   CS_BEGIN_AGAIN         ; ( orig CS_WHILE_REPEAT dest CS_BEGIN_AGAIN )
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; REPEAT ( C: orig CS_WHILE_REPEAT dest CS_BEGIN_AGAIN -- )
; https://forth-standard.org/standard/core/REPEAT
;------------------------------------------------------------------------------
        HEADER  "REPEAT", REPEAT_ENTRY, REPEAT_CFA, F_IMMEDIATE, WHILE_ENTRY
        CODEPTR DOCOL
        ; Stack: ( orig CS_WHILE_REPEAT dest CS_BEGIN_AGAIN )
        .word   LIT_CFA
        .word   CS_BEGIN_AGAIN
        .word   QPAIRS_CFA             ; verify CS_BEGIN_AGAIN, stack: ( orig CS_WHILE_REPEAT dest )
        .word   LIT_CFA
        .word   BRANCH_CFA
        .word   COMMA_CFA              ; compile BRANCH
        .word   COMMA_CFA              ; compile dest as branch target, stack: ( orig CS_WHILE_REPEAT )
        .word   LIT_CFA
        .word   CS_WHILE_REPEAT
        .word   QPAIRS_CFA             ; verify CS_WHILE_REPEAT, stack: ( orig )
        .word   HERE_CFA               ; ( orig here )
        .word   SWAP_CFA               ; ( here orig )
        .word   STORE_CFA              ; backpatch WHILE placeholder
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; DO Compilation: ( C: -- leave-addr loop-addr CS_DO_LOOP )
; Place leaver-addr and loop-addr onto the control-flow stack. Append DODO to
; the current definition. The semantics are incomplete until resolved by a
; consumer of placeholders such as LOOP.
; https://forth-standard.org/standard/core/DO
;------------------------------------------------------------------------------
        HEADER  "DO", DO_ENTRY, DO_CFA, F_IMMEDIATE, REPEAT_ENTRY
        CODEPTR DOCOL
        .word   LIT_CFA
        .word   DODO_CFA
        .word   COMMA_CFA              ; compile (DO)
        .word   HERE_CFA               ; push leave-addr placeholder address
        .word   ZERO_CFA
        .word   COMMA_CFA              ; compile placeholder leave target
        .word   HERE_CFA               ; push loop-addr
        .word   LIT_CFA
        .word   CS_DO_LOOP             ; push security number
        .word   EXIT_CFA               ; stack: ( leave-addr loop-addr CS_DO_LOOP )

;------------------------------------------------------------------------------
; (?DO) ( limit index -- ) (R: -- limit index) runtime for ?DO
; If limit = index skip the loop entirely, otherwise identical to (DO).
;------------------------------------------------------------------------------
        HEADER  "(?DO)", DOQDO_ENTRY, DOQDO_CFA, F_HIDDEN, DO_ENTRY
        CODEPTR DOQDO_CODE
        PUBLIC  DOQDO_CODE
        .a16
        .i16
                LDA     2,X             ; limit
                CMP     0,X             ; index
                BNE     @enter_loop     ; limit <> index so enter loop
                ; limit = index: skip loop, jump to leave target
                DROP                    ; drop index
                DROP                    ; drop limit
                LDA     0,Y             ; load leave target from inline data
                TAY                     ; IP = leave target
                NEXT
@enter_loop:
                IFETCH                  ; load leave target and advance IP
                PHA                     ; push leave target onto return stack
                LDA     2,X             ; limit
                PHA                     ; push limit onto return stack
                POP                     ; index
                PHA                     ; push index onto return stack
                DROP
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; ?DO Compilation: ( C: -- leave-addr loop-addr CS_DO_LOOP )
; Interpretation: Undefined.
; Like DO but skips the loop if limit = index at runtime.
; https://forth-standard.org/standard/core/qDO
;------------------------------------------------------------------------------
        HEADER  "?DO", QDO_ENTRY, QDO_CFA, F_IMMEDIATE, DOQDO_ENTRY
        CODEPTR DOCOL
        .word   LIT_CFA
        .word   DOQDO_CFA
        .word   COMMA_CFA              ; compile (?DO)
        .word   HERE_CFA               ; push leave-addr placeholder address
        .word   ZERO_CFA
        .word   COMMA_CFA              ; compile placeholder leave target
        .word   HERE_CFA               ; push loop-addr
        .word   LIT_CFA
        .word   CS_DO_LOOP             ; push security number
        .word   EXIT_CFA               ; stack: ( leave-addr loop-addr CS_DO_LOOP )

;------------------------------------------------------------------------------
; LOOP Compilation: ( C: leave-addr loop-addr CS_DO_LOOP -- )
; Append DOLOOP to the current defintion, pop and compile back branch test
; and target. Patch the LEAVE target in the DO byte code section.
; https://forth-standard.org/standard/core/LOOP
;------------------------------------------------------------------------------
        HEADER  "LOOP", LOOP_ENTRY, LOOP_CFA, F_IMMEDIATE, QDO_ENTRY
        CODEPTR DOCOL
        .word   LIT_CFA
        .word   CS_DO_LOOP
        .word   QPAIRS_CFA             ; verify security number
        .word   LIT_CFA
        .word   DOLOOP_CFA
        .word   COMMA_CFA              ; compile (LOOP)
        .word   COMMA_CFA              ; compile loop-addr as branch target
        .word   HERE_CFA               ; ( leave-addr here )
        .word   SWAP_CFA               ; ( here leave-addr )
        .word   STORE_CFA              ; backpatch LEAVE placeholder
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; +LOOP Compilation: ( C: leave-addr loop-addr CS_DO_LOOP -- )
; https://forth-standard.org/standard/core/PlusLOOP
;------------------------------------------------------------------------------
        HEADER  "+LOOP", PLUSLOOP_ENTRY, PLUSLOOP_CFA, F_IMMEDIATE, LOOP_ENTRY
        CODEPTR DOCOL
        .word   LIT_CFA
        .word   CS_DO_LOOP
        .word   QPAIRS_CFA             ; verify security number
        .word   LIT_CFA
        .word   DOPLUSLOOP_CFA
        .word   COMMA_CFA              ; compile (+LOOP)
        .word   COMMA_CFA              ; compile loop-addr as branch target
        .word   HERE_CFA               ; ( leave-addr here )
        .word   SWAP_CFA               ; ( here leave-addr )
        .word   STORE_CFA              ; backpatch LEAVE placeholder
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; https://forth-standard.org/standard/core/LEAVE
;------------------------------------------------------------------------------
        HEADER  "LEAVE", LEAVE_ENTRY, LEAVE_CFA, 0, PLUSLOOP_ENTRY
        CODEPTR LEAVE_CODE
        PUBLIC  LEAVE_CODE
        .a16
        .i16
                PLA                     ; Discard index
                PLA                     ; Discard limit
                PLY                     ; Load new IP (leave target)
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; RECURSE ( -- ) Compiles a pointer of the current word into itself.
; See: recursive
;------------------------------------------------------------------------------
        HEADER  "RECURSE", RECURSE_ENTRY, RECURSE_CFA, F_IMMEDIATE, LEAVE_ENTRY
        CODEPTR DOCOL
        .word   CURDEF_CFA
        .word   FETCH_CFA              ; ( cfa )
        .word   COMMA_CFA              ; compile into definition
        .word   EXIT_CFA

;==============================================================================
; SECTION 14: Pictured numeric output conversion words.
;==============================================================================

;------------------------------------------------------------------------------
; UD/MOD ( d-low d-high u -- rem quot-low quot-high ) non-standard helper for
; pictured I/O. Used to divide a double by a base to get a digit to print and
; the next quotient to divide.
;------------------------------------------------------------------------------
        HEADER  "UD/MOD", UDIVMOD_ENTRY, UDIVMOD_CFA, 0, RECURSE_ENTRY
        CODEPTR DOCOL
        .word   TOR_CFA                ; ( d-low d-high ) R: ( u )
        .word   ZERO_CFA               ; ( d-low d-high 0 )
        .word   RFETCH_CFA             ; ( d-low d-high 0 u ) R: ( u )
        .word   UMSLASHMOD_CFA         ; ( d-low rem quot-high ) R: ( u )
        ; rem is remainder from high division, used as high cell for low div
        .word   RFROM_CFA              ; ( d-low rem quot-high u )
        .word   SWAP_CFA               ; ( d-low rem u quot-high )
        .word   TOR_CFA                ; ( d-low rem u ) R: ( quot-high )
        .word   UMSLASHMOD_CFA         ; ( rem quot-low ) R: ( quot-high )
        .word   RFROM_CFA              ; ( rem quot-low quot-high )
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; <# ( -- ) Initialize the pictured numeric output conversion process.
; https://forth-standard.org/standard/core/num-start
;------------------------------------------------------------------------------
        HEADER  "<#", LESSHASH_ENTRY, LESSHASH_CFA, 0, UDIVMOD_ENTRY
        CODEPTR DOCOL
        .word   LIT_CFA
        .word   PAD_END                ; End of the PAD buffer
        .word   HLD_CFA                ; ( end-addr HLD-addr )
        .word   STORE_CFA
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; HOLD ( char -- ) insert char into pictured numeric output string
; https://forth-standard.org/standard/core/HOLD
;------------------------------------------------------------------------------
        HEADER  "HOLD", HOLD_ENTRY, HOLD_CFA, 0, LESSHASH_ENTRY
        CODEPTR DOCOL
        .word   HLD_CFA                ; ( char hld-addr )
        .word   FETCH_CFA              ; ( char hld )
        .word   ONEMINUS_CFA           ; ( char hld-1 )
        .word   DUP_CFA                ; ( char hld-1 hld-1 )
        .word   HLD_CFA                ; ( char hld-1 hld-1 hld-addr )
        .word   STORE_CFA              ; HLD = HLD -1
        .word   CSTORE_CFA             ; store char at new HLD
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; HOLDS ( c-addr u -- )
; https://forth-standard.org/standard/core/HOLDS
;------------------------------------------------------------------------------
        HEADER  "HOLDS", HOLDS_ENTRY, HOLDS_CFA, 0, HOLD_ENTRY
        CODEPTR DOCOL
HOLDS_LOOP:
        .word   DUP_CFA
        .word   ZBRANCH_CFA
        .word   HOLDS_DONE
        .word   ONEMINUS_CFA
        .word   TWODUP_CFA
        .word   PLUS_CFA
        .word   CFETCH_CFA
        .word   HOLD_CFA
        .word   BRANCH_CFA
        .word   HOLDS_LOOP
HOLDS_DONE:
        .word   TWODROP_CFA
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; # ( ud -- ud ) format one digit
;------------------------------------------------------------------------------
        HEADER  "#", HASH_ENTRY, HASH_CFA, 0, HOLDS_ENTRY
        CODEPTR DOCOL
        .word   BASE_CFA
        .word   FETCH_CFA              ; ( ud base )
        .word   UDIVMOD_CFA            ; ( rem quot-low quot-high )
        .word   ROT_CFA                ; ( quot-low quot-high rem )
        .word   DUP_CFA                ; ( quot-low quot-high rem rem )
        .word   LIT_CFA
        .word   9
        .word   GREATER_CFA            ; ( quot-low quot-high rem flag )
        .word   ZBRANCH_CFA
        .word   HASH_DIGIT
        .word   LIT_CFA
        .word   7
        .word   PLUS_CFA
HASH_DIGIT:
        .word   LIT_CFA
        .word   '0'
        .word   PLUS_CFA               ; ( quot-low quot-high char )
        .word   HOLD_CFA               ; ( quot-low quot-high )
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; #S ( ud -- 0 0 ) format all digits
;------------------------------------------------------------------------------
        HEADER  "#S", HASHS_ENTRY, HASHS_CFA, 0, HASH_ENTRY
        CODEPTR DOCOL
HASHS_LOOP:
        .word   HASH_CFA               ; ( ud )
        .word   TWODUP_CFA             ; ( ud ud )
        .word   OR_CFA                 ; ( ud flag )
        .word   ZEROEQ_CFA             ; ( ud flag ) true if both zero
        .word   ZBRANCH_CFA            ; branch back if not done
        .word   HASHS_LOOP
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; SIGN ( n -- ) if n negative prepend minus sign
;------------------------------------------------------------------------------
        HEADER  "SIGN", SIGN_ENTRY, SIGN_CFA, 0, HASHS_ENTRY
        CODEPTR DOCOL
        .word   ZEROLESS_CFA           ; ( flag )
        .word   ZBRANCH_CFA
        .word   SIGN_DONE
        .word   LIT_CFA
        .word   '-'
        .word   HOLD_CFA
SIGN_DONE:
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; #> ( ud -- c-addr u ) finalize pictured numeric output
;------------------------------------------------------------------------------
        HEADER  "#>", HASHGT_ENTRY, HASHGT_CFA, 0, SIGN_ENTRY
        CODEPTR DOCOL
        .word   TWODROP_CFA            ; ( ) discard ud
        .word   HLD_CFA
        .word   FETCH_CFA              ; ( c-addr )
        .word   LIT_CFA
        .word   PAD_END                ; ( c-addr PAD_END )
        .word   OVER_CFA               ; ( c-addr PAD_END c-addr )
        .word   MINUS_CFA              ; ( c-addr u )
        .word   EXIT_CFA

;==============================================================================
; SECTION 15: The Programming-Tools word set
;==============================================================================

;------------------------------------------------------------------------------
; ENVIRONMENT? ( c-addr u -- false | i * x true ) c-addr is the address of a
; character string and u is the string's character count. This is the text
; of an environment query which isn't generally used in embedded systems.
; Stubbed out with FALSE for compatibility.
; https://forth-standard.org/standard/core/ENVIRONMENTq
;------------------------------------------------------------------------------
        HEADER  "ENVIRONMENT?", ENVIRONMENTQ_ENTRY, ENVIRONMENTQ_CFA, 0, HASHGT_ENTRY
        CODEPTR DOCOL
        .word   TWODROP_CFA            ; discard c-addr u
        .word   FALSE_CFA              ; false - not supported
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; FORGET ( "<spaces>name" -- ) skips leading space delimiters. Parse name
; delimited by a space. Find name, then delete name from the dictionary along
; with all words added to the dictionary after name.
; Prints an error if the name can not be found.
;------------------------------------------------------------------------------
	HEADER  "FORGET", FORGET_ENTRY, FORGET_CFA, 0, ENVIRONMENTQ_ENTRY
        CODEPTR DOCOL
        .word   PARSENAME_CFA          ; ( c-addr u )
        .word   TWODUP_CFA             ; ( c-addr u c-addr u )
        .word   HERE_CFA               ; ( c-addr u c-addr u here )
        .word   PLACE_CFA              ; ( c-addr u ) uppercased copy at HERE
        .word   TWODROP_CFA            ; ( )
        .word   HERE_CFA               ; ( here )
        .word   COUNT_CFA              ; ( c-addr' u ) uppercased string
        .word   LATEST_CFA
        .word   FETCH_CFA              ; ( c-addr' u entry )
FORGET_LOOP:
        ; Check for end of dictionary
        .word   DUP_CFA                ; ( c-addr u entry entry )
        .word   ZBRANCH_CFA            ; branch if entry = 0 (not found)
        .word   FORGET_NOTFOUND

        ; Stash entry, duplicate c-addr u, get name, compare
        .word   TOR_CFA                ; ( c-addr u ) R: ( entry )
        .word   TWODUP_CFA             ; ( c-addr u c-addr u ) R: ( entry )
        .word   RFETCH_CFA             ; ( c-addr u c-addr u entry ) R: ( entry )
        .word   HEADERNAME_CFA         ; ( c-addr u c-addr u c-addr2 u2 ) R: ( entry )
        .word   COMPARE_CFA            ; ( c-addr u flag ) R: ( entry )
        .word   ZEROEQ_CFA             ; ( c-addr u match ) R: ( entry )
        .word   RFROM_CFA              ; ( c-addr u match entry ) R: ( )
        .word   SWAP_CFA               ; ( c-addr u entry match )
        .word   ZBRANCH_CFA
        .word   FORGET_NEXT

        ; Match found - clean up c-addr u then update LATEST and DP
        .word   TWOSWAP_CFA            ; ( entry c-addr u )
        .word   TWODROP_CFA            ; ( entry )
        .word   DUP_CFA                ; ( entry entry )
        .word   FETCH_CFA              ; ( entry link )
        .word   LATEST_CFA
        .word   STORE_CFA              ; LATEST = link
        .word   DP_CFA
        .word   STORE_CFA              ; DP = entry
        .word   EXIT_CFA

FORGET_NEXT:
        ; No match - follow link to next entry
        ; Stack: ( c-addr u entry )
        .word   FETCH_CFA              ; ( c-addr u link )
        .word   BRANCH_CFA
        .word   FORGET_LOOP

FORGET_NOTFOUND:
        ; Stack: ( c-addr u entry ) entry=0
        .word   DROP_CFA               ; ( c-addr u )
        .word   TWODROP_CFA            ; ( )
        .word   LIT_CFA
        .word   notfound_msg
        .word   CPUTS_CFA
        .word   ABORT_CFA
        .word   EXIT_CFA

notfound_msg:
        .byte   "Word not found", $0D, $0A, $00

;------------------------------------------------------------------------------
; MARKER ( "<spaces>name" -- ) creates a word that when executed restores
; the dictionary to its state at the time MARKER was called, including
; removing the marker word itself.
;------------------------------------------------------------------------------
        HEADER  "MARKER", MARKER_ENTRY, MARKER_CFA, 0, FORGET_ENTRY
        CODEPTR DOCOL
        ; Capture dictionary state BEFORE creating the new word.
        ; saved LATEST and DP are the restore point — marker erases itself.
        .word   LATEST_CFA
        .word   FETCH_CFA              ; ( latest )
        .word   DP_CFA
        .word   FETCH_CFA              ; ( latest dp )
        ; Parse name and build header. WORD leaves counted string at HERE,
        ; then DOCREATE consumes its address.
        .word   LIT_CFA
        .word   SPACE                  ; space delimiter
        .word   WORD_CFA               ; ( latest dp addr )
        .word   DOCREATE_CFA           ; ( latest dp ) header built, DP at CFA
        ; Patch CFA of new word to DOMARKER
        .word   DP_CFA
        .word   FETCH_CFA              ; ( latest dp cfa )
        .word   LIT_CFA
        .word   DOMARKER_CODE
        .word   SWAP_CFA
        .word   STORE_CFA              ; CFA = DOMARKER ( latest dp )
        ; Advance DP past CFA cell
        .word   DP_CFA
        .word   FETCH_CFA              ; ( latest dp dp )
        .word   CELLPLUS_CFA           ; ( latest dp dp+2 )
        .word   DP_CFA
        .word   STORE_CFA              ; DP += 2 ( latest dp )
        .word   REVEAL_CFA             ; make word visible
        ; Compile saved state into body
        .word   SWAP_CFA               ; ( dp latest )
        .word   COMMA_CFA              ; body[0] = saved LATEST
        .word   COMMA_CFA              ; body[1] = saved DP
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; DOMARKER - runtime action of a MARKER-created word.
; Body layout at CFA+2: [ saved_LATEST | saved_DP ]
; Restores LATEST and DP, erasing the marker and all words defined after it.
;------------------------------------------------------------------------------
        PUBLIC  DOMARKER_CODE
        .a16
        .i16
DOMARKER_CODE:
                PHY
                ; Restore LATEST from body[0] (CFA + CELL_SIZE)
                LDY     #CELL_SIZE
                LDA     (W),Y
                LDY     #U_LATEST
                STA     (UP),Y
                ; Restore DP from body[1] (CFA + CELL_SIZE*2)
                LDY     #CELL_SIZE * 2
                LDA     (W),Y
                LDY     #U_DP
                STA     (UP),Y
                PLY
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; SEE ( "<spaces>name" -- ) skips leading space delimiters. Parse name
; delimited by a space. Find name in dictionary, then print its definition
; or "primitive" if its assembly.
; Prints an error if the name can not be found.
;------------------------------------------------------------------------------
        HEADER  "SEE", SEE_ENTRY, SEE_CFA, 0, MARKER_ENTRY
        CODEPTR DOCOL
        ; Parse name, uppercase into HERE
        .word   PARSENAME_CFA          ; ( c-addr u )
        .word   TWODUP_CFA             ; ( c-addr u c-addr u )
        .word   HERE_CFA
        .word   PLACE_CFA              ; uppercase copy at HERE
        .word   TWODROP_CFA            ; ( )
        .word   HERE_CFA

        ; Find the word
        .word   FIND_CFA               ; ( xt 1|-1 | addr 0 )
        .word   DUP_CFA                ; ( xt 1|-1 1|-1 | addr 0 0 )
        .word   ZBRANCH_CFA
        .word   SEE_NOTFOUND
        .word   DROP_CFA               ; ( xt ) drop flag

        ; Print ": NAME "
        .word   LIT_CFA
        .word   colon_msg
        .word   CPUTS_CFA              ; print ": "
        .word   DUP_CFA                ; ( xt xt )
        .word   CFANAME_CFA            ; ( xt c-addr u true | xt false )
        .word   ZBRANCH_CFA
        .word   SEE_NONAME
        .word   TYPE_CFA               ; ( xt )
        .word   SPACE_CFA
        .word   BRANCH_CFA
        .word   SEE_CHECKTYPE

SEE_NONAME:
        .word   LIT_CFA
        .word   unknown_msg
        .word   CPUTS_CFA               ; ( xt )

SEE_CHECKTYPE:
        ; Check if DOCOL or primitive
        .word   DUP_CFA                ; ( xt xt )
        .word   FETCH_CFA              ; ( xt code-ptr )
        .word   LIT_CFA
        .word   DOCOL
        .word   EQUAL_CFA              ; ( xt flag )
        .word   ZBRANCH_CFA
        .word   SEE_PRIMITIVE

        ; DOCOL word - walk cells from xt+2
        .word   CELLPLUS_CFA           ; ( scan-ptr = xt+2 )

SEE_LOOP:
        .word   DUP_CFA                ; ( scan-ptr scan-ptr )
        .word   FETCH_CFA              ; ( scan-ptr cell )

        ; Check EXIT
        .word   DUP_CFA                ; ( scan-ptr cell cell )
        .word   LIT_CFA
        .word   EXIT_CFA
        .word   EQUAL_CFA              ; ( scan-ptr cell flag )
        .word   ZBRANCH_CFA
        .word   SEE_NOT_EXIT
        .word   TWODROP_CFA            ; ( )
        .word   LIT_CFA
        .word   exit_msg
        .word   CPUTS_CFA
        .word   CR_CFA
        .word   EXIT_CFA

SEE_NOT_EXIT:
        ; Check LIT
        .word   DUP_CFA                ; ( scan-ptr cell cell )
        .word   LIT_CFA
        .word   LIT_CFA
        .word   EQUAL_CFA              ; ( scan-ptr cell flag )
        .word   ZBRANCH_CFA
        .word   SEE_NOT_LIT
        .word   DROP_CFA               ; ( scan-ptr )
        .word   CELLPLUS_CFA           ; ( scan-ptr+2 )
        .word   DUP_CFA                ; ( scan-ptr+2 scan-ptr+2 )
        .word   FETCH_CFA              ; ( scan-ptr+2 value )
        .word   LIT_CFA
        .word   lit_msg
        .word   CPUTS_CFA
        .word   DOT_CFA                ; print value
        .word   SPACE_CFA
        .word   CELLPLUS_CFA           ; advance past value
        .word   BRANCH_CFA
        .word   SEE_LOOP

SEE_NOT_LIT:
        ; Check BRANCH
        .word   DUP_CFA                ; ( scan-ptr cell cell )
        .word   LIT_CFA
        .word   BRANCH_CFA
        .word   EQUAL_CFA              ; ( scan-ptr cell flag )
        .word   ZBRANCH_CFA
        .word   SEE_NOT_BRANCH
        .word   DROP_CFA               ; ( scan-ptr )
        .word   CELLPLUS_CFA           ; ( scan-ptr+2 )
        .word   DUP_CFA                ; ( scan-ptr+2 scan-ptr+2 )
        .word   FETCH_CFA              ; ( scan-ptr+2 target )
        .word   LIT_CFA
        .word   branch_msg
        .word   CPUTS_CFA
        .word   DOTHEX_CFA
        .word   SPACE_CFA
        .word   CELLPLUS_CFA           ; advance past target
        .word   BRANCH_CFA
        .word   SEE_LOOP

SEE_NOT_BRANCH:
        ; Check ZBRANCH
        .word   DUP_CFA                ; ( scan-ptr cell cell )
        .word   LIT_CFA
        .word   ZBRANCH_CFA
        .word   EQUAL_CFA              ; ( scan-ptr cell flag )
        .word   ZBRANCH_CFA
        .word   SEE_NOT_ZBRANCH
        .word   DROP_CFA               ; ( scan-ptr )
        .word   CELLPLUS_CFA           ; ( scan-ptr+2 )
        .word   DUP_CFA                ; ( scan-ptr+2 scan-ptr+2 )
        .word   FETCH_CFA              ; ( scan-ptr+2 target )
        .word   LIT_CFA
        .word   zbranch_msg
        .word   CPUTS_CFA
        .word   DOTHEX_CFA
        .word   SPACE_CFA
        .word   CELLPLUS_CFA           ; advance past target
        .word   BRANCH_CFA
        .word   SEE_LOOP

SEE_NOT_ZBRANCH:
        ; General case - look up CFA name
        .word   DROP_CFA               ; ( scan-ptr ) drop cell
        .word   DUP_CFA                ; ( scan-ptr scan-ptr )
        .word   FETCH_CFA              ; ( scan-ptr cell )
        .word   CFANAME_CFA            ; ( scan-ptr c-addr u true | scan-ptr false )
        .word   ZBRANCH_CFA
        .word   SEE_UNKNOWN
        .word   TYPE_CFA               ; ( scan-ptr ) print name
        .word   SPACE_CFA
        .word   CELLPLUS_CFA           ; advance scan-ptr
        .word   BRANCH_CFA
        .word   SEE_LOOP

SEE_UNKNOWN:
        ; Unknown CFA - print hex value
        .word   DUP_CFA                ; ( scan-ptr scan-ptr )
        .word   FETCH_CFA              ; ( scan-ptr cell )
        .word   DOTHEX_CFA             ; print hex
        .word   SPACE_CFA
        .word   CELLPLUS_CFA           ; advance scan-ptr
        .word   BRANCH_CFA
        .word   SEE_LOOP

SEE_PRIMITIVE:
        .word   DROP_CFA               ; ( ) drop xt
        .word   LIT_CFA
        .word   primitive_msg
        .word   CPUTS_CFA
        .word   CR_CFA
        .word   EXIT_CFA

SEE_NOTFOUND:
        .word   TWODROP_CFA            ; drop addr and 0
        .word   LIT_CFA
        .word   notfound_msg
        .word   CPUTS_CFA
        .word   ABORT_CFA
        .word   EXIT_CFA

colon_msg:      .byte ": ", $00
exit_msg:       .byte "EXIT ;", $00
lit_msg:        .byte "LIT ", $00
branch_msg:     .byte "BRANCH ", $00
zbranch_msg:    .byte "0BRANCH ", $00
primitive_msg:  .byte "primitive", $00
unknown_msg:    .byte "??? ", $00
;notfound_msg:   .byte "Word not found", $0D, $0A, $00

.ifdef DEBUG
;------------------------------------------------------------------------------
; TRACEOUT ( -- ) Prints current IP to console in hex.
;------------------------------------------------------------------------------
        .importzp TRACE_EN
        PUBLIC  TRACEOUT
        .a16
        .i16
                LDA     a:TRACE_EN
                BEQ     @done           ; FORTH_FALSE = 0, skip if off
                TYA                     ; Print IP (Y) as 4-digit hex
                JSR     hal_putchex
                LDA     #SPACE
                JSR     hal_putch
@done:          RTS
        ENDPUBLIC

;------------------------------------------------------------------------------
; TRACEON ( -- ) enable execution tracing
;------------------------------------------------------------------------------
        HEADER  "TRACEON", TRACEON_ENTRY, TRACEON_CFA, 0, SEE_ENTRY
        CODEPTR TRACEON_CODE
        PUBLIC  TRACEON_CODE
        .a16
        .i16
                LDA     #FORTH_TRUE
                STA     TRACE_EN
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; TRACEOFF ( -- ) disable execution tracing
;------------------------------------------------------------------------------
        HEADER  "TRACEOFF", TRACEOFF_ENTRY, TRACEOFF_CFA, 0, TRACEON_ENTRY
        CODEPTR TRACEOFF_CODE
        PUBLIC  TRACEOFF_CODE
        .a16
        .i16
                LDA     #FORTH_FALSE
                STA     TRACE_EN
                NEXT
        ENDPUBLIC
.endif

;==============================================================================
; LAST_WORD - must be the ENTRY of the final word defined above
; Used by FORTH_INIT to seed LATEST
;==============================================================================
.ifdef DEBUG
	LAST_WORD = TRACEOFF_ENTRY
.else
	LAST_WORD = SEE_ENTRY
.endif
