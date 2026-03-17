; -----------------------------------------------------------------------------
; print definitions and macros.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

;
; Macros
;

; These print macros are intended for debugging.
; Use in the main code responsibly.
.macro PRINT MSG
	pha
	lda #MSG
	jsr hal_cputs
	pla
.endmacro

.macro PRINTCR
	pha
	lda #C_RETURN
	jsr hal_putch
	pla
.endmacro

.macro PRINTLN MSG
       PRINT MSG
       PRINTCR
.endmacro

.macro PRINTC
       jsr print_chex
.endmacro

.macro PRINTLN_POP msg
	PRINT msg
	POP
	PRINTC
	PRINTCR
.endmacro

; Conditionally import via functions in consuming modules.
.ifndef __print_s__
.import print_cdec
.import print_cudec
.import print_ahex
.import print_chex
.endif
