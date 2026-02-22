; -----------------------------------------------------------------------------
; Echo sample for the Mench Reloaded SBC. Echos until control-C is entered.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

.include "ascii.inc"
.include "common.inc"
.include "print.inc"

; Main entry point for the interpreter test
.proc main
	OFF16MEM		; ensure accumulator is in 8 bit mode.
@while:
	getputch		; call get char with echo.
	cmp #ETX
	bne @while		; iterate while not end of transmission.
	rtl			; return to monitor.
.endproc
