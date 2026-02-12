; -----------------------------------------------------------------------------
; Uses PWM to control the brightness of an led
; The circuit:
; - LED anode is attached to VIA port A pin 0.
; - LED cathode is attached to ground VIA header pin.
;
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

.include "ascii.inc"
.include "common.inc"
.include "pbasic.inc"
.include "print.inc"
.include "via.inc"
.include "w65c265Monitor.inc"

LED_PIN = 0			; Port B pin 0

PUBLIC main
	jsr viaInit		; one time VIA initialization.
	printcr			; start output on a newline
	ON16MEM
	ON16X

	CYCLES = 1		; stack local for cycle count
	pea $0000
@loop:
	lda #LED_PIN		; set the pin to output and low for several
	ldx #80
	ldy #500
	jsr pbPWM

	tya
	printc
	printcr

	pla
	rtl
	jmp @loop
ENDPUBLIC
