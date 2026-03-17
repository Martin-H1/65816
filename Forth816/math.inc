; -----------------------------------------------------------------------------
; Forth Kernel Mathematics Primitives header.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

; Conditionally import via functions in consuming modules.
.ifndef __math_s__

.import PLUS_CODE
.import MINUS_CODE
.import STAR_CODE
.import UMSTAR_CODE
.import UMSLASHMOD_CODE
.import SLASHMOD_CODE
.import SLASH_CODE
.import MOD_CODE
.import NEGATE_CODE
.import ABS_CODE
.import MAX_CODE
.import MIN_CODE
.import ONEPLUS_CODE
.import ONEMINUS_CODE
.import TWOSTAR_CODE
.import TWOSLASH_CODE

.endif
