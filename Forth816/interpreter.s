;==============================================================================
; interpreter.s - 65816 Forth Kernel Intepreter Primitives
;
; All words are in ROM. Dictionary entries are linked in order.
; The HEADER macro creates the link field, flags, and name.
; The CODEPTR macro emits the code field (ITC code pointer).
;
; Pattern for each primitive word:
;
;   HEADER  "NAME", NAME_CFA, flags, PREV_CFA
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

.include "forth.inc"
.include "macros.inc"
.include "dictionary.inc"
.include "print.inc"

.segment "CODE"

;==============================================================================
; SECTION 8: INNER INTERPRETER SUPPORT WORDS
;==============================================================================

;------------------------------------------------------------------------------
; EXIT ( -- ) return from current colon definition
;------------------------------------------------------------------------------
	HEADER "EXIT", EXIT_CFA, 0, SPACES_CFA
	CODEPTR EXIT_CODE
.proc EXIT_CODE
	pla			; Pop saved IP from return stack
	tay			; Restore IP into Y
	NEXT
.endproc

;------------------------------------------------------------------------------
; EXECUTE ( xt -- ) execute word by execution token
;------------------------------------------------------------------------------
	HEADER "EXECUTE", EXECUTE_CFA, 0, EXIT_CFA
	CODEPTR EXECUTE_CODE
.proc EXECUTE_CODE
	lda 0,X			; xt = CFA
	inx
	inx
	sta W			; W = CFA
	lda (W)			; Fetch code pointer
	sta SCRATCH0
	jmp (SCRATCH0)		; Jump (word will NEXT itself)
.endproc

;------------------------------------------------------------------------------
; LIT ( -- n ) push inline literal (compiled word, not user-callable)
;------------------------------------------------------------------------------
	HEADER "LIT", LIT_CFA, F_HIDDEN, EXECUTE_CFA
	CODEPTR LIT_CODE
.proc LIT_CODE
	lda 0,Y			; Fetch literal value at IP
	iny			; Advance IP past literal
	iny
	dex
	dex
	sta 0,X			; Push literal
	NEXT
.endproc

;------------------------------------------------------------------------------
; BRANCH ( -- ) unconditional branch (compiled word)
; The cell following BRANCH contains the branch offset (signed)
;------------------------------------------------------------------------------
	HEADER "BRANCH", BRANCH_CFA, F_HIDDEN, LIT_CFA
	CODEPTR BRANCH_CODE
.proc BRANCH_CODE
	lda 0,Y			; Fetch branch target at IP
	; Branch target is stored as absolute address for simplicity:
	tay			; IP = branch target (absolute)
	NEXT
.endproc

;------------------------------------------------------------------------------
; 0BRANCH ( flag -- ) branch if flag is zero (compiled word)
;------------------------------------------------------------------------------
	HEADER "0BRANCH", ZBRANCH_CFA, F_HIDDEN, BRANCH_CFA
	CODEPTR ZBRANCH_CODE
.proc ZBRANCH_CODE
	lda 0,X
	inx			; pop and evaluate flag
	inx
	cmp #0000
	bne @no_branch		; Non-zero = no branch
	lda 0,Y			; Fetch branch target
	tay			; IP = target
	NEXT
@no_branch:
	iny			; Skip branch target cell
	iny
	NEXT
.endproc

;------------------------------------------------------------------------------
; (DO) ( limit index -- ) (R: -- limit index) runtime for DO
;------------------------------------------------------------------------------
	HEADER "(DO)", DODO_CFA, F_HIDDEN, ZBRANCH_CFA
	CODEPTR DODO_CODE
.proc DODO_CODE
	lda 2,X			; limit
	pha			; Push limit onto return stack
	lda 0,X			; index
	pha			; Push index onto return stack
	inx
	inx
	inx
	inx
	NEXT
.endproc

;------------------------------------------------------------------------------
; (LOOP) ( -- ) (R: limit index -- | limit index+1)
; runtime for LOOP - increments index, branches back if not done
;------------------------------------------------------------------------------
	HEADER "(LOOP)", DOLOOP_CFA, F_HIDDEN, DODO_CFA
	CODEPTR DOLOOP_CODE
