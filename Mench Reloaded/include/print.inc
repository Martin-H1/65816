; -----------------------------------------------------------------------------
; print definitions and macros.
; Syntactic sugar around monitor print functions.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

;
; Macros
;

.macro getputch
       jsr f_get_putch
.endmacro

.macro print MSG
	php
	phx
	pha
	OFF16MEM
	phb
	pla
	ldx #MSG
	jsr f_print
	ON16MEM
	pla
	plx
	plp
.endmacro

.macro printcr
	pha
	lda #C_RETURN
	jsr f_putch
	pla
.endmacro

.macro println MSG
       print MSG
       printcr
.endmacro

.macro printa
       jsr f_printa
.endmacro

.macro printc
       jsr f_printc
.endmacro

.macro printcdec
       jsr f_printcdec
.endmacro

.macro printcudec
       jsr f_printcudec
.endmacro

.macro printch
	jsr f_putch
.endmacro

; Conditionally import via functions in consuming modules.
.ifndef __print_asm__
.import f_get_putch
.import f_print
.import f_printa
.import f_printc
.import f_printcdec
.import f_printcudec
.import f_putch
.endif
