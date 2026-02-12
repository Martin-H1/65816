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
	phd
	ON16MEM
	ON16X
	printcr			; start output on a newline
	jsr viaInit		; one time VIA initialization.

	DUTY_CYCLE = 1		; stack local for cycle count
	pea $0001		; start with a valid value.
	tsc			; point direct page to stack frame
	tcd

@loop1:
	lda #LED_PIN		; set the pin to output and low for several
	ldx DUTY_CYCLE		; load the duty cycle
	ldy #50			; set the duration in ms
	jsr pbPWM

	inc DUTY_CYCLE
	lda DUTY_CYCLE
	cmp #$00ff
	bcc @loop1

	dec DUTY_CYCLE		; get duty cycle duration within limits.
@loop2:
	lda #LED_PIN		; set the pin to output and low for several
	ldx DUTY_CYCLE		; load the duty cycle
	ldy #50			; set the duration in ms
	jsr pbPWM

	dec DUTY_CYCLE
	bne @loop2		; exit when zero

@return:
	pla
	pld
	rtl
ENDPUBLIC
