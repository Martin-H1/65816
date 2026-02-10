; -----------------------------------------------------------------------------
; Math function definitions, macros, and function prototypes.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

;
; Aliases
;

; Conditionally import via functions in consuming modules.
.ifndef __math16_asm__
.import abs16
.import udiv16
.import umax16
.import umin16
.import umult16
.import usqrt16
.endif
