; -----------------------------------------------------------------------------
; Print function definitions.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

__print_asm__ = 1

.include "common.inc"
.include "print.inc"
.include "w65c265Monitor.inc"

;
; Functions
;

; printcdec - prints C as a signed 16 bit decimal number to console
; Inputs:
;   C - number
; Outputs:
;   C - preserved
PUBLIC f_printcdec
	and #$ffff
	bpl f_printcudec	; positive numbers require no processing
	pha
	pha
	lda #'-'		; Print sign
	putch
	pla			; undo the two's complement
	dec
	eor #$ffff
	jsr f_printcudec
	pla
	rts
ENDPUBLIC

; printcudec - prints C as an unsigned 16 bit decimal number to console
; Inputs:
;   C - number
; Outputs:
;   C - preserved
PUBLIC f_printcudec
	php			; save processor status
	phd			; save direct page register
	phx
	phy
	pha

	NUM_MSB = 4
	NUM_LSB = 3
	BCD = 2
	COUNTER = 1

	pha			; Establish working area
	pea $0000		; reserve working area on stack

	tsc			; transfer stack pointer to direct page reg
	tcd			; function local space is now direct page.

	OFF16MEM		; Switch to byte mode.

	lda #0			; null delimiter for print loop
	pha

@while:				; divide TOS by 10
	stz BCD			; clr BCD
	lda #16
	sta COUNTER		; {>} = loop counter
@foreachbit:
	asl NUM_LSB		; TOS is gradually replaced
	rol NUM_MSB		; with the quotient
	rol BCD			; BCD result is gradually replaced
	lda BCD			; with the remainder
	sec
	sbc #10			; partial BCD >= 10 ?
	bcc @else
	sta BCD			; yes: update the partial result
	inc NUM_LSB		; set low bit in partial quotient
@else:
	dec COUNTER
	bne @foreachbit		; loop 16 times
	lda BCD
	ora #'0'		; convert BCD result to ASCII
	pha			; stack digits in ascending
	lda NUM_LSB		; order ('0' for zero)
	ora NUM_MSB
	bne @while		; } until TOS is 0

@print:
	pla
@loop:
	putch			; print digits in descending order
	pla			; until null delimiter is encountered
	bne @loop

@return:
	ON16MEM			; exit byte mode
	pla			; clean up working area
	pla

	pla			; restore registers and return
	ply
	plx
	pld
	plp
	rts
ENDPUBLIC
