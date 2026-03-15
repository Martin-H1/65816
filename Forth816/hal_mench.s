;==============================================================================
; hal_mench.s - Hardware Abstraction Layer (HAL) for the Mench Reloaded SBC.
; Martin Heermance <mheermance@gmail.com>
;==============================================================================

__hal_s__ = 1

.p816
.smart off

.include "macros.inc"
.include "forth.inc"
.include "hal.inc"

;==============================================================================
; CODE SEGMENT - ROM kernel
;==============================================================================
.segment "CODE"

; reads a CR terminated line from console into buffer
PUBLIC hal_cgets
	rts
ENDPUBLIC

; prints a null terminated string to the console.
PUBLIC hal_cputs	
	rts
ENDPUBLIC

; returns a character from the terminal input buffer.
PUBLIC hal_getch
	rts
ENDPUBLIC

; returns a character in A into the terminal input buffer.
PUBLIC hal_ungetch
	rts
ENDPUBLIC

; puts a character in A to console.
PUBLIC hal_putch
	rts
ENDPUBLIC

; enable/disable character echo during line editing.
PUBLIC hal_setecho
	rts
ENDPUBLIC

; sets a callback for a BRK instruction handler.
PUBLIC hal_set_brk	
	rts
ENDPUBLIC

; sets a callback for an interrupt handler.
PUBLIC hal_set_isr
	rts
ENDPUBLIC

; sets a callback for a non-maskable interrupt handler.
PUBLIC hal_set_nmi
	rts
ENDPUBLIC

;==============================================================================
; HARDWARE VECTORS
;==============================================================================
.segment "VECTORS"

; Emulation mode vectors ($FFE0-$FFEF are unused/reserved)

.word $0000			; $FFE0 - unused
.word $0000			; $FFE2 - unused
.word $0000			; $FFE4 - COP (emulation)
.word $0000			; $FFE6 - unused
.word $0000			; $FFE8 - ABORT (emulation)
.word $0000			; $FFEA - unused
.word $0000			; $FFEC - NMI (emulation)
.word FORTH_INIT		; $FFEE - RESET (emulation) init

; Native mode vectors ($FFF0-$FFFF)
.word $0000			; $FFF0 - COP (native)
.word $0000			; $FFF2 - BRK (native)
.word $0000			; $FFF4 - ABORT (native)
.word $0000			; $FFF6 - unused
.word $0000			; $FFF8 - NMI (native)
.word FORTH_INIT		; $FFFA - unused
.word FORTH_INIT		; $FFFC - RESET (native)
.word $0000			; $FFFE - IRQ/BRK (native)
