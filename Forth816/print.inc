; -----------------------------------------------------------------------------
; print definitions and macros.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

;
; Macros
;
.macro print MSG
	pha
	lda #MSG
	jsr hal_cputs
	pla
.endmacro

.macro printcr
	pha
	lda #C_RETURN
	jsr hal_putch
	pla
.endmacro

.macro println MSG
       print MSG
       printcr
.endmacro

.macro printc
       jsr print_chex
.endmacro

; Conditionally import via functions in consuming modules.
.ifndef __print_s__
.import print_cdec
.import print_cudec
.import print_ahex
.import print_chex
.endif
