; -----------------------------------------------------------------------------
; print definitions and macros.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

;
; Macros
;

; Conditionally import via functions in consuming modules.
.ifndef __print_s__
.import print_cdec
.import print_cudec
.endif
