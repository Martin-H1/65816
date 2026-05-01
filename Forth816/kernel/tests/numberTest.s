; -----------------------------------------------------------------------------
; numberTest - unit test for number words (e.g. >NUMBER and NUMBER?
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

.p816                   ; Enable 65816 instruction set
.smart off              ; Manual size tracking (safer for Forth)
.A16
.I16

.include "constants.inc"
.include "dictionary.inc"
.include "hal.inc"
.include "macros.inc"
.include "macrosdbg.inc"

.import COMPARE_CODE
.import DROP_CODE
.import MOVE_CODE
.import SKIPCHAR_CODE
.import PLACE_CODE
.import PARSE_CODE
.import WORD_CODE
.import FIND_CODE
.import TONUMBER_CODE
.import NUMBERQ_CODE
.import INTERPRET_CODE
.import SPACE_CODE
.import TRACEOFF_CODE
.import TRACEON_CODE

.importzp SCRATCH0
.importzp UP
.importzp W

; Main entry point for the test
PUBLIC MAIN
	TYPESTRCR "number test - enter!"
	jsr TRACEOFF_CODE	; tracing initialization.

	jsr tonumberTest
	jsr numberTest
	jsr doubleNumberTest

	TYPESTRCR "number test - exit!"
	rts
ENDPUBLIC

.macro TONUMARGS str
.scope
	lda #0000
	PUSH
	PUSH
	lda #@addr
	PUSH
	lda #.strlen(str)
	PUSH
	BRA @over
@addr:	.asciiz str
@over:
.endscope
.endmacro

.proc tonumberTest
	TYPESTR ">NUMBER test input=''"
	TONUMARGS ""
	jsr TONUMBER_CODE
	TYPESTR ", Status="
	JSR DOT_CODE
	jsr DROP_CODE
	jsr DROP_CODE
	TYPESTR_DOT ", Result="

	TYPESTR ">NUMBER test input='--'"
	TONUMARGS "--"
	jsr TONUMBER_CODE
	TYPESTR ", Status="
	JSR DOT_CODE
	jsr DROP_CODE
	jsr DROP_CODE
	TYPESTR_DOT ", Result="

	TYPESTR ">NUMBER test input='12G'"
	TONUMARGS "12G"
	jsr TONUMBER_CODE
	TYPESTR ", Status="
	JSR DOT_CODE
	jsr DROP_CODE
	jsr DROP_CODE
	TYPESTR_DOT ", Result="

	TYPESTR ">NUMBER test input='0'"
	TONUMARGS "0"
	jsr TONUMBER_CODE
	TYPESTR ", Status="
	JSR DOT_CODE
	jsr DROP_CODE
	jsr DROP_CODE
	TYPESTR_DOT ", Result="

	TYPESTR ">NUMBER test input='-10'"
	TONUMARGS "-10"
	jsr TONUMBER_CODE
	TYPESTR ", Status="
	JSR DOT_CODE
	jsr DROP_CODE
	jsr DROP_CODE
	TYPESTR_DOT ", Result="

	TYPESTR ">NUMBER test input='500'"
	TONUMARGS "500"
	jsr TONUMBER_CODE
	TYPESTR ", Status="
	JSR DOT_CODE
	jsr DROP_CODE
	jsr DROP_CODE
	TYPESTR_DOT ", Result="

	phy
	ldy #U_BASE
	lda #16
	sta (UP),y
	ply

	TYPESTR ">NUMBER test input='7FF'"
	TONUMARGS "7FF"
	jsr TONUMBER_CODE
	TYPESTR ", Status="
	JSR DOT_CODE
	jsr DROP_CODE
	jsr DROP_CODE
	TYPESTR_DOT ", Result="

	TYPESTR ">NUMBER test input='DEAD'"
	TONUMARGS "DEAD"
	jsr TONUMBER_CODE
	TYPESTR ", Status="
	JSR DOT_CODE
	jsr DROP_CODE
	jsr DROP_CODE
	TYPESTR_DOTHEX ", Result="

	phy
	ldy #U_BASE
	lda #10
	sta (UP),y
	ply

	rts
.endproc

.proc numberTest
	; Invalid input returning error flag
	LPPUTS numsg1		; empty string test
	lda #error1
	PUSH
	jsr hal_lpputs
	LPPUTS numsg2
	jsr NUMBERQ_CODE
	jsr DOTHEX_CODE
	LPPUTS numsg3
	jsr DOT_CODE
	jsr CR_CODE

	LPPUTS numsg1		; two minus signs
	lda #error2
	PUSH
	jsr hal_lpputs
	jsr NUMBERQ_CODE
	LPPUTS numsg2
	jsr DOTHEX_CODE
	LPPUTS numsg3
	jsr DOT_CODE
	jsr CR_CODE

	LPPUTS numsg1		; not a number
	lda #error3
	PUSH
	jsr hal_lpputs
	jsr NUMBERQ_CODE
	LPPUTS numsg2
	jsr DOTHEX_CODE
	LPPUTS numsg3
	jsr DOT_CODE
	jsr CR_CODE

	LPPUTS numsg1		; a number with trailing junk
	lda #error4
	PUSH
	jsr hal_lpputs
	jsr NUMBERQ_CODE
	LPPUTS numsg2
	jsr DOTHEX_CODE
	LPPUTS numsg3
	jsr DOT_CODE
	jsr CR_CODE

	LPPUTS numsg1		; a word instead of a number
	lda #error5
	PUSH
	jsr hal_lpputs
	jsr NUMBERQ_CODE
	LPPUTS numsg2
	jsr DOTHEX_CODE
	LPPUTS numsg3
	jsr DOT_CODE
	jsr CR_CODE

	; Decimal and hex conversion
	; Zero first
	LPPUTS numsg1
	lda #num1
	PUSH
	jsr hal_lpputs
	jsr NUMBERQ_CODE
	LPPUTS numsg2
	jsr DOTHEX_CODE
	LPPUTS numsg3
	jsr DOT_CODE
	jsr CR_CODE

	; Negative numbers
	LPPUTS numsg1
	lda #num2
	PUSH
	jsr hal_lpputs
	jsr NUMBERQ_CODE
	LPPUTS numsg2
	jsr DOTHEX_CODE
	LPPUTS numsg3
	jsr DOT_CODE
	jsr CR_CODE

	LPPUTS numsg1
	lda #num3
	PUSH
	jsr hal_lpputs
	jsr NUMBERQ_CODE
	LPPUTS numsg2
	jsr DOTHEX_CODE
	LPPUTS numsg3
	jsr DOT_CODE
	jsr CR_CODE

	LPPUTS numsg1
	lda #hex1
	PUSH
	jsr hal_lpputs
	jsr NUMBERQ_CODE
	LPPUTS numsg2
	jsr DOTHEX_CODE
	LPPUTS numsg3
	jsr DOT_CODE
	jsr CR_CODE

	LPPUTS numsg1
	lda #hex2
	PUSH
	jsr hal_lpputs
	jsr NUMBERQ_CODE
	LPPUTS numsg2
	jsr DOTHEX_CODE
	LPPUTS numsg3
	jsr DOT_CODE
	jsr CR_CODE

	LPPUTS numsg1
	lda #hex3
	PUSH
	jsr hal_lpputs
	jsr NUMBERQ_CODE
	LPPUTS numsg2
	jsr DOTHEX_CODE
	LPPUTS numsg3
	jsr DOTHEX_CODE
	jsr CR_CODE

	LPPUTS numsg1
	lda #hex4
	PUSH
	jsr hal_lpputs
	jsr NUMBERQ_CODE
	LPPUTS numsg2
	jsr DOTHEX_CODE
	LPPUTS numsg3
	jsr DOTHEX_CODE
	jsr CR_CODE

	LPPUTS numsg1
	lda #hex5
	PUSH
	jsr hal_lpputs
	jsr NUMBERQ_CODE
	LPPUTS numsg2
	jsr DOTHEX_CODE
	LPPUTS numsg3
	jsr DOTHEX_CODE
	jsr CR_CODE

	;Boundary values like $7FFF and $8000
	rts
.endproc
numsg1:	PString "Number test input='"
numsg2:	PString "', Status="
numsg3:	PString ", Result="
error1:	PString ""
error2:	PString "--"
error3:	PString "fpp"
error4:	PString "12G"
error5:	PString "CELL"
num1:	PString "0"
num2:	PString "-10"
num3:	PString "500"
hex1:	PString "7FF"
hex2:	PString "-$7FF"
hex3:	PString "$DEAD"
hex4:	PString "$7FFF"
hex5:	PString "$8000"

.proc doubleNumberTest
	LPPUTS dmsg1
	lda #dnum1
	PUSH
	jsr hal_lpputs
	jsr NUMBERQ_CODE
	LPPUTS dmsg2
	jsr DOTHEX_CODE
	LPPUTS dmsg3
	jsr DOTHEX_CODE
	jsr SPACE_CODE
	jsr DOTHEX_CODE
	jsr CR_CODE

	LPPUTS dmsg1
	lda #dnum2
	PUSH
	jsr hal_lpputs
	jsr NUMBERQ_CODE
	LPPUTS dmsg2
	jsr DOTHEX_CODE
	LPPUTS dmsg3
	jsr DOTHEX_CODE
	jsr SPACE_CODE
	jsr DOTHEX_CODE
	jsr CR_CODE

	LPPUTS dmsg1
	lda #dnum3
	PUSH
	jsr hal_lpputs
	jsr NUMBERQ_CODE
	LPPUTS dmsg2
	jsr DOTHEX_CODE
	LPPUTS dmsg3
	jsr DOTHEX_CODE
	jsr SPACE_CODE
	jsr DOTHEX_CODE
	jsr CR_CODE

	LPPUTS dmsg1
	lda #dnum4
	PUSH
	jsr hal_lpputs
	jsr NUMBERQ_CODE
	LPPUTS dmsg2
	jsr DOTHEX_CODE
	LPPUTS dmsg3
	jsr DOTHEX_CODE
	jsr SPACE_CODE
	jsr DOTHEX_CODE
	jsr CR_CODE

	LPPUTS dmsg1
	lda #dnum5
	PUSH
	jsr hal_lpputs
	jsr NUMBERQ_CODE
	LPPUTS dmsg2
	jsr DOTHEX_CODE
	LPPUTS dmsg3
	jsr DOTHEX_CODE
	jsr SPACE_CODE
	jsr DOTHEX_CODE
	jsr CR_CODE

	LPPUTS dmsg1
	lda #dnum6
	PUSH
	jsr hal_lpputs
	jsr NUMBERQ_CODE
	LPPUTS dmsg2
	jsr DOTHEX_CODE
	LPPUTS dmsg3
	jsr DOTHEX_CODE
	jsr CR_CODE

	LPPUTS dmsg1
	lda #dnum7
	PUSH
	jsr hal_lpputs
	jsr NUMBERQ_CODE
	LPPUTS dmsg2
	jsr DOTHEX_CODE
	LPPUTS dmsg3
	jsr DOTHEX_CODE
	jsr CR_CODE

	LPPUTS dmsg1
	lda #dnum8
	PUSH
	jsr hal_lpputs
	jsr NUMBERQ_CODE
	LPPUTS dmsg2
	jsr DOTHEX_CODE
	LPPUTS dmsg3
	jsr DOTHEX_CODE
	jsr SPACE_CODE
	jsr DOTHEX_CODE
	jsr CR_CODE

	LPPUTS dmsg1
	lda #dnum9
	PUSH
	jsr hal_lpputs
	jsr NUMBERQ_CODE
	LPPUTS dmsg2
	jsr DOTHEX_CODE
	LPPUTS dmsg3
	jsr DOTHEX_CODE
	jsr SPACE_CODE
	jsr DOTHEX_CODE
	jsr CR_CODE

	rts
.endproc
dmsg1:	PString "Double number test input='"
dmsg2:	PString "', Status="
dmsg3:	PString ", Result="
dnum1:	PString "1234."    ; should show 1234 0 (d_lo=1234, d_hi=0)
dnum2:	PString "0."       ; should show 0 0
dnum3:	PString "100000."  ; d_lo=$86A0, d_hi=$0001  (100000 = $000186A0)
dnum4:	PString "-1."      ; d_lo=$FFFF, d_hi=$FFFF
dnum5:	PString "-100000." ; d_lo=$7960, d_hi=$FFFE
dnum6:	PString "65535"    ; single cell, should show $FFFF
dnum7:	PString "65536"    ; should fail (overflow, no trailing dot)
dnum8:	PString "65536."   ; should show 0 1 (d_lo=0, d_hi=1)
dnum9:	PString "$10000."  ; d_lo=0, d_hi=1
