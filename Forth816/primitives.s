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
; DUP ( a -- a a )
;------------------------------------------------------------------------------
        HEADER  "DUP", DUP_ENTRY, DUP_CFA, 0, 0
        CODEPTR DUP_CODE
        PUBLIC  DUP_CODE
        .a16
        .i16
                LDA     0,X             ; Load TOS
                DEX
                DEX
                STA     0,X             ; Push copy
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; DROP ( a -- )
;------------------------------------------------------------------------------
        HEADER  "DROP", DROP_ENTRY, DROP_CFA, 0, DUP_ENTRY
        CODEPTR DROP_CODE
        PUBLIC  DROP_CODE
        .a16
        .i16
                INX
                INX
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
                LDA     0,X             ; b (TOS)
                STA     SCRATCH0
                LDA     2,X             ; a (NOS)
                STA     0,X             ; TOS = a
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
                DEX
                DEX
                STA     0,X             ; Push copy of a
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
                LDA     0,X             ; b (TOS)
                INX
                INX
                STA     0,X             ; Overwrite a with b
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
                INX
                INX
                INX
                INX
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
; DEPTH ( -- n ) number of items on parameter stack
;------------------------------------------------------------------------------
        HEADER  "DEPTH", DEPTH_ENTRY, DEPTH_CFA, 0, TWOOVER_ENTRY
        CODEPTR DEPTH_CODE
        PUBLIC  DEPTH_CODE
        .a16
        .i16
                JSR     calc_depth
                DEX
                DEX
                STA     0,X
                NEXT

calc_depth:     TXA
                EOR     #$FFFF          ; Two's complement
                INC     A
                CLC
                ADC     #PSP_INIT       ; PSP_INIT - result / 2
                LSR     A               ; Divide by 2 (cells)
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

;==============================================================================
; SECTION 2: RETURN STACK PRIMITIVES
;==============================================================================

;------------------------------------------------------------------------------
; >R ( a -- ) (R: -- a)
;------------------------------------------------------------------------------
        HEADER  ">R", TOR_ENTRY, TOR_CFA, 0, PICK_ENTRY
        CODEPTR TOR_CODE
        PUBLIC  TOR_CODE
        .a16
        .i16
                LDA     0,X             ; Pop from parameter stack
                INX
                INX
                PHA                     ; Push onto return stack
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
                PLA                     ; Pop from return stack
                DEX
                DEX
                STA     0,X             ; Push onto parameter stack
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
                ; Pop to read the value, immediately push back,
                ; then A still holds the value for the parameter stack.
                PLA                     ; Pop R@ value (A = value)
                PHA                     ; Push it back (return stack unchanged)
                DEX
                DEX
                STA     0,X             ; Push copy onto parameter stack
                NEXT
        ENDPUBLIC

;==============================================================================
; SECTION 3: ARITHMETIC PRIMITIVES
;==============================================================================

;------------------------------------------------------------------------------
; + ( a b -- a+b )
;------------------------------------------------------------------------------
        HEADER  "+", PLUS_ENTRY, PLUS_CFA, 0, RFETCH_ENTRY
        CODEPTR PLUS_CODE
        PUBLIC  PLUS_CODE
        .a16
        .i16
                LDA     0,X             ; b
                CLC
                ADC     2,X             ; a + b
                INX
                INX
                STA     0,X             ; Replace with result
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; - ( a b -- a-b )
;------------------------------------------------------------------------------
        HEADER  "-", MINUS_ENTRY, MINUS_CFA, 0, PLUS_ENTRY
        CODEPTR MINUS_CODE
        PUBLIC  MINUS_CODE
        .a16
        .i16
                LDA     2,X             ; a
                SEC
                SBC     0,X             ; a - b
                INX
                INX
                STA     0,X
                NEXT
        ENDPUBLIC

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
        HEADER  "*", STAR_ENTRY, STAR_CFA, 0, MINUS_ENTRY
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
        CODEPTR SLASHMOD_CODE
        PUBLIC  SLASHMOD_CODE
        .a16
        .i16
                JSR     SLASHMOD_IMPL
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; SLASHMOD_IMPL  –  signed 16÷16 → 16r 16q   ANS Forth floored division
; Called via JSR from /MOD and MOD.
;
; Entry stack:
;   0,X = n2  (divisor,  signed 16-bit)
;   2,X = n1  (dividend, signed 16-bit)
;
; Exit stack:
;   0,X = quotient   (floored toward −∞)
;   2,X = remainder  (sign matches divisor)
;
; ANS floored vs. truncated:
;   Truncated: remainder has sign of dividend.
;   Floored:   remainder has sign of divisor; quotient is floor(n1/n2).
;   When signs of n1 and n2 differ AND remainder ≠ 0:
;     floored_quot = truncated_quot - 1
;     floored_rem  = truncated_rem  + n2
;
; Method:
;   1. Save original signed n1, n2 on hardware stack.
;   2. Take |n1|, |n2|; call UMSLASHMOD_IMPL for unsigned truncated division.
;   3. Apply floored-division sign correction.
;
; Hardware stack frame after PHY + two PHA:
;   1,S = n2  (saved divisor,  pushed last)
;   3,S = n1  (saved dividend, pushed first)
;   5,S = saved IP (pushed by PHY)
;------------------------------------------------------------------------------
        PUBLIC  SLASHMOD_IMPL
        .a16
        .i16

        SDIV_N1 = 3                     ; offset to saved n1 in hardware stack
        SDIV_N2 = 1                     ; offset to saved n2

                ; Step 1: save originals on hardware stack
                LDA     2,X             ; n1 (dividend)
                PHA                     ; → 3,S
                LDA     0,X             ; n2 (divisor)
                PHA                     ; → 1,S

                ; Step 2: replace stack values with absolute values
                LDA     2,X             ; n1
                BPL     @n1_pos
                EOR     #$FFFF
                INC     A               ; |n1|
@n1_pos:        STA     2,X

                LDA     0,X             ; n2
                BPL     @n2_pos
                EOR     #$FFFF
                INC     A               ; |n2|
@n2_pos:        STA     0,X

                ; Step 3: build ( divisor ud_high ud_low ) for UMSLASHMOD_IMPL
                DEX
                DEX                     ; allocate one new cell
                LDA     2,X             ; |n2| = divisor
                STA     0,X             ; divisor at 0,X
                STZ     2,X             ; ud_high = 0
                ; Result: 0,X=|n2|  2,X=0  4,X=|n1|

                ; Step 4: unsigned division
                JSR     UMSLASHMOD_IMPL

                ; 0,X = |quot|, 2,X = |rem| on entry to sign correction

                ; Step 5: quotient sign
                LDA     SDIV_N1,S
                EOR     SDIV_N2,S
                BPL     @quot_positive
                LDA     0,X             ; quot
                BEQ     @quot_positive
                EOR     #$FFFF
                INC     A
                STA     0,X
