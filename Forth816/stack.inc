; -----------------------------------------------------------------------------
; Forth Kernel Stack Primitives header.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

; Conditionally import via functions in consuming modules.
.ifndef __stack_s__

.import DUP_CODE
.import DROP_CODE
.import SWAP_CODE
.import OVER_CODE
.import ROT_CODE
.import NIP_CODE
.import TUCK_CODE
.import TWODROP_CODE
.import TWODUP_CODE
.import TWOSWAP_CODE
.import TWOOVER_CODE
.import DEPTH_CODE
.import PICK_CODE
.import TOR_CODE
.import RFROM_CODE
.import RFETCH_CODE

.endif
