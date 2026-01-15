; -----------------------------------------------------------------------------
; VIA function definitions.
; Took code from Rich Cini's SBC OS, made it generic using macros, and ported
; to the 65816.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

__via_asm__ = 1

.include "common.inc"
.include "via.inc"
.include "w65c265Monitor.inc"

; Note: This module sets accumulator to 8 bit mode as the VIA is a byte
; oriented device. But it restores prior settings before returning to caller.

;
; Functions
;

; Initializes via and requires no arguments.
PUBLIC viaInit
	php
	OFF16MEM		; Enter byte transfer mode.
	lda #$00
	ldy #VIA_PCR		; zero out lower regsiters
@loop:	sta VIA_BASE,y
	dey
	bpl @loop
	lda #$7f		; init two upper registers.
	sta VIA_BASE + VIA_IFR
	sta VIA_BASE + VIA_IER
	plp
	rts
ENDPUBLIC
