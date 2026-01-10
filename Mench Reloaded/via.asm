; -----------------------------------------------------------------------------
; VIA function definitions.
; Took code from Rich Cini's SBC OS, made it generic using macros, and ported
; to the 65816. Note: This module assumes accumulator is in bit mode as the
; VIA is a byte oriented device.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

__via_asm__ = 1

.include "common.inc"
.include "via.inc"

;
; Functions
;

; Initializes via and requires no arguments.
PUBLIC viaInit
	lda #00
	ldy #VIA_PCR		; zero out lower regsiters
@loop:	sta VIA_BASE,y
	dey
	bpl @loop
	lda #$7f		; init two upper registers.
	sta VIA_BASE + VIA_IFR
	sta VIA_BASE + VIA_IER
	rts
ENDPUBLIC

PUBLIC viaTimer2Delay
	lda #$00
	sta VIA_BASE+VIA_ACR	; select one shot mode
	sta VIA_BASE+VIA_T2CL	; set lower latch to zero
	lda #$01		; delay duration
	sta VIA_BASE+VIA_T2CH	; high part = 01.  Start
	lda #$20		; mask
@loop:	bit VIA_BASE+VIA_IFR	; time out?
	beq @loop
	lda VIA_BASE+VIA_T2CL	; clear timer 2 interrupt
	rts
ENDPUBLIC
