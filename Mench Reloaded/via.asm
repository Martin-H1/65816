; -----------------------------------------------------------------------------
; VIA function definitions.
; Took code from Rich Cini's SBC OS, made it generic using macros, and
; ported to the 65816.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

.include "common.inc"
.include "via.inc"

;
; Functions
;
PUBLIC via1Init
	OFF16MEM
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
