; -----------------------------------------------------------------------------
; Blink sample for the Mench Reloaded SBC.
; Toggles a 65c22 pin which can blink and LED.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

.include "ascii.inc"
.include "common.inc"
.include "pbasic.inc"
.include "via.inc"

LED_PIN = $0000			; Port A pin 0

; Main entry point for the program.
.proc main
	jsr viaInit		; one time VIA initialization.
	ON16MEM
	lda #LED_PIN
	jsr pbOutput		; Set pin 0 (port A pin 0) as output.

@while:
	lda #LED_PIN
	jsr pbHigh		; Turn the LED ON

	lda #1000
	jsr pbPause		; Wait for 1 second

	lda #LED_PIN
	jsr pbLow		; Turn the LED OFF

	lda #1000
	jsr pbPause		; Wait for 1 second

	bra @while
.endproc
