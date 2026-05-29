; =============================================================================
; hal_header.asm — WDC boot signature and HAL entry point
;
; The W65C265S masked ROM checks for the ASCII string "WDC" at $8000–$8002.
; If found it does JMP $8004, entering our code with:
;   native mode, A=8-bit, X/Y=16-bit, I=1, D=0, SP=$01FF
;
; Layout:
;   $8000–$8002   "WDC" signature (3 bytes)
;   $8003         $00  padding
;   $8004         JMP hal_reset  (3 bytes — lands in HAL_CODE segment)
;
; The signature occupies the HAL_SIG segment ($8000–$8003).
; The JMP is the first instruction of the HAL_CODE segment ($8004).
;
; Forth kernel detection:
;   After HAL init completes, hal_probe_forth searches for a Forth
;   signature at a location within $8004–$BEEF. The exact address is
;   agreed between the HAL and the Forth build — see hal_sfr.inc for
;   FORTH_PROBE_ADDR and FORTH_ENTRY_ADDR constants.
; =============================================================================

        .p816
        .smart  off

        .include "macros.inc"
        .include "hal_sfr.inc"

        .global hal_reset

; =============================================================================
; WDC boot signature — must be exactly at $8000
; =============================================================================

        .segment "HAL_SIG"

        .byte   "WDC"           ; $8000–$8002: signature checked by masked ROM
        .byte   $00             ; $8003: padding

; =============================================================================
; HAL entry point — must be exactly at $8004
;
; Masked ROM does JMP $8004. We immediately jump to hal_reset which
; contains the full initialisation sequence. This indirection allows
; hal_reset to live anywhere in the HAL_CODE region rather than being
; forced to start at $8004.
; =============================================================================

        .segment "HAL_CODE"

        JMP     hal_reset       ; $8004–$8006: enter HAL init
