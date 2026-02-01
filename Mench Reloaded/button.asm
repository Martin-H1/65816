; -----------------------------------------------------------------------------
; Button sample for the Mench Reloaded SBC.
; Turns the LED connected to pin 0 on and off when a push button
; attached to pin 8 is pushed.
; The circuit:
; - LED attached from VIA port A pin 0 to ground through 220 ohm resistor
; - A push button is attached to VIA port B pin 0. The normally closed contact
; - is attached to a 3k-10K pullup to +5V, and the normally open contact to a
; - similar pulldown to ground.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

.include "ascii.inc"
.include "common.inc"
.include "pbasic.inc"
.include "via.inc"
.include "w65c265Monitor.inc"

LED_PIN = $0000			; Port A pin 0
BUTTON_PIN = $0008		; Port B pin 0

; Main entry point for the program.
.proc main
	ON16X
	ON16MEM
	jsr viaInit		; one time VIA initialization.
	jsr pbOutput		; Set pin 0 (port A pin 0) as output.
	jsr pbInput		; Set pin 8 (port B pin 0) as input.

@while:
	lda #BUTTON_PIN
	jsr pbINX		; read button state (also set pin 0 to input).

	beq @else
	lda #LED_PIN
	jsr pbHigh		; Turn the LED ON
	bra @endif
@else:	lda #LED_PIN
	jsr pbLow		; Turn the LED OFF
@endif:

	bra @while
.endproc
