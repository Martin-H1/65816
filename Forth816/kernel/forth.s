;==============================================================================
; forth.s - 65816 ANS Forth Kernel (ITC)
;
; Architecture:
;   Threading:  Indirect Threaded Code (ITC)
;   Cell size:  16-bit
;   ROM:        Kernel primitives ($8000-$FFBF)
;   RAM:        Dictionary, stacks, user area
;
; Register conventions:
;   A  (16-bit) Working register / scratch
;   X  (16-bit) Parameter Stack Pointer (PSP) - points to TOS
;   Y  (16-bit) Instruction Pointer (IP)      - points to next CFA
;   S  (16-bit) Return Stack Pointer (RSP)    - hardware stack
;   D           Direct Page base ($0000)
;   DB          Data Bank ($00)
;
; ITC execution model:
;   Each word's Code Field contains the ADDRESS of a pointer.
;   That pointer holds the address of the actual machine code.
;
;   Dictionary entry layout:
;   +--------+-------+--------+-----+--------+-----------+
;   | LINK   | FLAGS | NAME.. | $00 | CFA    | body...   |
;   | 2 bytes| 1 byte| n bytes|     | 2 bytes| ...       |
;   +--------+-------+--------+-----+--------+-----------+
;                                    ^-- Code Field (CFA)
;                                        contains address of
;                                        code pointer
;==============================================================================

        .p816                   ; Enable 65816 instruction set
        .smart off              ; Manual size tracking (safer for Forth)

        .include "macros.inc"
        .include "dictionary.inc"

;------------------------------------------------------------------------------
; ZERO PAGE - Direct Page variables
; ca65 will use direct page addressing for these automatically
;------------------------------------------------------------------------------
        .segment "ZEROPAGE"

W:              .res 2          ; Working register (current CFA)
UP:             .res 2          ; User Pointer (base of user area)
RSP_INIT:       .res 2          ; RSP init value from ROM monitor or $01FF
SCRATCH0:       .res 2          ; General purpose scratch
SCRATCH1:       .res 2          ; General purpose scratch
TMPA:           .res 2          ; Temp for multiply/divide
TMPB:           .res 2          ; Temp for multiply/divide
.ifdef DEBUG
TRACE_EN:       .res 2                  ; Trace enable flag
.endif

; Export zero page symbols with .globalzp so other translation units
; use direct page addressing when referencing them
        .globalzp       W
        .globalzp       UP
        .globalzp       RSP_INIT
        .globalzp       SCRATCH0
        .globalzp       SCRATCH1
        .globalzp       TMPA
        .globalzp       TMPB
.ifdef DEBUG
        .globalzp       TRACE_EN
.endif
;------------------------------------------------------------------------------
; CONSTANTS - shared with primitives.s via include file
;------------------------------------------------------------------------------
        .include "constants.inc"

; Dictionary header flag bits are defined in dictionary.inc

;==============================================================================
; CODE SEGMENT - ROM kernel
;==============================================================================
        .segment "CODE"

;------------------------------------------------------------------------------
; INNER INTERPRETER
;
; NEXT - advance IP and jump through the code field pointer.
;
; This is inlined as a macro for speed. It performs:
;   1. Fetch cell at IP (Y) into W         W = *IP  (this is the CFA)
;   2. Advance IP by 2                     IP += 2
;   3. Fetch code pointer from W           temp = *W
;   4. Jump to that address
;
; Because Y is our IP and ca65/65816 doesn't have (Y) addressing,
; we use a small trampoline via SCRATCH0.
;------------------------------------------------------------------------------

; NEXT is defined as a macro in macros.inc and inlined into each primitive.

;------------------------------------------------------------------------------
; DOCOL - Code pointer for all colon (:) definitions
;
; On entry: W = CFA of the word being entered
; Action:   Push current IP (Y) onto return stack,
;           set IP to first cell of body (W+2),
;           then NEXT.
;------------------------------------------------------------------------------
        PUBLIC  DOCOL
        .a16
        .i16
                PHY                     ; Push IP onto return stack
                LDA     W               ; W = CFA of this word
                TAY                     ; IP = body start
                INY                     ; Body starts at CFA+2
                INY
                NEXT                    ; Execute first body word
        ENDPUBLIC

