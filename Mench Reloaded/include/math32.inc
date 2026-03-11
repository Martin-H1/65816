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

;
; Macros
;
.macro inclong var
.scope
	inc var
        bne @over
        inc var+2
@over:
.endscope
.endmacro

; Conditionally import via functions in consuming modules.
.ifndef __math32_asm__
.import _add32
.import _sub32
.import _umult32
.import _udivmod32
.import _popay
.import _pushay
.import _stest32
.import _swap
.endif
