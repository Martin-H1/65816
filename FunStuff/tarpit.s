; -----------------------------------------------------------------------------
; Test of recursive macros and other odd ball ideas.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

.include "macros.inc"

; Main entry point for the test
.proc main
	INIT
	PUSHI 10
@loop:	DUP
	DOT
	PUSHI 1
	SUB
	ZBRANCH @loop
	HALT		; return to monitor.
.endproc
