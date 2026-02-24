; -----------------------------------------------------------------------------
; Uses PWM and a 754410 to control the speed and direction of two DC motors.
; The circuit:
; - 754410 1,2 EN is attached to VIA port A pin 2.
; - 754410 3,4 EN is attached to VIA port A pin 3.
; - 754410 1A is attached to VIA port A pin 4.
; - 754410 2A is attached to VIA port A pin 5.
; - 754410 3A is attached to VIA port A pin 6.
; - 754410 4A is attached to VIA port A pin 7.
; - 754410 1Y is connected to Motor 1
; - 754410 2Y is connected to Motor 1
; - 754410 3Y is connected to Motor 2
; - 754410 4Y is connected to Motor 2
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

.include "ascii.inc"
.include "common.inc"
.include "pbasic.inc"
.include "print.inc"
.include "via.inc"

M1_PWM = 2			; Motor 1 pwm channel
M2_PWM = 3			; Motor 2 pwm channel
M1_1A = 4			; Motor 1 direction pins
M1_2A = 5
M2_3A = 6			; Motor 2 direction pins
M2_4A = 7

PUBLIC main
	ON16MEM
	ON16X
	phd
	printcr			; start output on a newline
	jsr viaInit		; one time VIA initialization.

	DUTY_CYCLE = 1		; stack local for cycle count
	pea $0001		; start with a valid value.
	tsc			; point direct page to stack frame
	tcd

	lda #M1_PWM
	jsr pbLow		; Turn motor 1 off
	lda #M2_PWM
	jsr pbLow		; Turn motor 2 off

	lda #M1_1A		; Set motor 1 to forward
	jsr pbHigh
	lda #M1_2A
	jsr pbLow

	lda #M2_3A		; Set motor 2 to forward
	jsr pbHigh
	lda #M2_4A
	jsr pbLow

@loop1:
	lda #M1_PWM		; Ramp motor 1 with increasing PWM duty cycles.
	ldx DUTY_CYCLE		; load the duty cycle
	ldy #15			; set the duration in ms
	jsr pbPWM

	lda #M2_PWM		; Ramp motor 2 with increasing PWM duty cycles.
	ldx DUTY_CYCLE		; load the duty cycle
	ldy #15			; set the duration in ms
	jsr pbPWM

	inc DUTY_CYCLE		; ramp duty cycle
	lda DUTY_CYCLE
	cmp #$00ff
	bcc @loop1

	dec DUTY_CYCLE		; get duty cycle duration within limits.
@loop2:
	lda #M1_PWM		; Ramp motor 1 with increasing PWM duty cycles.
	ldx DUTY_CYCLE		; load the duty cycle
	ldy #15			; set the duration in ms
	jsr pbPWM

	lda #M2_PWM		; Ramp motor 2 with increasing PWM duty cycles.
	ldx DUTY_CYCLE		; load the duty cycle
	ldy #15			; set the duration in ms
	jsr pbPWM

	dec DUTY_CYCLE
	bne @loop2		; exit when zero

@return:
	pla
	pld
	rtl
ENDPUBLIC
