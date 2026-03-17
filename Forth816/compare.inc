; -----------------------------------------------------------------------------
; Forth Kernel Comparison and Logic Primitives header.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

; Conditionally import via functions in consuming modules.
.ifndef __compare_s__

.import EQUAL_CODE
.import NOTEQUAL_CODE
.import LESS_CODE
.import GREATER_CODE
.import ULESS_CODE
.import UGREATER_CODE
.import ZEROEQ_CODE
.import ZEROLESS_CODE
.import ZEROGT_CODE
.import AND_CODE
.import OR_CODE
.import XOR_CODE
.import INVERT_CODE
.import LSHIFT_CODE
.import RSHIFT_CODE

.endif
