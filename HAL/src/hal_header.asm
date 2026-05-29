; =============================================================================
; hal_header.asm — WDC boot signature and HAL entry point
;
; The W65C265S masked ROM checks for "WDC" at $8000–$8002.
; If found it does JMP $8004, entering our code with:
;   native mode, A=8-bit, X/Y=16-bit, I=1, D=0, SP=$01FF
;
; Both the signature and the entry JMP are in the HAL_SIG segment,
; guaranteeing the JMP is at exactly $8004 regardless of linker ordering.
;
; Layout:
;   $8000–$8002   "WDC" signature
;   $8003         $00  padding
;   $8004–$8006   JMP hal_reset
; =============================================================================

        .p816
        .smart  off

        .include "macros.inc"
        .include "hal_sfr.inc"

        .global hal_reset

        .segment "HAL_SIG"

        .byte   "WDC"           ; $8000–$8002: boot signature
        .byte   $00             ; $8003: padding
        JMP     hal_reset       ; $8004–$8006: enter HAL init
