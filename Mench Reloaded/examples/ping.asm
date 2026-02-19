; -----------------------------------------------------------------------------
; Ping))) sensor sample for the Mench Reloaded SBC.
; Read a PING))) ultrasonic rangefinder and return the distance to the closest
; object in range. Do this by sending a pulse to the sensor to initiate a
; reading, then listens for a pulse to return. The length of the returning
; pulse is proportional to the distance of the object from the sensor.
; The circuit:
; - Ping))) control pin is attached to VIA port B pin 0.
; - Ping))) power and ground are connected to respective VIA header pins.
;
; Notes:
; - Ping))) draws too much current for USB power. You must use battery power.
;
; - For more information on Ping))) read:
;   https://www.parallax.com/package/ping-ultrasonic-distance-sensor-downloads/
;
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

.include "ascii.inc"
.include "common.inc"
.include "math16.inc"
.include "pbasic.inc"
.include "print.inc"
.include "via.inc"

PING_PIN = 8			; Port B pin 0
PULSE_WIDTH = 5 * ONE_US	; Ping))) activated by a pulse of 2 or more uS

; Parallax's Ping))) datasheet says there are 73.746 microseconds per inch
; To get the distance divide the pulse width by 2 times a scaling factor.
; It's two times because of pulse outbound and return time.
INCH_SCALE_FACTOR = 2 * 74 * ONE_US

; The speed of sound is 340 m/s or 29 microseconds per centimeter. The pulse
; travels out and back, so again we divide by two times a scaling factor.
CM_SCALE_FACTOR = 2 * 29 * ONE_US

PUBLIC main
	jsr viaInit		; one time VIA initialization.
	printcr			; start output on a newline
	ON16MEM
	ON16X

	CYCLES = 1		; stack local for cycle count
	pea $0000
@loop:
	lda #PING_PIN		; set the pin to output and low for several
	jsr pbLow		; machine cycles to ensure a clean HIGH pulse.

	lda #PING_PIN		; send activation pulse
	ldx #PULSE_WIDTH
	jsr pbPulsout

	lda #PING_PIN		; read response pulse from the Ping))) which
	ldx #LOW		; is a LOW-HIGH-LOW pulse with duration
	jsr pbPulsin		; proportional to the echo off an object.
	sta CYCLES,s		; save for using multiple times.

	printcudec		; print cpu cycle count.
	print cycles

	lda CYCLES,s		; convert time to distance units and output.
	tax
	lda #INCH_SCALE_FACTOR
	jsr udiv16
	printcudec
	print inches

	lda CYCLES,s
	tax
	lda #CM_SCALE_FACTOR
	jsr udiv16
	printcudec
	println centi

	lda #100
	jsr pbPause

	jmp @loop
ENDPUBLIC

cycles:	.asciiz " cycles, "
inches:	.asciiz " in, "
centi:	.asciiz " cm"
