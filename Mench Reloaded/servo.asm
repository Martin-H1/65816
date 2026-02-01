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

; Main entry point for the program.
.proc main
	ON16MEM
	ON16X
	PULSE_WIDTH = 0		; used to store pulse width in microseconds
	pea $0000		; reserve stack local for PULSE_WIDTH
	jsr viaInit		; one time VIA initialization.

@loop:
	lda #1000		; sweep 0° to 180° (1000 to 2000 µs)
@sweep_up:
	sta PULSE_WIDTH,s
	tax
	lda #SERVO_PIN
	jsr pbPulsout		; send control pulse (units µs)

	lda #20
	jsr pbPause		; Wait 20 ms between pulses

	lda PULSE_WIDTH,s	; increment the pulse width
	adc #10
	cmp #1000		; loop until 180°
	bne @sweep_up

@sweep_down:			; Sweep from 180° back to 0°
	sta PULSE_WIDTH,s
	tax
	lda #SERVO_PIN
	jsr pbPulsout		; send control pulse (units µs)

	lda #20
	jsr pbPause		; Wait 20 ms between pulses

	lda PULSE_WIDTH,s	; increment the pulse width
	sec
	sbc #10
	cmp #500		; loop until 180°
	bne @sweep_down

	bra @loop
.endproc
