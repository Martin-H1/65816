; -----------------------------------------------------------------------------
; Test of recursive macros and other odd ball ideas.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

.include "vmachine.inc"

; Main entry point for the test
PUBLIC MAIN
	CALL	LOOP_EXAMPLE
	HALT			; return to monitor.
ENDPUBLIC

PUBLIC LOOP_EXAMPLE
	PUSHI 10
@loop:	CPUTS	"Count = "
	DUP
	DOT
	PRINTCR
	PUSHI 1
	SUB
	BRANCHZ @loop
	RETURN
ENDPUBLIC

