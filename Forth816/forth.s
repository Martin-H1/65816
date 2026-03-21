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
SCRATCH0:       .res 2          ; General purpose scratch
SCRATCH1:       .res 2          ; General purpose scratch
TMPA:           .res 2          ; Temp for multiply/divide
TMPB:           .res 2          ; Temp for multiply/divide
HAL_RXBUF:      .res 1          ; HAL receive lookahead buffer (1 byte)
HAL_RXREADY:    .res 1          ; HAL receive buffer flag (0=empty, 1=full)

; Export zero page symbols with .globalzp so other translation units
; use direct page addressing when referencing them
        .globalzp       W
        .globalzp       UP
        .globalzp       SCRATCH0
        .globalzp       SCRATCH1
        .globalzp       TMPA
        .globalzp       TMPB
        .globalzp       HAL_RXBUF
        .globalzp       HAL_RXREADY

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
                TYA                     ; Current IP → A
                PHA                     ; Push IP onto return stack
                LDA     W               ; W = CFA of this word
                CLC
                ADC     #2              ; Body starts at CFA+2
                TAY                     ; IP = body start
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
                LDA     W               ; CFA
                CLC
                ADC     #2
                STA     SCRATCH0
                LDA     (SCRATCH0)      ; Fetch constant value
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
                ; Push body address of THIS word (W+2)
                LDA     W
                CLC
                ADC     #2
                DEX
                DEX
                STA     0,X             ; Push body address

                ; W points to CFA which contains address of DODOES.
                ; The DOES> code address is stored after DOCOL saved IP.
                ; IP (Y) was set by the caller to point to DOES> code.
                NEXT
        ENDPUBLIC

;==============================================================================
; SYSTEM INITIALIZATION
;==============================================================================
        .proc   FORTH_INIT
                ; --- Switch to 65816 native mode ---
                CLC
                XCE                     ; Clear emulation bit → native mode

                ; --- 16-bit registers ---
                REP     #$30
                .a16
                .i16

                ; --- Set Direct Page to $0000 ---
                LDA     #$0000
                TCD

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
                LDA     #RSP_INIT
                TAS                     ; Hardware (return) stack pointer

                ; --- Initialize User Pointer ---
                LDA     #UP_BASE
                STA     UP

                ; --- User area: BASE = 10 ---
                LDA     #UP_BASE + U_BASE
                STA     SCRATCH0
                LDA     #10
                STA     (SCRATCH0)

                ; --- User area: STATE = 0 (interpret) ---
                ; STZ (indirect) not supported - use STA (UP),Y
                LDA     #UP_BASE
                STA     SCRATCH0
                LDA     #0
                LDY     #U_STATE
                STA     (SCRATCH0),Y    ; STATE = 0

                ; --- User area: DP = DICT_BASE ---
                LDA     #UP_BASE + U_DP
                STA     SCRATCH0
                LDA     #DICT_BASE
                STA     (SCRATCH0)

                ; --- User area: LATEST = last ROM word ---
                LDA     #UP_BASE + U_LATEST
                STA     SCRATCH0
                LDA     #LAST_WORD      ; Defined at end of dictionary.s
                STA     (SCRATCH0)

                ; --- User area: TIB = TIB_BASE ---
                LDA     #UP_BASE + U_TIB
                STA     SCRATCH0
                LDA     #TIB_BASE
                STA     (SCRATCH0)

                ; --- User area: >IN = 0 and SOURCE-LEN = 0 ---
                LDA     #UP_BASE
                STA     SCRATCH0
                LDA     #0
                LDY     #U_TOIN
                STA     (SCRATCH0),Y    ; >IN = 0
                LDY     #U_SOURCELEN
                STA     (SCRATCH0),Y    ; SOURCE-LEN = 0

                ; --- Jump to ABORT to reset stacks and start interpreter ---
                ; ABORT_CODE is a machine code primitive that resets both
                ; stacks and jumps directly into QUIT_BODY via NEXT.
                ; We must NOT call QUIT_CFA here because that is a colon
                ; definition — DOCOL would try to push the current IP onto
                ; the return stack, but there is no valid IP at startup.
                JMP     ABORT_CODE
        .endproc

;==============================================================================
; HARDWARE VECTORS
;==============================================================================
        .segment "VECTORS"

        ; Emulation mode vectors ($FFE0-$FFEF are unused/reserved)
        .word   $0000                   ; $FFE0 - unused
        .word   $0000                   ; $FFE2 - unused
        .word   $0000                   ; $FFE4 - COP (emulation)
        .word   $0000                   ; $FFE6 - unused
        .word   $0000                   ; $FFE8 - ABORT (emulation)
        .word   $0000                   ; $FFEA - unused
        .word   $0000                   ; $FFEC - NMI (emulation)
        .word   FORTH_INIT              ; $FFEE - RESET (emulation) → init

        ; Native mode vectors ($FFF0-$FFFF)
        .word   $0000                   ; $FFF0 - COP (native)
        .word   $0000                   ; $FFF2 - BRK (native)
        .word   $0000                   ; $FFF4 - ABORT (native)
        .word   $0000                   ; $FFF6 - unused
        .word   $0000                   ; $FFF8 - NMI (native)
        .word   FORTH_INIT              ; $FFFA - unused
        .word   FORTH_INIT              ; $FFFC - RESET (native)
        .word   $0000                   ; $FFFE - IRQ/BRK (native)
