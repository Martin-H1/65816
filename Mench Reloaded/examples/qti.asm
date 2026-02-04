; -----------------------------------------------------------------------------
; QTI sensor sample for the Mench Reloaded SBC.
; Reads a Parallax QTI or Pololu QTR line sensor using RCTime.
; The circuit:
; - Line sensor power pin is attached to VIA port B pin 0.
; - Line sensor input pin is attached to VIA port B pin 1.
; - Line sensor ground is connected to VIA port ground.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

.include "ascii.inc"
.include "common.inc"
.include "pbasic.inc"
.include "print.inc"
.include "via.inc"
.include "w65c265Monitor.inc"

LINE_SENSOR_PWR = 8		; Optional as you can connect sensor to +5v
LINE_SENSOR_IN = 9		; Data pin from line sensor.

PUBLIC main
@loop:
	jsr viaInit		; one time VIA initialization.
	jsl SEND_CR		; start output on a newline

	ON16MEM
	ON16X

	lda LINE_SENSOR_PWR	; Activate sensor IR LED
	jsr pbHigh

	lda LINE_SENSOR_IN	; discharge sensor capacitor
	jsr pbHigh

	lda #1			; wait for discharge
	jsr pbPause

	lda LINE_SENSOR_IN
	ldx #HIGH
	jsr pbRCTime		; read sensor value

	pha
	lda LINE_SENSOR_PWR	; deactivate sensor IR LED
	jsr pbLow

	print msg
	pla
	printa
	printcr

	lda #100		; wait a tenth of a second between readings.
	jsr pbPause

	bra @loop
ENDPUBLIC

msg:	.asciiz "sensor = "
