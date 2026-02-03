; -----------------------------------------------------------------------------
; Servo sample for the Mench Reloaded SBC.
; Sweeps the servo connected to pin 0 through its full range of motion.
; The circuit:
; - Servo control pin is attached to VIA port B pin 0.
; - Servo power and ground are connected to a 6 volt battery.
; - Servo ground is also connected to Vss.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

.include "ascii.inc"
.include "common.inc"
.include "pbasic.inc"
.include "via.inc"
.include "w65c265Monitor.inc"

SERVO_PIN = $0008		; Port B pin 0

SERVO_MIN = 1000 * ONE_US
SERVO_MAX = 2000 * ONE_US
SERVO_STEP = (SERVO_MAX - SERVO_MIN)/100

; Main entry point for the program.
PUBLIC main
	jsr viaInit		; one time VIA initialization.
	jsl SEND_CR		; start output on a newline
	ON16MEM
	ON16X

	PULSE_WIDTH = 1		; used to store pulse width in microseconds
	pea $0000		; reserve stack local for PULSE_WIDTH

@loop:
	lda #SERVO_MIN		; sweep 0° to 180° (1000 to 2000 µs)
@sweep_up:
	sta PULSE_WIDTH,s

	tax
	lda #SERVO_PIN
	jsr pbPulsout		; send control pulse (units µs)

	lda #20
	jsr pbPause		; Wait 20 ms between pulses

	lda #SERVO_STEP		; increment the pulse width
	clc
	adc PULSE_WIDTH,s

	cmp #SERVO_MAX		; loop until 180°
	bcc @sweep_up

@sweep_down:			; Sweep from 180° back to 0°
	sta PULSE_WIDTH,s

	tax
	lda #SERVO_PIN
	jsr pbPulsout		; send control pulse (units µs)

	lda #20
	jsr pbPause		; Wait 20 ms between pulses

	lda PULSE_WIDTH,s	; increment the pulse width
	sec
	sbc #SERVO_STEP

	cmp #SERVO_MIN		; loop until 180°
	bcs @sweep_down

	bra @loop
ENDPUBLIC
