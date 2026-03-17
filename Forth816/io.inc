; -----------------------------------------------------------------------------
; Forth Kernel I/O Primitives header.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

; Conditionally import via functions in consuming modules.
.ifndef __io_s__

.import EMIT_CODE
.import KEY_CODE
.import KEYQ_CODE
.import TYPE_CODE
.import CR_CODE
.import SPACE_CODE
.import SPACES_CODE

.endif

