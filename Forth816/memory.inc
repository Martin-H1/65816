; -----------------------------------------------------------------------------
; Forth Kernel Memory Primitives header.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

; Conditionally import via functions in consuming modules.
.ifndef __memory_s__

.import FETCH_CODE
.import STORE_CODE
.import CFETCH_CODE
.import CSTORE_CODE
.import TWOFETCH_CODE
.import TWOSTORE_CODE
.import MOVE_CODE
.import FILL_CODE

.endif
