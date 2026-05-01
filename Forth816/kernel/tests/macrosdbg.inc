; -----------------------------------------------------------------------------
; debug definitions and macros.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

;
; Imports
;
.import CR_CODE
.import DOTHEX_CODE
.import DOTS_CODE
.import DOT_CODE
.import TYPE_CODE
.import UDOT_CODE

;
; Macros
;
.macro CALL_DOCOL cfa_addr
       lda #cfa_addr
       sta W
       jsr DOCOL
.endmacro

.macro MOVE_TIB str
.scope
	lda #@localstr
	PUSH
	lda #TIB_BASE
	PUSH
	lda #.strlen(str)
	phy
	ldy #U_SOURCELEN
	sta (UP),Y			; SOURCE string length
	ply
	PUSH
	jsr MOVE_CODE
	phy
	ldy #U_TOIN
	lda #0
	sta (UP),Y			; >IN = 0
	ply
	bra @skip
@localstr: .asciiz str
@skip:
.endscope
.endmacro

.macro LPPUTS str
       lda #str
       jsr hal_lpputs
.endmacro

.macro TYPESTR str
.scope
	lda #@localstr
	PUSH
	lda #.strlen(str)
	PUSH
	jsr TYPE_CODE
	bra @skip
@localstr: .asciiz str
@skip:
.endscope
.endmacro

.macro TYPESTRCR str
	TYPESTR str
	jsr CR_CODE
.endmacro

.macro TYPESTR_DOT str
	TYPESTR str
	jsr DOT_CODE
	jsr CR_CODE
.endmacro

.macro TYPESTR_DOTHEX str
	TYPESTR str
	jsr DOTHEX_CODE
	jsr CR_CODE
.endmacro

.macro TYPESTR_UDOT str
	TYPESTR str
	jsr UDOT_CODE
	jsr CR_CODE
.endmacro

.macro  PString Arg
	.byte   .strlen(Arg), Arg
.endmacro