.proc DOLOOP_CODE
	pla			; index
	inc			; index+1
	sta SCRATCH0
	pla			; limit
	cmp SCRATCH0		; limit == index+1?
	beq @done		; Loop finished
	pha			; Push limit back
	lda SCRATCH0
	pha			; Push index+1 back
	lda 0,Y			; Branch target
	tay			; IP = loop top
	NEXT
@done:	iny			; Drop limit, don't push index back
	iny			; Skip branch target
	NEXT
.endproc

;------------------------------------------------------------------------------
; (+LOOP) ( n -- ) (R: limit index -- | limit index+n)
; runtime for +LOOP
;------------------------------------------------------------------------------
	HEADER "(+LOOP)", DOPLUSLOOP_CFA, F_HIDDEN, DOLOOP_CFA
	CODEPTR DOPLUSLOOP_CODE
.proc DOPLUSLOOP_CODE
	lda 0,X			; step
	inx
	inx
	sta SCRATCH1
	pla			; index
	clc
	adc SCRATCH1		; index + step
	sta SCRATCH0
	pla			; limit
	cmp SCRATCH0		; Check if we crossed limit
	beq @done		; index == limit → done
	sta TMPA		; Save limit TODO - is this needed?
	pha			; Push limit back
	lda SCRATCH0
	pha			; Push new index back
	lda 0,Y			; Branch back
	tay
	NEXT
@done:	iny
	iny
	NEXT
.endproc

;------------------------------------------------------------------------------
; UNLOOP ( -- ) (R: limit index -- ) discard DO loop parameters
;------------------------------------------------------------------------------
	HEADER "UNLOOP", UNLOOP_CFA, 0, DOPLUSLOOP_CFA
	CODEPTR UNLOOP_CODE
.proc UNLOOP_CODE
	pla			; Discard index
	pla			; Discard limit
	NEXT
.endproc

;------------------------------------------------------------------------------
; I ( -- n ) (R: limit index -- limit index) copy loop index
;------------------------------------------------------------------------------
	HEADER "I", I_CFA, 0, UNLOOP_CFA
	CODEPTR I_CODE
.proc I_CODE
	; Return stack: TOS=index NOS=limit NOS2=saved_IP
	pla			; Pop index
	pha			; Push back
	dex			; Push to parameter sstack
	dex
	sta 0,X			; Loop index is now on parameter stack
	NEXT
.endproc

;------------------------------------------------------------------------------
; J ( -- n ) copy outer loop index
;------------------------------------------------------------------------------
	HEADER "J", J_CFA, 0, I_CFA
	CODEPTR J_CODE
.proc J_CODE
	; Return stack (top to bottom):
	;   inner_index, inner_limit, saved_IP, outer_index, outer_limit
	; Pop 4 cells to get to outer index
	pla			; inner index
	sta SCRATCH0
	pla			; inner limit
	sta SCRATCH1
	pla			; saved IP
	sta TMPA
	pla			; outer index
	sta TMPB
	; Push them all back
	pha			; outer index back
	lda TMPA
	pha			; saved IP
	lda SCRATCH1
	pha
	lda SCRATCH0
	pha			; inner limit
	lda TMPB		; Push outer index to param stack
	dex
	dex
	sta 0,X
	NEXT
.endproc

;==============================================================================
; SECTION 9: DICTIONARY PRIMITIVES
;==============================================================================

;------------------------------------------------------------------------------
; HERE ( -- addr ) current dictionary pointer
;------------------------------------------------------------------------------
	HEADER "HERE", HERE_CFA, 0, J_CFA
	CODEPTR HERE_CODE
.proc HERE_CODE
	lda UP			; UP in page zero
	clc
	adc #U_DP		; Add the dictionary pointer offset
	sta SCRATCH0
	lda (SCRATCH0)		; Fetch DP indirect.
	dex
	dex
	sta 0,X			; Push to parameter stack.
	NEXT
.endproc

;------------------------------------------------------------------------------
; ALLOT ( n -- ) advance dictionary pointer by n bytes
;------------------------------------------------------------------------------
	HEADER "ALLOT", ALLOT_CFA, 0, HERE_CFA
	CODEPTR ALLOT_CODE
.proc ALLOT_CODE
	lda UP			; Get UP and add DP offset
	clc
	adc #U_DP
	sta SCRATCH0
	lda (SCRATCH0)		; Fetch DP indirect
	clc
	adc 0,X			; Advance to DP + n
	sta (SCRATCH0)		; Store new DP
	inx			; drop n
	inx
	NEXT
