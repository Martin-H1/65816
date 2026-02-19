; -----------------------------------------------------------------------------
; Hello World sample for the Mench Reloaded SBC.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

.include "print.inc"

.A8
.I16

; Main entry point for the interpreter test
.proc main
	jsl SEND_CR
	lda #$00
	ldx #hello
	jsl PUT_STR
	jsl SEND_CR
	rtl
.endproc

hello:	.asciiz "Hello World!"
