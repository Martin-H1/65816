; -----------------------------------------------------------------------------
; Math function definitions, macros, and function prototypes.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

;
; Aliases
;

; Conditionally import via functions in consuming modules.
.ifndef __math16_asm__
.import div16
.import mult16
.import sqrt16
.endif
