; -----------------------------------------------------------------------------
; Hello World sample for the Mench Reloaded SBC.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

.include "ascii.inc"
.include "common.inc"
.include "print.inc"

; Main entry point for the interpreter test
.proc main
	ON16MEM
	ON16X
	printcr
	println hello
	rtl
.endproc

hello:	.asciiz "Hello World!"
