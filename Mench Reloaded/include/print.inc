; -----------------------------------------------------------------------------
; print definitions and macros.
; Syntactic sugar around monitor print functions.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

;
; Macros
;

.macro print MSG
	php
	OFF16MEM
	lda #$00
	ldx #MSG
	jsl PUT_STR
	ON16MEM
	plp
.endmacro

.macro printcr
	php
	OFF16MEM
	jsl SEND_CR
	ON16MEM
	plp
.endmacro

.macro println MSG
	php
	OFF16MEM
	lda #$00
	ldx #MSG
	jsl PUT_STR
	jsl SEND_CR
	ON16MEM
	plp
.endmacro

.macro printa
	pha
	php
	OFF16MEM

	pha
	xba
	jsl SEND_HEX_OUT
	pla
	jsl SEND_HEX_OUT

	ON16MEM
	plp
	pla
.endmacro

.macro putch
	jsl PUT_CHR
.endmacro
