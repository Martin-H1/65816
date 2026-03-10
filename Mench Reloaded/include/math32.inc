; -----------------------------------------------------------------------------
; 32 bit math function definitions, macros, and function prototypes.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

;
; Aliases
;

STACKBASE = $00                   ; normally 0
ZR        = $00                   ; 0 four 32 bit scratch cells
WR        = ZR+4                  ; 4
XR        = WR+4                  ; 8
YR        = XR+4                  ; c

; Conditionally import via functions in consuming modules.
.ifndef __math32_asm__

.endif