.endproc

;------------------------------------------------------------------------------
; , ( val -- ) compile cell into dictionary
;------------------------------------------------------------------------------
	HEADER ",", COMMA_CFA, 0, ALLOT_CFA
	CODEPTR COMMA_CODE
.proc COMMA_CODE
	lda UP			; Get UP, add DP offset, and load DP
	clc
	adc #U_DP
	sta SCRATCH0
	lda (SCRATCH0)		; Save DP → SCRATCH1
	sta SCRATCH1
	lda 0,X			; Pop val off parameter stack
	inx
	inx
	sta (SCRATCH1)		; Store indirect through DP
	lda SCRATCH1		; DP += 2
	clc
	adc #2
	sta (SCRATCH0)		; Update pointer for next time.
	NEXT
.endproc

;------------------------------------------------------------------------------
; C, ( byte -- ) compile byte into dictionary
;------------------------------------------------------------------------------
	HEADER "C,", CCOMMA_CFA, 0, COMMA_CFA
	CODEPTR CCOMMA_CODE
.proc CCOMMA_CODE
	lda UP			; Get UP, add DP offset, and load DP
	clc
	adc #U_DP
	sta SCRATCH0
	lda (SCRATCH0)
	sta SCRATCH1		; Store DP to allow indirect store.
	lda 0,X			; Pop data
	inx
	inx
	sep #$20		; Enter byte transfer mode
        .a8
	sta (SCRATCH1)		; store A indirect.
	rep #$20
        .a16
	lda SCRATCH1
	inc
	lda SCRATCH1		; Update the pointer by a byte.
	inc
	sta (SCRATCH0)
	NEXT
.endproc

;------------------------------------------------------------------------------
; LATEST ( -- addr ) address of LATEST variable in user area
;------------------------------------------------------------------------------
	HEADER "LATEST", LATEST_CFA, 0, CCOMMA_CFA
	CODEPTR LATEST_CODE
.proc LATEST_CODE
	lda UP			; Get UP and add offset to LATEST
	clc
	adc #U_LATEST
	dex
	dex
	sta 0,X			; Push onto parameter stack
	NEXT
.endproc

;==============================================================================
; SECTION 10: USER AREA ACCESSORS
;==============================================================================

;------------------------------------------------------------------------------
; BASE ( -- addr ) address of BASE variable
;------------------------------------------------------------------------------
	HEADER "BASE", BASE_CFA, 0, LATEST_CFA
	CODEPTR BASE_CODE
.proc BASE_CODE
	lda UP			; Get UP and add BASE offset and push
	clc
	adc #U_BASE
	dex
	dex
	sta 0,X
	NEXT
.endproc

;------------------------------------------------------------------------------
; STATE ( -- addr ) address of STATE variable
;------------------------------------------------------------------------------
	HEADER "STATE", STATE_CFA, 0, BASE_CFA
	CODEPTR STATE_CODE
.proc STATE_CODE
	lda UP			; Get UP and add STATE offset and push
	clc
	adc #U_STATE
	dex
	dex
	sta 0,X
	NEXT
.endproc

;------------------------------------------------------------------------------
; >IN ( -- addr ) address of >IN variable
;------------------------------------------------------------------------------
	HEADER ">IN", TOIN_CFA, 0, STATE_CFA
	CODEPTR TOIN_CODE
.proc TOIN_CODE
	lda UP			; Get UP and add TOIN offset and push
	clc
	adc #U_TOIN
	dex
	dex
	sta 0,X
	NEXT
.endproc

;------------------------------------------------------------------------------
; SOURCE ( -- addr len ) current input source
;------------------------------------------------------------------------------
	HEADER "SOURCE", SOURCE_CFA, 0, TOIN_CFA
	CODEPTR SOURCE_CODE
.proc SOURCE_CODE
	lda UP			; Push TIB address
	clc
	adc #U_TIB
	sta SCRATCH0
	lda (SCRATCH0)
	dex
	dex
	sta 0,X
	lda UP			; Push source length
	clc
	adc #U_SOURCELEN
	sta SCRATCH0
	lda (SCRATCH0)
	dex
	dex
	sta 0,X
	NEXT
.endproc