@quot_positive:
                ; Step 6: remainder sign (negate if dividend negative)
                LDA     SDIV_N1,S
                BPL     @rem_positive
                LDA     2,X             ; rem
                BEQ     @rem_positive
                EOR     #$FFFF
                INC     A
                STA     2,X
@rem_positive:
                ; Step 7: floor correction
                LDA     SDIV_N1,S
                EOR     SDIV_N2,S
                BPL     @done
                LDA     2,X             ; remainder (signed)
                BEQ     @done
                DEC     0,X             ; quot -= 1
                LDA     2,X
                CLC
                ADC     SDIV_N2,S       ; rem += n2
                STA     2,X
@done:
                ; 0,X=rem 2,X=quot
                PLA
                PLA
                RTS
        ENDPUBLIC

;------------------------------------------------------------------------------
; / ( n1 n2 -- quot ) signed division
;------------------------------------------------------------------------------
        HEADER  "/", SLASH_ENTRY, SLASH_CFA, 0, SLASHMOD_ENTRY
        CODEPTR SLASH_CODE
        PUBLIC  SLASH_CODE
        .a16
        .i16
                JSR     SLASHMOD_IMPL
                LDA     0,X             ; b (TOS)
                INX
                INX
                STA     0,X             ; Overwrite a with b
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; MOD ( n1 n2 -- rem )
;------------------------------------------------------------------------------
        HEADER  "MOD", MOD_ENTRY, MOD_CFA, 0, SLASH_ENTRY
        CODEPTR MOD_CODE
        PUBLIC  MOD_CODE
        .a16
        .i16
                JSR     SLASHMOD_IMPL
                INX
                INX
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; NEGATE ( n -- -n )
;------------------------------------------------------------------------------
        HEADER  "NEGATE", NEGATE_ENTRY, NEGATE_CFA, 0, MOD_ENTRY
        CODEPTR NEGATE_CODE
        PUBLIC  NEGATE_CODE
        .a16
        .i16
                LDA     0,X
                EOR     #$FFFF
                INC     A
                STA     0,X
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
                LDA     0,X
                BPL     @done
                EOR     #$FFFF
                INC     A
                STA     0,X
@done:          NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; MAX ( a b -- max )
;------------------------------------------------------------------------------
        HEADER  "MAX", MAX_ENTRY, MAX_CFA, 0, ABS_ENTRY
        CODEPTR MAX_CODE
        PUBLIC  MAX_CODE
        .a16
        .i16
                LDA     2,X             ; a
                CMP     0,X             ; a - b (signed)
                BPL     @endif          ; a >= b, a is max
                LDA     0,X             ; a < b, overwrite a with b
                STA     2,X
@endif:         INX                     ; Drop TOS as NOS is max
                INX
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
@endif:         INX                     ; Drop TOS as NOS is min
                INX
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
                LDA     0,X
                ; Arithmetic shift right: preserve sign bit
                CMP     #$8000          ; Set carry if negative
                ROR     A               ; Shift right, sign bit from carry
                STA     0,X
                NEXT
        ENDPUBLIC

;==============================================================================
; SECTION 4: COMPARISON PRIMITIVES
; ANS Forth: TRUE = $FFFF, FALSE = $0000
;==============================================================================

;------------------------------------------------------------------------------
; = ( a b -- flag )
;------------------------------------------------------------------------------
        HEADER  "=", EQUAL_ENTRY, EQUAL_CFA, 0, TWOSLASH_ENTRY
        CODEPTR EQUAL_CODE
        PUBLIC  EQUAL_CODE
        .a16
        .i16
                LDA     0,X
                INX
                INX
                CMP     0,X
                BEQ     @true
                STZ     0,X
                NEXT
@true:          LDA     #$FFFF
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
                LDA     0,X
                INX
                INX
                CMP     0,X
                BNE     @true
                STZ     0,X
                NEXT
@true:          LDA     #$FFFF
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
                LDA     #$0000          ; Set TOS to false
                BRA     @return
@overflow:
                BPL     @true           ; overflow + positive result = a<b
@false:         LDA     #$0000          ; Set TOS to false
                BRA     @return
@true:          LDA     #$FFFF          ; Set TOS to true
@return:
                INX                     ; Drop b
                INX
                STA     0,X             ; Set TOS to result
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
                LDA     #$0000          ; Set TOS to false
                BRA     @return
@overflow:
                BPL     @true
@false:         LDA     #$0000          ; Set TOS to false
                BRA     @return
@true:          LDA     #$FFFF          ; Set TOS to true
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
@true:          LDA     #$FFFF
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
@true:          LDA     #$FFFF
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
                LDA     #$FFFF
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
                LDA     #$FFFF
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
@true:          LDA     #$FFFF
                STA     0,X
                NEXT
        ENDPUBLIC

;==============================================================================
; SECTION 5: LOGIC PRIMITIVES
;==============================================================================

;------------------------------------------------------------------------------
; AND ( a b -- a&b )
;------------------------------------------------------------------------------
        HEADER  "AND", AND_ENTRY, AND_CFA, 0, ZEROGT_ENTRY
        CODEPTR AND_CODE
        PUBLIC  AND_CODE
        .a16
        .i16
                LDA     0,X
                INX
                INX
                AND     0,X
                STA     0,X
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
                LDA     0,X
                INX
                INX
                ORA     0,X
                STA     0,X
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
                LDA     0,X
                INX
                INX
                EOR     0,X
                STA     0,X
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
                LDA     0,X
                EOR     #$FFFF
                STA     0,X
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
; 2@ ( addr -- d ) fetch double cell (low at addr, high at addr+2)
;------------------------------------------------------------------------------
        HEADER  "2@", TWOFETCH_ENTRY, TWOFETCH_CFA, 0, CSTORE_ENTRY
        CODEPTR TWOFETCH_CODE
        PUBLIC  TWOFETCH_CODE
        .a16
        .i16
                LDA     0,X             ; addr
                STA     SCRATCH0
                LDA     (SCRATCH0)      ; low cell
                STA     SCRATCH1
                LDA     SCRATCH0
                CLC
                ADC     #2
                STA     SCRATCH0
                LDA     (SCRATCH0)      ; high cell
                DEX
                DEX
                STA     0,X             ; TOS = high
                LDA     SCRATCH1
                STA     2,X             ; NOS = low
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; 2! ( d addr -- ) store double cell
;------------------------------------------------------------------------------
        HEADER  "2!", TWOSTORE_ENTRY, TWOSTORE_CFA, 0, TWOFETCH_ENTRY
        CODEPTR TWOSTORE_CODE
        PUBLIC  TWOSTORE_CODE
        .a16
        .i16
                LDA     0,X             ; peek addr → SCRATCH0
                STA     SCRATCH0
                CLC
                ADC     #2              ; addr+2 → SCRATCH1 (carry now clear)
                STA     SCRATCH1
                LDA     2,X             ; low cell of d
                STA     (SCRATCH0)      ; store at addr
                LDA     4,X             ; high cell of d
                STA     (SCRATCH1)      ; store at addr+2
                TXA
                ADC     #6              ; drop 3 cells (carry still clear from above)
                TAX
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; MOVE ( src dst u -- ) copy u bytes from src to dst
;------------------------------------------------------------------------------
        HEADER  "MOVE", MOVE_ENTRY, MOVE_CFA, 0, TWOSTORE_ENTRY
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

