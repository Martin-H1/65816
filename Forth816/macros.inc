;==============================================================================
; macros.inc - ca65 Macros for 65816 Forth Kernel
;==============================================================================

;
; Put assembler in 16 bit mode, as 8 bit mode is the exception
; selected at module level. Set processor, and turn off smart mode.
;
.A16
.I16
.p816				; Enable 65816 instruction set
.smart off			; Manual size tracking (safer for Forth)

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
        .a16
        LDA     0,Y             ; A = *IP (fetch CFA of next word)
        INY                     ; IP += 1
        INY                     ; IP += 2  (advance past this cell)
        STA     W               ; W = CFA
        LDA     (W)             ; A = *W (fetch code pointer)
        STA     SCRATCH0
        JMP     (SCRATCH0)      ; Jump to code
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
	lda 0,X			; load value off stack
	inx			; advance pointer, but this
	inx			; resets processor flags
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
; Usage: HEADER "NAME", name_label, flags, prev_label
;
;   str_name   - string literal for the name field
;   lbl        - assembly label for the CFA (used as execution token)
;   flags      - F_IMMEDIATE, F_HIDDEN, or 0
;   prev       - label of previous word's header (for link field)
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
.macro  HEADER  str_name, lbl, flags, prev
        .ifnblank prev
          .word prev
        .else
          .word 0
        .endif
        .byte (flags | .strlen(str_name))
        .byte str_name
        .align 2
lbl:
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

; These are from the WDC 65c265 monitor ROM listing. Reusing them allows
; using code from the monitor with minimal changes.

; masking building symbols
LOWNIB	= $0F
HINIB	= $F0

; control bits for REP and SEP
MEM16	= $20
IND16	= $10

.macro ON16MEM
       .A16		; tell the assembler about mode
       rep #MEM16	; set 8-bit accumulator mode
.endmacro

.macro OFF16MEM
       .A8
       sep #MEM16
.endmacro

.macro ON16X
       .I16
       rep #IND16
.endmacro

.macro OFF16X
       .I8
       sep #IND16
.endmacro

.macro ON16
       .A16
       .I16
       rep #(MEM16 | IND16)
.endmacro

.macro OFF16
       .A8
       .I8
       sep #(MEM16 | IND16)
.endmacro

.macro PUBLIC function_name
.export function_name
.proc function_name
.endmacro

.macro ENDPUBLIC
.endproc
.endmacro
