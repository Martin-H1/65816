; -----------------------------------------------------------------------------
; Blink sample for the Mench Reloaded SBC.
; Toggles a 65c22 pin which can blink and LED.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

.include "ascii.inc"
.include "common.inc"
.include "via.inc"
.include "w65c265Monitor.inc"

; Main entry point for the program.
.proc main
@setup:
	OFF16MEM		; ensure accumulator is in 8 bit mode.

	jsr viaInit
	lda #$ff
	sta VIA_BASE+VIA_DDRA	; Set port A as output.

@while:
	lda #HIGH		; Turn the LED ON
	sta VIA_BASE+VIA_PRA
	jsr viaTimer2Delay	; Wait for 1 second

	lda #LOW
	sta VIA_BASE+VIA_PRA	; Turn the LED OFF
	jsr viaTimer2Delay	; Wait for 1 second

	bra @while
.endproc
