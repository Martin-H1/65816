;==============================================================================
; NUMBER ( addr -- n flag )
;
; Convert a counted string at addr to a signed integer using the current BASE.
; flag is TRUE ($FFFF) on success, FALSE ($0000) on error. The counted string
; format is the format produced by WORD.
;
; Supported input:
;   Optional leading '-' for negation
;   Digits 0-9, A-F (uppercase) interpreted in current BASE
;   Any digit >= BASE, or unrecognised character, causes failure
;   Empty string (length = 0) causes failure
;
; Stack effect: ( addr -- n TRUE ) on success
;               ( addr -- addr FALSE ) on failure [addr preserved for error msg]
;==============================================================================

        HEADER  "NUMBER", NUMBER_ENTRY, NUMBER_CFA, 0, ACCEPT_ENTRY
        CODEPTR NUMBER_CODE
        PUBLIC  NUMBER_CODE
        .a16
        .i16

        LOC_COUNT   = 1         ; hw stack offset for character count
        LOC_PTR     = 3         ; hw stack offset for current char pointer
        LOC_SIGN    = 5         ; hw stack offset for sign value
        LOC_BASE    = 7         ; hw stack offset for base value
        LOC_RESULT  = 9         ; hw stack offset for result
        LOC_PRODUCT = 11        ; hw stack offset for product
        LOC_SIZE = LOC_PRODUCT + 1

                PHD                     ; Save DP
                PHY                     ; Save IP

                TSC                     ; Reserve space for stack locals
                SEC
                SBC     #LOC_SIZE
                TCS
                TCD                     ; No page zero access until return!

                ;----------------------------------------------------------
                ; Fetch BASE using UP page zero pointer into LOC_BASE
                ;----------------------------------------------------------
                LDY     #UP
                LDA     a:0,Y           ; Initialize pointer to user area
                STA     LOC_PTR         ; Borrow pointer to hold UP
                LDY     #U_BASE
                LDA     (LOC_PTR),Y     ; BASE
                STA     LOC_BASE        ; LOC_BASE = BASE
                STZ     LOC_SIGN        ; LOC_SIGN = 0, assume positive
                STZ     LOC_RESULT      ; Initial value is zero.

                ;----------------------------------------------------------
                ; Load address, read length byte, set up char pointer.
                ;----------------------------------------------------------
                LDA     a:0,X           ; addr (counted string)
                STA     LOC_PTR

                SEP     #$20            ; 8-bit for byte fetch
                .a8
                LDA     (LOC_PTR)       ; length byte
                REP     #$20
                .a16
                AND     #$00FF
                BEQ     @fail_return    ; Empty string -> fail
                STA     LOC_COUNT       ; LOC_COUNT = character count

                ; Advance pointer to first character (addr+1)
                INC     LOC_PTR

                ;----------------------------------------------------------
                ; Check for leading '-'.
                ;----------------------------------------------------------
                SEP     #$20
                .a8
                LDA     (LOC_PTR)       ; Peek at first char
                REP     #$20
                .a16
                AND     #$00FF
                CMP     #'-'
                BNE     @digit_loop

                ; Leading minus: set sign, advance pointer, decrement count
                DEC     LOC_SIGN        ; Was 0, now -1, sign = negative
                INC     LOC_PTR         ; advance char pointer
                DEC     LOC_COUNT       ; one fewer char to process
                BEQ     @fail_return    ; '-' alone is not a valid number

                ;----------------------------------------------------------
                ; Digit conversion loop.
                ;----------------------------------------------------------
@digit_loop:
                ; Fetch current character
                SEP     #$20
                .a8
                LDA     (LOC_PTR)
                REP     #$20
                .a16
                AND     #$00FF

                ; Convert ASCII to digit value
                CMP     #'0'
                BCC     @fail_return    ; < '0' -> invalid
                CMP     #'9' + 1
                BCC     @is_decimal
                CMP     #'A'
                BCC     @fail_return    ; between '9' and 'A' -> invalid
                CMP     #'F' + 1
                BCS     @fail_return    ; > 'F' -> invalid
                ; Hex letter A-F
                SEC
                SBC     #'A' - 10       ; A->10, B->11, ... F->15
                BRA     @check_base

@is_decimal:
                SEC
                SBC     #'0'            ; '0'->0 ... '9'->9

@check_base:
                ; Digit value is in A. Reject if >= BASE.
                CMP     LOC_BASE        ; digit - BASE
                BCS     @fail_return    ; digit >= BASE -> invalid

                ; RESULT = RESULT * BASE + digit
                ; Multiply by using repeated addition
                PHA                     ; Save digit on hw stack temporarily.

                ; Multiply: use Y as loop counter (IP already saved)
                LDY     LOC_BASE
                STZ     LOC_PRODUCT     ; product accumulator = 0
@mul_loop:
                LDA     LOC_PRODUCT
                CLC
                ADC     LOC_RESULT      ; product += LOC_RESULT
                STA     LOC_PRODUCT
                DEY
                BNE     @mul_loop

                ; PRODUCT = T * BASE; add digit
                PLA                     ; digit back into A
                CLC
                ADC     LOC_PRODUCT
                STA     LOC_RESULT

                ; Advance pointer and loop
                INC     LOC_PTR
                DEC     LOC_COUNT
                BNE     @digit_loop

                ;----------------------------------------------------------
                ; All digits processed successfully.
                ; Apply sign.
                ;----------------------------------------------------------
                LDA     LOC_SIGN        ; sign flag
                BEQ     @positive
                ; Negate result
                LDA     LOC_RESULT
                EOR     #$FFFF
                INC     A
                STA     LOC_RESULT
@positive:
                ; Replace TOS (addr) with result, push TRUE flag
                LDA     LOC_RESULT
                STA     a:0,X           ; TOS = result using absolute addressing
                LDA     #$FFFF          ; TRUE
                BRA     @return

                ;----------------------------------------------------------
                ; Failure path: leave original addr on stack, push FALSE.
                ;----------------------------------------------------------
@fail_return:
                ; addr is still at 0,X (untouched), set status FALSE
                LDA     #0              ; FALSE

@return:        DEX
                DEX
                STA     a:0,X           ; Push status code
                ; Tear down hw stack locals, restore IP and DP
                TSC                     ; Drop locals
                CLC
                ADC     #LOC_SIZE
                TCS
                PLY                     ; Restore IP
                PLD                     ; Restore DP
                NEXT
        ENDPUBLIC