;------------------------------------------------------------------------------
; DOVAR - Code pointer for VARIABLE definitions
;
; Pushes the address of the variable body (CFA+2) onto parameter stack.
;------------------------------------------------------------------------------
        PUBLIC  DOVAR
        .a16
        .i16
                LDA     W               ; CFA
                CLC
                ADC     #2              ; Address of body
                DEX
                DEX
                STA     0,X             ; Push onto parameter stack
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; DOCON - Code pointer for CONSTANT definitions
;
; Pushes the value stored in the body (CFA+2) onto parameter stack.
;------------------------------------------------------------------------------
        PUBLIC  DOCON
        .a16
        .i16
                PHY
                LDY     #2
                LDA     (W),Y           ; Fetch constant value at CFA+2
                PLY
                DEX
                DEX
                STA     0,X             ; Push value
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; DODOES - Code pointer for DOES> defined words
;
; Pushes body address, then transfers control to the DOES> code.
; The DOES> code address is stored in the CFA+2 of the defining word.
;------------------------------------------------------------------------------
        PUBLIC  DODOES
        .a16
        .i16
                ; W = CFA of the created word
                ; CFA+0 = address of DODOES code pointer cell
                ; CFA+2 = address of DOES> code (stored by (DOES>))
                ; CFA+4 = body start (what we push onto param stack)

                ; Push IP to return stack (we're entering a colon-like context)
                PHY                     ; save current IP

                ; Fetch DOES> code address from CFA+2 and set as new IP
                LDY      #2
                LDA      (W),Y          ; IP = DOES> code
                TAY                     ; IP = DOES> code

                ; Push body address (CFA+4) onto parameter stack
                LDA     W
                CLC
                ADC     #4
                DEX
                DEX
                STA     0,X             ; push body address
                NEXT
        ENDPUBLIC

;------------------------------------------------------------------------------
; RTS_CFA_LIST trampoline used to handle the NEXT at the end of code that
; is entered via a JSR. This allows assembly primitives to call each other.
;------------------------------------------------------------------------------
RTS_CFA_LIST:
	.word RTS_CFA
        HEADER "RTS", RTS_ENTRY, RTS_CFA, 0, 0
        CODEPTR RTS_CODE
        PUBLIC  RTS_CODE
                ldy     #RTS_CFA_LIST
                rts
        ENDPUBLIC

;==============================================================================
; SYSTEM INITIALIZATION
;==============================================================================
        PUBLIC MAIN
                ; --- Set Data Bank to $00 ---
                ; PEA pushes $0000 as a 16-bit value (2 bytes on stack).
                ; First PLB discards the high byte, second PLB loads
                ; the low byte ($00) into the Data Bank Register.
                ; No need to switch accumulator width.
                PEA     $0000
                PLB                     ; Discard high byte
                PLB                     ; DB = $00

                ; --- Initialize stacks ---
                LDX     #PSP_INIT       ; Parameter stack pointer
                TSC                     ; S initialized by HAL ROM Vector.
                STA     RSP_INIT        ; Save S to reinitialize stack pointer

.ifdef DEBUG
                STZ     TRACE_EN        ; Tracing off at startup
.endif

                ; --- Initialize User Pointer ---
                LDA     #UP_BASE
                STA     UP

                ; --- User area: BASE = 10 ---
                LDY     #U_BASE
                LDA     #10
                STA     (UP),Y

                ; --- User area: STATE = 0 (interpret) ---
                ; STZ (indirect) not supported - use STA (UP),Y
                LDY     #U_STATE
                LDA     #FORTH_FALSE
                STA     (UP),Y          ; STATE = 0

                ; --- User area: DP = DICT_BASE ---
                LDY     #U_DP
                LDA     #DICT_BASE
                STA     (UP),Y

                ; --- User area: LATEST = last ROM word ---
                LDY     #U_LATEST
                LDA     #LAST_WORD      ; Defined at end of dictionary.s
                STA     (UP),Y

                ; --- User area: TIB = TIB_BASE ---
                LDY     #U_TIB
                LDA     #TIB_BASE
                STA     (UP),Y

                ; --- User area: >IN = 0 and SOURCE-LEN = 0 ---
                LDY     #U_TOIN
                LDA     #0
                STA     (UP),Y          ; >IN = 0

                LDY     #U_SOURCELEN
                STA     (UP),Y          ; SOURCE-LEN = 0

                ; --- User area: PAD and HLD = PAD_BASE ---
                LDA     #PAD_BASE
                LDY     #U_PAD
                STA     (UP),Y

                LDY     #U_HLD
                STA     (UP),Y

                ; --- User area: SAVEDP and SAVELATEST = 0
                LDY     #U_SAVEDP
                STZ     (UP),Y

                LDY     #U_SAVELATEST
                STZ     (UP),Y

		; --- Jump to ABORT to reset stacks and start interpreter ---
                ; ABORT_CODE is a machine code primitive that resets both
                ; stacks and jumps directly into QUIT_BODY via NEXT.
                ; We must NOT call QUIT_CFA here because that is a colon
                ; definition — DOCOL would try to push the current IP onto
                ; the return stack, but there is no valid IP at startup.
                JMP     ABORT_CODE
        ENDPUBLIC
