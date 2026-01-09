; -----------------------------------------------------------------------------
; Hello World sample for the Mench Reloaded SBC.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

.include "ascii.inc"
.include "common.inc"
.include "w65c265Monitor.inc"

; Main entry point for the interpreter test
.proc main
	OFF16MEM		; ensure accumulator is in 8 bit mode.
@while:
	jsl GET_PUT_CHR		; call monitor get char with echo.
	cmp #ETX
	bne @while		; iterate while not end of transmission.
	rtl			; return to monitor.
.endproc
