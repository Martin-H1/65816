; -----------------------------------------------------------------------------
; Hello World sample for the Mench Reloaded SBC.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

.include "ascii.inc"
.include "common.inc"
.include "print.inc"

.A8
.I16

; Main entry point for the interpreter test
.proc main
	printcr
	println hello
	rtl
.endproc

hello:	.asciiz "Hello World!"