;==============================================================================
; SECTION 7: UART I/O PRIMITIVES
;==============================================================================

;------------------------------------------------------------------------------
; EMIT ( char -- ) transmit character via HAL
;------------------------------------------------------------------------------
        HEADER  "EMIT", EMIT_ENTRY, EMIT_CFA, 0, FILL_ENTRY
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
; CR ( -- ) emit carriage return + line feed via HAL
;------------------------------------------------------------------------------
        HEADER  "CR", CR_ENTRY, CR_CFA, 0, TYPE_ENTRY
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
                LDA     0,Y             ; Fetch literal value at IP
                INY
                INY                     ; Advance IP past literal
                DEX
                DEX
                STA     0,X             ; Push literal
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; BRANCH ( -- ) unconditional branch (compiled word)
; The cell following BRANCH contains the branch offset (signed)
;------------------------------------------------------------------------------
        HEADER  "BRANCH", BRANCH_ENTRY, BRANCH_CFA, F_HIDDEN, LIT_ENTRY
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
                LDA     0,X             ; step
                INX
                INX
                STA     SCRATCH1
                PLA                     ; index
                CLC
                ADC     SCRATCH1        ; index + step
                STA     SCRATCH0
                PLA                     ; limit
                ; Check if we crossed limit
                ; Done when (index-limit) XOR (new_index-limit) sign differs
                CMP     SCRATCH0
                BEQ     @done           ; index == limit → done
                STA     TMPA            ; Save limit
                PHA                     ; Push limit back
                LDA     SCRATCH0
                PHA                     ; Push new index back
                LDA     0,Y             ; Branch back
                TAY
                NEXT
@done:          INY
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
                ; Return stack: TOS=index NOS=limit NOS2=saved_IP
                ; Pop index, copy, push back
                PLA                     ; index
                PHA                     ; Push back
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
                ; Return stack (top to bottom):
                ;   inner_index, inner_limit, saved_IP, outer_index, outer_limit
                ; Pop 4 cells to get to outer index
                PLA                     ; inner index
                STA     SCRATCH0
                PLA                     ; inner limit
                STA     SCRATCH1
                PLA                     ; saved IP
                STA     TMPA
                PLA                     ; outer index
                STA     TMPB
                ; Push them all back
                PHA                     ; outer index back
                LDA     TMPA
                PHA
                LDA     SCRATCH1
                PHA
                LDA     SCRATCH0
                PHA
                ; Push outer index to param stack
                LDA     TMPB
                DEX
                DEX
                STA     0,X
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
; , ( val -- ) compile cell into dictionary
;------------------------------------------------------------------------------
        HEADER  ",", COMMA_ENTRY, COMMA_CFA, 0, ALLOT_ENTRY
        CODEPTR COMMA_CODE
        PUBLIC  COMMA_CODE
        .a16
        .i16
                PHY
                LDY     #U_DP
                LDA     (UP),Y          ; DP → SCRATCH0
                STA     SCRATCH0
                CLC                     ; DP += 2
                ADC     #2
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
; LATEST ( -- addr ) address of LATEST variable in user area
;------------------------------------------------------------------------------
        HEADER  "LATEST", LATEST_ENTRY, LATEST_CFA, 0, CCOMMA_ENTRY
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
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; PAD ( -- addr ) address of scratch pad area.
;------------------------------------------------------------------------------
        HEADER  "PAD", PAD_ENTRY, PAD_CFA, 0, SOURCE_ENTRY
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

;==============================================================================
; SECTION 11: STRING AND PARSE WORDS
;==============================================================================

