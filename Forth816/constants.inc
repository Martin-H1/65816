;==============================================================================
; constants.inc - Shared numeric constants for 65816 Forth kernel
;
; Included by both forth.s and primitives.s (and any other files that
; need these values). Numeric constants defined with = can't be exported
; via .global/.import in ca65 -- the solution is a shared include file.
;==============================================================================

.ifndef CONSTANTS_INC
CONSTANTS_INC = 1

; Stack addresses
PSP_INIT        = $03FF         ; Parameter stack initial pointer
RSP_INIT        = $01FF         ; Return stack initial pointer (hardware)

; User area base and offsets
UP_BASE         = $0400
U_BASE          = $00           ; Numeric base          (cell)
U_STATE         = $02           ; Compile state         (cell, 0=interp)
U_DP            = $04           ; Dictionary pointer    (cell)
U_LATEST        = $06           ; Latest definition     (cell)
U_TIB           = $08           ; TIB address           (cell)
U_TOIN          = $0A           ; >IN parse offset      (cell)
U_SOURCELEN     = $0C           ; Source string length  (cell)
U_HANDLER       = $0E           ; Exception handler     (cell)

; Terminal Input Buffer
TIB_BASE        = $0500
TIB_SIZE        = $0100

; RAM dictionary
DICT_BASE       = $0600

; ANS Forth boolean values
FORTH_TRUE      = $FFFF
FORTH_FALSE     = $0000

.endif ; CONSTANTS_INC
