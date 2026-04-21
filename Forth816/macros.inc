;==============================================================================
; macros.inc - ca65 Macros for 65816 Forth Kernel
;==============================================================================

.ifndef MACROS_INC
MACROS_INC = 1

;------------------------------------------------------------------------------
; NEXT - Inner interpreter dispatch
;
; Fetches the CFA at IP (Y), advances IP by 2, then jumps through
; the code pointer stored at that CFA.
;
; Register state on entry:
;   Y = IP (points to next CFA cell in current word body)
;   X = PSP
;   A = undefined (will be clobbered)
;
; Cycle cost: ~14 cycles (inlined)
;------------------------------------------------------------------------------
.macro  NEXT
.ifdef DEBUG
        JSR     TRACEOUT
.endif
        LDA     0,Y             ; A = *IP (fetch CFA of next word)
        INY                     ; IP += 1
        INY                     ; IP += 2  (advance past this cell)
        STA     W               ; W = CFA
        ; --- Stack underflow guard ---
        CPX     #PSP_EMPTY      ; PSP >= PSP_EMPTY?
        .local @underflow
        BCS     @underflow
        LDA     (W)             ; A = *W (fetch code pointer)
        STA     SCRATCH0
        JMP     (SCRATCH0)      ; Jump to code
@underflow:
        JMP     PSP_UNDERFLOW_HANDLER
.endmacro

;------------------------------------------------------------------------------
; PUSH - Push value in A onto parameter stack
;------------------------------------------------------------------------------
.macro  PUSH
        DEX
        DEX
        STA     0,X
.endmacro

;------------------------------------------------------------------------------
; POP - Pop top of parameter stack into A
;------------------------------------------------------------------------------
.macro  POP
        LDA     0,X
        INX
        INX
.endmacro

;------------------------------------------------------------------------------
; RPUSH - Push A onto return stack
;------------------------------------------------------------------------------
.macro  RPUSH
        PHA
.endmacro

;------------------------------------------------------------------------------
; RPOP - Pop return stack into A
;------------------------------------------------------------------------------
.macro  RPOP
        PLA
.endmacro

;------------------------------------------------------------------------------
; HEADER - Create a dictionary entry header in ROM
;
; Usage: HEADER "NAME", entry_label, cfa_label, flags, prev
;
;   str_name   - string literal for the name field
;   entry_lbl  - assembly label for the header (used for next word's link field)
;   cfa_lbl    - assembly label for the CFA (used as execution token)
;   flags      - F_IMMEDIATE, F_HIDDEN, or 0
;   prev       - label of previous word's header entry (for link field)
;                use 0 for the first word
;
; Layout produced:
;   .word  prev          ; Link field  (2 bytes)
;   .byte  flags|len     ; Flags+length byte
;   .byte  "NAME"        ; Name characters
;   .align 2             ; Align CFA to word boundary
;   lbl:                 ; <- CFA label (this is the execution token)
;   .word  code_ptr      ; Code field  (2 bytes, filled by CODEPTR macro)
;------------------------------------------------------------------------------
.macro  HEADER  str_name, entry_lbl, cfa_lbl, flags, prev
entry_lbl:
        .ifnblank prev
          .word prev
        .else
          .word 0
        .endif
        .byte (flags | .strlen(str_name))
        .byte str_name
        .align 2
cfa_lbl:
.endmacro

;------------------------------------------------------------------------------
; CODEPTR - Emit code pointer cell after a HEADER
;
; For primitive (CODE) words, code_label is the machine code routine.
; For colon words, code_label is DOCOL.
; For variables, code_label is DOVAR.
; For constants, code_label is DOCON.
;
; Usage: CODEPTR routine_label
;------------------------------------------------------------------------------
.macro  CODEPTR code_label
        .word code_label
.endmacro

;------------------------------------------------------------------------------
; PRIM - Full primitive word definition shorthand
;
; Creates header + code pointer, then you write the body inline.
; Ends scope with .endproc.
;
; Usage:
;   PRIM "DUP", DUP_CFA, 0, LAST_CFA
;   .proc DUP_CODE
;       ... machine code ...
;       NEXT
;   .endproc
;------------------------------------------------------------------------------

; (No combined macro for PRIM+body since ca65 can't open a .proc in a macro)
; Use HEADER + CODEPTR + .proc separately - see primitives.s for pattern.

;==============================================================================
; W65C265 ROM MONITOR CONSTANTS
; From the WDC W65C265 monitor ROM listing.
;==============================================================================

; Nibble masks (from monitor ROM listing)
LOWNIB  = $0F
HINIB   = $F0

; Control bits for REP and SEP
MEM16   = $20                   ; Accumulator width bit
IND16   = $10                   ; Index register width bit

;==============================================================================
; REGISTER WIDTH MACROS
; These match the W65C265 monitor ROM conventions exactly.
; NOTE: ON16MEM/OFF16MEM comments below describe the RESULT, not the operation:
;   ON16MEM  → REP #MEM16 → accumulator becomes 16-bit
;   OFF16MEM → SEP #MEM16 → accumulator becomes 8-bit
;==============================================================================

.macro ON16MEM
        REP     #MEM16          ; Accumulator = 16-bit
        .A16
.endmacro

.macro OFF16MEM
        SEP     #MEM16          ; Accumulator = 8-bit
        .A8
.endmacro

.macro ON16X
        REP     #IND16          ; Index registers = 16-bit
        .I16
.endmacro

.macro OFF16X
        SEP     #IND16          ; Index registers = 8-bit
        .I8
.endmacro

.macro ON16
        REP     #(MEM16 | IND16) ; All registers = 16-bit
        .A16
        .I16
.endmacro

.macro OFF16
        SEP     #(MEM16 | IND16) ; All registers = 8-bit
        .A8
        .I8
.endmacro

;------------------------------------------------------------------------------
; PUBLIC / ENDPUBLIC - Export a subroutine as a global symbol
;
; Usage:
;   PUBLIC my_function
;       ... code ...
;   ENDPUBLIC
;------------------------------------------------------------------------------
.macro  PUBLIC function_name
        .export function_name
        .proc   function_name
.endmacro

.macro  ENDPUBLIC
        .endproc
.endmacro

.endif ; MACROS_INC
