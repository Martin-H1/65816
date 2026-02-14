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

BUZZER_PIN = 0			; Port B pin 0

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

@while:
	dec DUTY_CYCLE
	bne @while		; exit when zero

@return:
	pla
	pld
	rtl

notes:	.word 1
duration:
	.word 1
	
ENDPUBLIC
