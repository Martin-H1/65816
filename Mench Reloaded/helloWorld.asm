; -----------------------------------------------------------------------------
; Hello World sample for the Mench Reloaded SBC.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

.include "w65c265Monitor.inc"

.A8
.I16

; Main entry point for the interpreter test
.proc main
	lda #$00
	ldx #hello
	jsl PUT_STR
	rtl
.endproc

hello:	.asciiz "Hello World!\n"