;------------------------------------------------------------------------------
; COUNT ( addr -- addr+1 len ) counted string to addr/len
;------------------------------------------------------------------------------
        HEADER  "COUNT", COUNT_ENTRY, COUNT_CFA, 0, PAD_ENTRY
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
; PARSE ( char -- c-addr u )
;------------------------------------------------------------------------------
        HEADER  "PARSE", PARSE_ENTRY, PARSE_CFA, 0, COUNT_ENTRY
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
; (S") runtime ( -- c-addr u )
; IP points to length cell followed by string bytes.
; Pushes c-addr and u, advances IP past string data.
;------------------------------------------------------------------------------
DOSQUOTE_ENTRY:
        .word   PARSE_ENTRY            ; Link field
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
; S"
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
        .word   LIT_CFA
        .word   0
        .word   DODO_CFA                ; runtime DO  ( limit index -- )
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
DOTQUOTE_ENTRY:
        .word   SQUOTE_ENTRY            ; Link field
        .byte   F_HIDDEN | 3            ; Flags + length (3 chars)
        .byte   $28, $2E, $22           ; '(' '.' '"'
        .align  2
DOTQUOTE_CFA:
        CODEPTR DOTQUOTE_CODE
        PUBLIC  DOTQUOTE_CODE
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
; ." ( -- )
; https://forth-standard.org/standard/core/Dotq
;------------------------------------------------------------------------------
DOTQUOTE_OUTER_ENTRY:
        .word   DOTQUOTE_ENTRY          ; Link field
        .byte   F_IMMEDIATE | 2         ; Flags + length (2 chars)
        .byte   $2E, $22                ; '.' '"'
        .align  2
DOTQUOTE_OUTER_CFA:
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
        .word   DOTQUOTE_CFA            ; compile (.")
        .word   COMMA_CFA
        .word   TWODUP_CFA              ; ( c-addr u c-addr u )
        .word   NIP_CFA                 ; ( c-addr u u )
        .word   COMMA_CFA               ; compile u
        .word   LIT_CFA
        .word   0
        .word   DODO_CFA                ; loop u times
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
; 
; 
;------------------------------------------------------------------------------
DABORTQUOTE_ENTRY:
        .word   DOTQUOTE_ENTRY          ; Link field
        .byte   F_HIDDEN | 8            ; Flags + length (7 chars)
        .byte   "(ABORT", $22, ")"      ; '(' 'A' 'B' 'O' 'R' 'T' '"' ')'
        .align  2
DABORTQUOTE_CFA:
        CODEPTR DABORTQUOTE_CODE
        PUBLIC  DABORTQUOTE_CODE
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
; 
; 
;------------------------------------------------------------------------------
ABORTQUOTE_ENTRY:
        .word   DABORTQUOTE_ENTRY       ; Link field
        .byte   F_IMMEDIATE | 6         ; Flags + length (6 chars)
        .byte   "ABORT", $22            ; 'A' 'B' 'O' 'R' 'T' '"'
        .align  2
ABORTQUOTE_CFA:
        CODEPTR DOCOL
        .word   LIT_CFA
        .word   '"'
        .word   PARSE_CFA               ; ( c-addr u )
        .word   LIT_CFA
        .word   DABORTQUOTE_CFA         ; compile (ABORT")
        .word   COMMA_CFA
        .word   TWODUP_CFA              ; ( c-addr u c-addr u )
        .word   NIP_CFA                 ; ( c-addr u u )
        .word   COMMA_CFA               ; compile u
        .word   LIT_CFA
        .word   0
        .word   DODO_CFA
ABORTQUOTE_CLOOP:
        .word   DUP_CFA
        .word   I_CFA
        .word   PLUS_CFA
        .word   CFETCH_CFA
        .word   CCOMMA_CFA
        .word   DOLOOP_CFA
        .word   ABORTQUOTE_CLOOP
        .word   DROP_CFA
        .word   ALIGN_CFA
        .word   EXIT_CFA

HEADER  "CHAR", CHAR_ENTRY, CHAR_CFA, 0, ABORTQUOTE_ENTRY
        CODEPTR DOCOL
        .word   LIT_CFA
        .word   ' '
        .word   WORD_CFA                ; ( c-addr ) counted string
        .word   LIT_CFA
        .word   1
        .word   PLUS_CFA                ; ( c-addr+1 ) skip length byte
        .word   CFETCH_CFA              ; ( char ) first character
        .word   EXIT_CFA

HEADER  "[CHAR]", BRACKCHAR_ENTRY, BRACKCHAR_CFA, F_IMMEDIATE, CHAR_ENTRY
        CODEPTR DOCOL
        .word   CHAR_CFA                ; ( char )
        .word   LIT_CFA
        .word   LIT_CFA
        .word   COMMA_CFA               ; compile LIT
        .word   COMMA_CFA               ; compile char value
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; WORD ( char -- addr ) parse word delimited by char from input
; Returns counted string at HERE
;
; Stack frame locals (offsets from S after frame is built):
;   LOC_IDX   = 1,S   parse index (>IN)
;   LOC_LEN   = 3,S   source length
;   LOC_TIB   = 5,S   TIB base address
;   LOC_HERE  = 7,S   HERE (output buffer)
;   LOC_DELIM = 9,S   delimiter char
;   LOC_DST   = 11,S  destination pointer.
;   LOC_UP    = 13,S  local UP
;   (saved IP at 15,S, pushed first by PHY)
;------------------------------------------------------------------------------
        HEADER  "WORD", WORD_ENTRY, WORD_CFA, 0, BRACKCHAR_ENTRY
        CODEPTR WORD_CODE
        PUBLIC  WORD_CODE
        .a16
        .i16
                LOC_IDX   = 1
                LOC_LEN   = 3
                LOC_TIB   = 5
                LOC_HERE  = 7
                LOC_DELIM = 9
                LOC_DEST  = 11
                LOC_UP    = 13
                LOC_SIZE  = LOC_UP + 1

                ; --- Save DP, IP, and set up stack frame ---
                PHD                     ; Save DP (at 13,S after frame built)
                PHY                     ; Save IP (at 11,S after frame built)
                TSC
                SEC
                SBC     #LOC_SIZE
                TCS
                TCD                     ; Set Direct Page to stack frame

                ; Push delimiter (popped from parameter stack)
                LDA     a:0,X           ; Peek TOS to get delimiter
                STA     LOC_DELIM

                LDA     a:UP            ; Initialize pointer to user area
                STA     LOC_UP

                ; Push HERE
                LDY     #U_DP
                LDA     (LOC_UP),Y      ; HERE
                STA     LOC_HERE

                ; Push TIB base
                LDY     #U_TIB
                LDA     (LOC_UP),Y      ; TIB base
                STA     LOC_TIB

                ; Push source length
                LDY     #U_SOURCELEN
                LDA     (LOC_UP),Y      ; source length
                STA     LOC_LEN

                ; Push parse index (>IN)
                LDY     #U_TOIN
                LDA     (LOC_UP),Y      ; >IN
                STA     LOC_IDX
                TAY                     ; Use Y as the parse index during loops

                ; --- Skip leading delimiters ---
@skip_loop:
                CPY     LOC_LEN         ; If Y >= source length then input end
                BCC     @otherwise

                SEP     #$20            ; Return HERE with zero-length counted string
                .a8
                LDA     #0
                LDY     #0
                STA     (LOC_HERE),Y    ; Zero count byte at HERE
                REP     #$20
                .a16
                BRA     @return         ; Tear down frame and return

@otherwise:
                SEP     #$20
                .a8
                LDA     (LOC_TIB),Y     ; Fetch TIB[index]
                REP     #$20
                .a16
                AND     #$00FF
                CMP     LOC_DELIM       ; Is it the delimiter?
                BNE     @found_start    ; No - start of word found
                INY                     ; Increment parse index
                BRA     @skip_loop

                ; --- Copy word characters to HERE+1 ---
@found_start:
                ; Set up destination: HERE+1 (past the count byte)
                LDA     LOC_HERE
                INC     A               ; dest = HERE+1
                STA     LOC_DEST
                PHX
                LDX     #$0000          ; Borrow X for char count = 0
@copy:
                CPY     LOC_LEN         ; parse index >= source length?
                BCS     @copy_done      ; End of input

                SEP     #$20
                .a8
                LDA     (LOC_TIB),Y     ; Fetch TIB[index]
                REP     #$20
                .a16
                AND     #$00FF
                CMP     LOC_DELIM       ; Is it the delimiter?
                BEQ     @copy_done      ; Yes - end of word

                ; ANS Forth 1994 requires case-insensitivity for standards
                ; words, uppercasing input before dictionary lookup.
                CMP     #'a'
                BCC     @not_lower
                CMP     #'z'+1
                BCS     @not_lower
                AND     #$DF            ; Clear bit 5 = convert to uppercase
@not_lower:
                ; Store char at dest
                SEP     #$20
                .a8
                STA     (LOC_DEST)
                REP     #$20
                .a16
                INC     LOC_DEST        ; Advance dest pointer
                INX                     ; Increment char count
                INY                     ; Advance parse index
                BRA     @copy

@copy_done:
                ; Skip the trailing delimiter if not at end
                CPY     LOC_LEN
                BCS     @store_count
                INY                     ; Consume trailing delimiter

@store_count:
                ; Store count byte at HERE
                STY     LOC_IDX         ; Update LOC_IDX with Y contents.
                TXA                     ; char count
                PLX                     ; Restore X
                SEP     #$20
                .a8
                STA     (LOC_HERE)      ; Store count byte at HERE
                REP     #$20
                .a16

                ; Update >IN in user area
                LDY     #U_TOIN
                LDA     LOC_IDX
                STA     (LOC_UP),Y      ; >IN

@return:
                LDA     LOC_HERE
                STA     a:0,X           ; Put HERE onto parameter stack TOS

                ; --- Tear down stack frame and return to interpreter ---
                TSC                     ; Drop locals
                CLC
                ADC    #LOC_SIZE
                TCS
                PLY                     ; Restore IP
                PLD                     ; Restore DP
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; DECIMAL ( -- ) set numeric base to 10
;------------------------------------------------------------------------------
        HEADER  "DECIMAL", DECIMAL_ENTRY, DECIMAL_CFA, 0, WORD_ENTRY
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
; TODO: ud is currently 16-bit single cell. Upgrade to true 32-bit double
;       when double number support is added.
;------------------------------------------------------------------------------
        HEADER  ">NUMBER", TONUMBER_ENTRY, TONUMBER_CFA, 0, HEX_ENTRY
        CODEPTR TONUMBER_CODE
        PUBLIC  TONUMBER_CODE
        .a16
        .i16

        LOC_U       = 1         ; character count
        LOC_ADDR    = 3         ; current char pointer
        LOC_UDHI    = 5         ; high cell of ud (0 until double support)
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
                BEQ     @done           ; u = 0, done

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

                ; ud = ud * BASE + digit
                ; First: ud_lo * BASE via UM*
                PHA                     ; save digit on hw stack

                DEX                     ; push ud_lo
                DEX
                LDA     LOC_UDLO
                STA     a:0,X
                DEX                     ; push BASE
                DEX
                LDA     LOC_BASE
                STA     a:0,X

                PHD
                LDA     #$0000          ; set Direct Page to $0000
                TCD
                LDY     #RTS_CFA_LIST   ; Use the RTS_CFA trampoline.
                JSR     UMSTAR_CODE     ; ( ud_lo ud_hi )
                PLD

                ; Add digit to low cell, propagate carry to high cell
                PLA                     ; restore digit
                CLC
                ADC     a:2,X           ; add to ud_lo (NOS)
                STA     LOC_UDLO
                BCC     @no_carry
                INC     LOC_UDHI        ; carry into ud_hi (TOS)
@no_carry:
                INX
                INX
                INX
                INX                     ; clean up UM* result from stack

                ; Advance pointer, decrement count
                INC     LOC_ADDR
                DEC     LOC_U
                BRA     @digit_loop

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
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; NUMBER? ( c-addr -- n true | c-addr false )
; Handles prefixes: - (negative), $ (hex), # (decimal), % (binary)
; Restores BASE after conversion.
;------------------------------------------------------------------------------
        HEADER  "NUMBER?", NUMBERQ_ENTRY, NUMBERQ_CFA, 0, TONUMBER_ENTRY
        CODEPTR NUMBERQ_CODE
        PUBLIC  NUMBERQ_CODE
        .a16
        .i16

        LOC_ADDR    = 1         ; original c-addr (for fail return)
        LOC_PTR     = 3         ; current char pointer
        LOC_COUNT   = 5         ; remaining character count
        LOC_SIGN    = 7         ; 0=positive, $FFFF=negative
        LOC_BASE    = 9         ; saved original BASE
        LOC_TMPBASE = 11        ; working base for this conversion
        LOC_UP      = 13        ; local UP to avoid refetching
        LOC_SIZE    = LOC_UP + 1

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

                SEP     #$20
                .a8
                LDA     (LOC_ADDR)      ; length byte
                REP     #$20
                .a16
                AND     #$00FF
                BNE     @skip
                JMP     @fail_return    ; empty string -> fail
@skip:          STA     LOC_COUNT

                ; Advance past length byte
                LDA     LOC_ADDR
                INC     A
                STA     LOC_PTR

                ;--------------------------------------------------------------
                ; Cache BASE, init working base and sign
                ;--------------------------------------------------------------
                LDA     a:UP
                STA     LOC_UP
                LDY     #U_BASE
                LDA     (LOC_UP),Y
                STA     LOC_BASE        ; save original BASE
                STA     LOC_TMPBASE     ; working base defaults to BASE
                STZ     LOC_SIGN        ; assume positive

                ;--------------------------------------------------------------
                ; Check for prefix characters
                ;--------------------------------------------------------------
                SEP     #$20
                .a8
                LDA     (LOC_PTR)       ; peek first char
                REP     #$20
                .a16
                AND     #$00FF

                CMP     #'-'
                BNE     @check_dollar
                DEC     LOC_SIGN        ; 0 -> $FFFF = negative

                INC     LOC_PTR         ; Consume '-' char, advance pointer
                DEC     LOC_COUNT       ; one fewer char to process
                BEQ     @fail_return    ; '-' alone is not a valid number

                SEP     #$20
                .a8
                LDA     (LOC_PTR)       ; peek next char
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
                BEQ     @fail_return    ; prefix alone is not valid

                ; Handle minus after base prefix (e.g. $-FF not supported,
                ; but -$ is already handled above)

@no_prefix:
                ;--------------------------------------------------------------
                ; Temporarily write working base into BASE in user area
                ;--------------------------------------------------------------
                LDY     #U_BASE
                LDA     LOC_TMPBASE
                STA     (LOC_UP),Y      ; BASE = working base

                ;--------------------------------------------------------------
                ; Set up stack for >NUMBER: ( 0 0 c-addr u )
                ; We need 4 cells below current TOS.
                ; Current TOS (0,X) = original c-addr, replace with u
                ; then push c-addr, ud_hi, ud_lo below.
                ;--------------------------------------------------------------
                LDA     #0
                STA     a:0,X           ; ud_lo
                DEX
                DEX
                STA     a:0,X           ; stack: ( ud_lo ud_hi c-addr u )
                DEX
                DEX
                LDA     LOC_PTR         ; c-addr
                STA     a:0,X
                DEX
                DEX
                LDA     LOC_COUNT       ; u
                STA     a:0,X           ; TOS = u
                LDY     #RTS_CFA_LIST   ; RTS Trampoline
                JSR     TONUMBER_CODE   ; ( ud_lo ud_hi c-addr u )

                ;--------------------------------------------------------------
                ; Restore original BASE
                ;--------------------------------------------------------------
                LDY     #U_BASE
                LDA     LOC_BASE
                STA     (LOC_UP),Y

                ;--------------------------------------------------------------
                ; Check u = 0 (all chars consumed = success)
                ;--------------------------------------------------------------
                LDA     a:0,X           ; u
                TAY
                INX                     ; drop u
                INX
                INX                     ; drop c-addr
                INX
                INX                     ; drop ud_hi (single cell for now)
                INX
                TYA                     ; TOS = ud_lo = result
                BNE     @fail_return    ; unconverted chars remain -> fail

                ;--------------------------------------------------------------
                ; Apply sign
                ;--------------------------------------------------------------
                LDA     LOC_SIGN
                BEQ     @positive
                LDA     a:0,X
                EOR     #$FFFF
                INC     A
                STA     a:0,X
@positive:
                LDA     #FORTH_TRUE
                BRA     @return

@fail_return:
                LDA     LOC_ADDR        ; original c-addr
                STA     a:0,X           ; restore TOS
                LDA     #0              ; FALSE

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
        .word   LIT_CFA
        .word   0                       ; 0 = interpret
        .word   STORE_CFA              ; STATE = 0

        ; Main REPL loop
QUIT_LOOP:
        .word   TIB_CFA                 ; Push TIB address
        .word   LIT_CFA
        .word   TIB_SIZE                ; Max input length
        .word   ACCEPT_CFA              ; Read line → ( len )
        .word   LIT_CFA
        .word   UP_BASE + U_SOURCELEN
        .word   STORE_CFA               ; Store length in user area
        .word   LIT_CFA
        .word   0
        .word   LIT_CFA
        .word   UP_BASE + U_TOIN
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

; TIB - push TIB base address
        HEADER  "TIB", TIB_ENTRY, TIB_CFA, 0, RSP_RESET_ENTRY
        CODEPTR TIB_PRIM_CODE
        PUBLIC  TIB_PRIM_CODE
        .a16
        .i16
                LDA     UP
                CLC
                ADC     #U_TIB
                STA     SCRATCH0
                LDA     (SCRATCH0)
                DEX
                DEX
                STA     0,X
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
        HEADER  "ACCEPT", ACCEPT_ENTRY, ACCEPT_CFA, 0, TIB_ENTRY
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
                ADC     #2              ; Point to flags|len byte
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
; UNDEFINED-WORD ( addr -- ) print error message and abort
; Called when INTERPRET cannot find or convert a word.
;------------------------------------------------------------------------------
        HEADER  "UNDEFINED-WORD", UNDEFINED_WORD_ENTRY, UNDEFINED_WORD_CFA, 0, FIND_ENTRY
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
        .word   LIT_CFA
        .word   ' '                     ; space delimiter
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
; . (DOT) ( n -- ) print signed number
;------------------------------------------------------------------------------
        HEADER  ".", DOT_ENTRY, DOT_CFA, 0, INTERPRET_ENTRY
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
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; .HEX ( n -- ) print hexadecimal number
;------------------------------------------------------------------------------
        HEADER  ".HEX", DOTHEX_ENTRY, DOTHEX_CFA, 0, UDOT_ENTRY
        CODEPTR DOTHEX_CODE
        PUBLIC  DOTHEX_CODE
        .a16
        .i16
                ; Print TOS as 4-digit hex
                LDA     0,X
                INX
                INX
                JSR     print_chex
                LDA     #SPACE
                JSR     hal_putch
        NEXT

        ; print_ahex - prints lower eight bits of the accumulator in hex
        ; Inputs:
        ;   A - byte to print
        ; Outputs:
        ;   A - retained
	.proc print_ahex
                PHA
                PHA
                LSR
                LSR
                LSR
                LSR
                JSR @print_nybble
                PLA
                JSR @print_nybble
                PLA
                RTS

@print_nybble:
                AND #LOWNIB
                SED
                CLC
                ADC #$9990              ; Produce $90-$99 or $00-$05
                ADC #$9940              ; Produce $30-$39 or $41-$46
                CLD
                jmp hal_putch
        .endproc

        ; print_chex - prints C as a 16 bit hex number to the console.
        ; Inputs:
        ;   C - number
        ; Outputs:
        ;   C - preserved
        .proc print_chex
                PHA
                PHA
                XBA
                JSR print_ahex
                PLA
                JSR print_ahex
                PLA
                RTS
        .endproc

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
                BEQ     @skip           ; no items on stack.
                STA     SCRATCH0
                JSR     DOT_CODE::print_udec

@skip:          LDA     #@crlf
                JSR     hal_cputs
                NEXT
        @prompt: .asciiz "ok "
        @crlf: .byte C_RETURN, L_FEED, 0
        ENDPUBLIC

;------------------------------------------------------------------------------
; WORDS ( -- ) list all non-hidden words in the dictionary
;------------------------------------------------------------------------------
        HEADER  "WORDS", WORDS_ENTRY, WORDS_CFA, 0, DOT_PROMPT_ENTRY
        CODEPTR DOCOL

WORDS_BODY:
        .word   LATEST_CFA              ; ( addr-of-LATEST-var )
        .word   FETCH_CFA               ; ( entry )
WORDS_LOOP:
        .word   DUP_CFA                 ; ( entry entry )
        .word   LIT_CFA
        .word   2
        .word   PLUS_CFA                ; ( entry entry+2 )
        .word   CFETCH_CFA              ; ( entry flags+len )
        .word   LIT_CFA
        .word   F_HIDDEN
        .word   AND_CFA                 ; ( entry flags+len & F_HIDDEN )
        .word   ZEROEQ_CFA              ; ( entry flag ) true if not hidden
        .word   ZBRANCH_CFA
        .word   WORDS_SKIP
        .word   DUP_CFA                 ; ( entry entry )
        .word   LIT_CFA
        .word   3
        .word   PLUS_CFA                ; ( entry entry+3 ) skip link+flags byte
        .word   DUP_CFA                 ; ( entry entry+3 entry+3 )
        .word   LIT_CFA
        .word   1
        .word   MINUS_CFA               ; ( entry entry+3 entry+2 )
        .word   CFETCH_CFA              ; ( entry entry+3 flags+len )
        .word   LIT_CFA
        .word   F_LENMASK
        .word   AND_CFA                 ; ( entry entry+3 len )
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
        HEADER  "(CREATE)", PCREATE_ENTRY, PCREATE_CFA, F_HIDDEN, WORDS_ENTRY
        CODEPTR PCREATE_CODE
        PUBLIC  PCREATE_CODE
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
                ADC     #2
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
                LDY     #2
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
; REVEAL ( -- ) clear F_HIDDEN on the most recent dictionary entry
;------------------------------------------------------------------------------
        HEADER  "REVEAL", REVEAL_ENTRY, REVEAL_CFA, 0, PCREATE_ENTRY
        CODEPTR REVEAL_CODE
        PUBLIC  REVEAL_CODE
        .a16
        .i16
                PHY                     ; Save IP
                ; Fetch LATEST
                LDY     #U_LATEST
                LDA     (UP),Y          ; LATEST
                ; flags byte is at LATEST+2
                CLC
                ADC     #2
                STA     SCRATCH0        ; point to flags byte
                SEP     #$20
                .a8
                LDA     (SCRATCH0)      ; read flags byte
                AND     #$FF ^ F_HIDDEN ; clear hidden bit
                STA     (SCRATCH0)      ; write back
                REP     #$20
                .a16
                PLY                     ; Restore IP
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; : ( -- ) parse name, create dictionary header, enter compile mode
;------------------------------------------------------------------------------
        HEADER  ":", COLON_ENTRY, COLON_CFA, 0, REVEAL_ENTRY
        CODEPTR DOCOL
COLON_BODY:
        .word   LIT_CFA
        .word   ' '
        .word   WORD_CFA                ; ( addr ) parse name from input
        .word   PCREATE_CFA             ; ( ) build header, update LATEST and DP
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
; VARIABLE ( -- ) parse name, create variable definition
; Runtime: pushes address of body cell onto stack
;------------------------------------------------------------------------------
        HEADER  "VARIABLE", VARIABLE_ENTRY, VARIABLE_CFA, 0, SEMICOLON_ENTRY
        CODEPTR DOCOL
VARIABLE_BODY:
        .word   LIT_CFA
        .word   ' '
        .word   WORD_CFA                ; ( addr ) parse name
        .word   PCREATE_CFA             ; ( ) build header
        .word   LIT_CFA
        .word   DOVAR                   ; code pointer for variables
        .word   COMMA_CFA               ; write DOVAR at CFA
        .word   LIT_CFA
        .word   0
        .word   COMMA_CFA               ; allot and initialize one cell
        .word   REVEAL_CFA              ; clear F_HIDDEN
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; CONSTANT ( n -- ) parse name, create constant definition
; Runtime: pushes stored value onto stack
;------------------------------------------------------------------------------
        HEADER  "CONSTANT", CONSTANT_ENTRY, CONSTANT_CFA, 0, VARIABLE_ENTRY
        CODEPTR DOCOL
CONSTANT_BODY:
        .word   LIT_CFA
        .word   ' '
        .word   WORD_CFA                ; ( n addr ) parse name
        .word   PCREATE_CFA             ; ( n ) build header
        .word   LIT_CFA
        .word   DOCON                   ; code pointer for constants
        .word   COMMA_CFA               ; write DOCON at CFA
        .word   COMMA_CFA               ; store constant value in body
        .word   REVEAL_CFA              ; clear F_HIDDEN
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; [ ( -- ) enter interpretation state (immediate)
; Sets STATE = 0
; https://forth-standard.org/standard/core/Bracket
;------------------------------------------------------------------------------
        HEADER  "[", LBRACKET_ENTRY, LBRACKET_CFA, F_IMMEDIATE, CONSTANT_ENTRY
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
; CREATE ( -- ) parse name, create dictionary entry with DOVAR behavior
; Runtime: created word pushes address of its body onto stack
;------------------------------------------------------------------------------
        HEADER  "CREATE", CREATE_ENTRY, CREATE_CFA, 0, COMPILECOMMA_ENTRY
        CODEPTR DOCOL
CREATE_BODY:
        .word   LIT_CFA
        .word   ' '
        .word   WORD_CFA                ; ( addr ) parse name
        .word   PCREATE_CFA             ; ( ) build header
        .word   LIT_CFA
        .word   DOVAR                   ; code pointer
        .word   COMMA_CFA               ; write DOVAR at CFA
        .word   LIT_CFA
        .word   0                       ; placeholder for DOES> code address
        .word   COMMA_CFA               ; reserve CFA+2 cell
        .word   REVEAL_CFA              ; clear F_HIDDEN
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; (DOES>) ( -- ) runtime helper compiled by DOES>
; Patches the most recently CREATED word to use DODOES behavior.
; W points to this word's CFA. IP (Y) points to the DOES> code.
;------------------------------------------------------------------------------
        HEADER  "(DOES>)", PDOES_ENTRY, PDOES_CFA, F_HIDDEN, CREATE_ENTRY
        CODEPTR PDOES_CODE
        PUBLIC  PDOES_CODE
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
                ADC     #2              ; point to flags byte
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
                LDY     #2
                STA     (SCRATCH0),Y    ; store DOES> code address

                ; EXIT the defining word - return to caller
                PLY                     ; pop outer saved IP from DOCOL
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; DOES> ( -- ) immediate: compile (DOES>) into current definition
;------------------------------------------------------------------------------
        HEADER  "DOES>", DOES_ENTRY, DOES_CFA, F_IMMEDIATE, PDOES_ENTRY
        CODEPTR DOCOL
DOES_BODY:
        .word   LIT_CFA
        .word   PDOES_CFA
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
        .word   LIT_CFA                 ; Space delimeter
        .word   ' '
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
; Append the run-time semantics given below to the current definition.
; An ambiguous condition exists if name is not found.
; Run-time: ( -- xt )
; Place name's execution token xt on the stack. The execution token returned by
; the compiled phrase "['] X" is the same value returned by "' X" outside of
; compilation state.
; https://forth-standard.org/standard/core/BracketTick
;------------------------------------------------------------------------------
        HEADER  "[']", BRACKETTICK_ENTRY, BRACKETTICK_CFA, F_IMMEDIATE, TICK_ENTRY
        CODEPTR DOCOL
        .word   TICK_CFA                ; execute ' -> xt on stack
        .word   LIT_CFA                 ; execute LIT -> pushes the next cell...
        .word   LIT_CFA                 ; ...which is the value LIT_CFA itself
        .word   COMMA_CFA               ; compile LIT_CFA into dictionary
        .word   COMMA_CFA               ; compile xt into dictionary
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; IF Interpretation: Undefined. Compilation: ( C: -- orig )
; Put the location of a new unresolved forward reference orig onto the control
; flow stack. Append the run-time semantics below to the current definition.
; The semantics are incomplete until orig is resolved by THEN or ELSE.
; Run-time: ( x -- )
; If all bits of x are zero, continue execution at the location specified by
; the resolution of orig.
; https://forth-standard.org/standard/core/IF
;------------------------------------------------------------------------------
        HEADER  "IF", IF_ENTRY, IF_CFA, F_IMMEDIATE, BRACKETTICK_ENTRY
        CODEPTR DOCOL
        .word   LIT_CFA                 ; compile ZBRANCH into definition
        .word   ZBRANCH_CFA
        .word   COMMA_CFA
        .word   HERE_CFA                ; push address of placeholder
        .word   LIT_CFA                 ; compile placeholder 0
        .word   0
        .word   COMMA_CFA
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; THEN Interpretation: Undefined. Compilation: ( C: orig --  )
; Append the run-time semantics given below to the current definition. Resolve
; the forward reference orig using the location of the appended run-time
; semantics.
; Run-time: ( -- )
; Continue execution.
; https://forth-standard.org/standard/core/THEN
;------------------------------------------------------------------------------
        HEADER  "THEN", THEN_ENTRY, THEN_CFA, F_IMMEDIATE, IF_ENTRY
        CODEPTR DOCOL
        .word   HERE_CFA                ; ( addr here )
        .word   SWAP_CFA                ; ( here addr )
        .word   STORE_CFA               ; backpatch placeholder
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; ELSE Interpretation: Undefined. Compilation: ( C: orig1 -- orig2 )
; Put the location of a new unresolved forward reference orig2 onto the control
; flow stack. Append the run-time semantics given below to the current
; definition. The semantics will be incomplete until orig2 is resolved by THEN.
; Resolve the forward reference orig1 using the location following the
; appended run-time semantics.
; Run-time: ( -- )
; Continue execution at the location given by the resolution of orig2.
; https://forth-standard.org/standard/core/ELSE
;------------------------------------------------------------------------------
        HEADER  "ELSE", ELSE_ENTRY, ELSE_CFA, F_IMMEDIATE, THEN_ENTRY
        CODEPTR DOCOL
        .word   LIT_CFA                 ; compile BRANCH into definition
        .word   BRANCH_CFA
        .word   COMMA_CFA
        .word   HERE_CFA                ; push address of new placeholder
        .word   LIT_CFA                 ; compile placeholder 0
        .word   0
        .word   COMMA_CFA
        .word   SWAP_CFA                ; ( new-addr if-addr )
        .word   HERE_CFA                ; ( new-addr if-addr here )
        .word   SWAP_CFA                ; ( new-addr here if-addr )
        .word   STORE_CFA              ; backpatch IF's placeholder
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; BEGIN Interpretation: Undefined. Compilation: ( C: -- dest )
; Put the next location for a transfer of control, dest, onto the control flow
; stack. Append the run-time semantics given below to the current definition.
; Run-time:( -- )
; Continue execution.
; https://forth-standard.org/standard/core/BEGIN
;------------------------------------------------------------------------------
        HEADER  "BEGIN", BEGIN_ENTRY, BEGIN_CFA, F_IMMEDIATE, ELSE_ENTRY
        CODEPTR DOCOL
        .word   HERE_CFA                ; push current DP as loop top
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; UNTIL Interpretation: Undefined. Compilation: ( C: dest -- )
; Append the run-time semantics given below to the current definition, resolving
; the backward reference dest.
; Run-time: ( x -- )
; If all bits of x are 0, continue execution at the location specified by dest.
; https://forth-standard.org/standard/core/UNTIL
;------------------------------------------------------------------------------
        HEADER  "UNTIL", UNTIL_ENTRY, UNTIL_CFA, F_IMMEDIATE, BEGIN_ENTRY
        CODEPTR DOCOL
        .word   LIT_CFA                 ; compile ZBRANCH
        .word   ZBRANCH_CFA
        .word   COMMA_CFA
        .word   COMMA_CFA               ; compile loop top address
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; WHILE Interpretation: Undefined. Compilation: ( C: dest -- orig dest )
; Put the location of a new unresolved forward reference orig onto the control
; flow stack, under the existing dest. Append the run-time semantics given
; below to the current definition. The semantics are incomplete until orig and
; dest are resolved (e.g., by REPEAT).
; Run-time: ( x -- )
; If all bits of x are zero, continue execution at the location specified by
; the resolution of orig.
; https://forth-standard.org/standard/core/WHILE
;------------------------------------------------------------------------------
HEADER  "WHILE", WHILE_ENTRY, WHILE_CFA, F_IMMEDIATE, UNTIL_ENTRY
        CODEPTR DOCOL
        .word   LIT_CFA                 ; compile ZBRANCH
        .word   ZBRANCH_CFA
        .word   COMMA_CFA
        .word   HERE_CFA                ; push placeholder address
        .word   LIT_CFA                 ; compile placeholder 0
        .word   0
        .word   COMMA_CFA
        .word   EXIT_CFA                ; stack: ( begin-addr while-addr )

;------------------------------------------------------------------------------
; REPEAT Interpretation: Undefined. Compilation: ( C: orig dest -- )
; Append the run-time semantics given below to the current definition,
; resolving the backward reference dest. Resolve the forward reference orig
; using the location following the appended run-time semantics.
; Run-time: ( -- )
; Continue execution at the location given by dest.
; https://forth-standard.org/standard/core/REPEAT
;------------------------------------------------------------------------------
HEADER  "REPEAT", REPEAT_ENTRY, REPEAT_CFA, F_IMMEDIATE, WHILE_ENTRY
        CODEPTR DOCOL
        .word   LIT_CFA                 ; compile BRANCH
        .word   BRANCH_CFA
        .word   COMMA_CFA
        .word   SWAP_CFA                ; ( while-addr begin-addr )
        .word   COMMA_CFA               ; compile begin-addr as branch target
        .word   HERE_CFA                ; ( while-addr here )
        .word   SWAP_CFA                ; ( here while-addr )
        .word   STORE_CFA               ; backpatch WHILE placeholder
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; DO Interpretation: Undefined. Compilation: ( C: -- do-sys )
; Place do-sys onto the control-flow stack. Append the run-time semantics given
; below to the current definition. The semantics are incomplete until resolved
; by a consumer of do-sys such as LOOP.
; Run-time: ( n1 | u1 n2 | u2 -- ) ( R: -- loop-sys )
; Set up loop control parameters with index n2 | u2 and limit n1 | u1.
; An ambiguous condition exists if n1 | u1 and n2 | u2 are not both the same
; type. Anything already on the return stack becomes unavailable until the
; loop-control parameters are discarded.
; https://forth-standard.org/standard/core/DO
;------------------------------------------------------------------------------
        HEADER  "DO", DO_ENTRY, DO_CFA, F_IMMEDIATE, REPEAT_ENTRY
        CODEPTR DOCOL
        .word   LIT_CFA                 ; compile (DO)
        .word   DODO_CFA
        .word   COMMA_CFA
        .word   HERE_CFA                ; push loop top address
        .word   EXIT_CFA

;------------------------------------------------------------------------------
; LOOP Interpretation: Undefined. Compilation: ( C: do-sys -- )
; Append the run-time semantics given below to the current definition. Resolve
; the destination of all unresolved occurrences of LEAVE between the location
; given by do-sys and the next location for a transfer of control, to execute
; the words following the LOOP.
; Run-time: ( -- ) ( R: loop-sys1 -- | loop-sys2 )
; An ambiguous condition exists if the loop control parameters are unavailable.
; Add one to the loop index. If the loop index is then equal to the loop limit,
; discard the loop parameters and continue execution immediately following the
; loop. Otherwise continue execution at the beginning of the loop.
; https://forth-standard.org/standard/core/LOOP
;------------------------------------------------------------------------------
        HEADER  "LOOP", LOOP_ENTRY, LOOP_CFA, F_IMMEDIATE, DO_ENTRY
        CODEPTR DOCOL
        .word   LIT_CFA                 ; compile (LOOP)
        .word   DOLOOP_CFA
        .word   COMMA_CFA
        .word   COMMA_CFA               ; compile loop top address
        .word   EXIT_CFA

;==============================================================================
; Stub declarations for words referenced in QUIT_BODY colon definition
; that are not yet implemented (WORDS, defining words etc.)
; These allow the project to assemble; implement fully in a later pass.
;==============================================================================

; Stub defining words - to be fully implemented

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
                JSR     DOTHEX_CODE::print_chex
                LDA     #SPACE
                JSR     hal_putch
@done:          RTS
        ENDPUBLIC

;------------------------------------------------------------------------------
; TRACEON ( -- ) enable execution tracing
;------------------------------------------------------------------------------
        HEADER  "TRACEON", TRACEON_ENTRY, TRACEON_CFA, 0, LOOP_ENTRY
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
	LAST_WORD = LOOP_ENTRY
.endif
