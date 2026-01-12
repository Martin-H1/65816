; -----------------------------------------------------------------------------
; VIA definitions, macros, and function prototypes.
; Took code from Rich Cini's SBC OS, made it generic using macros, and
; ported to the 65816 and ca65.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

; I/O Locations for the 6522 VIA chip registers
VIA_BASE	= $dfe0
VIA_PRB		= $00
VIA_PRA		= $01
VIA_DDRB	= $02
VIA_DDRA	= $03
VIA_T1CL	= $04
VIA_T1CH	= $05
VIA_T1LL	= $06
VIA_TALH	= $07
VIA_T2CL	= $08
VIA_T2CH	= $09
VIA_SR		= $0a
VIA_ACR		= $0b
VIA_PCR		= $0c
VIA_IFR		= $0d
VIA_IER		= $0e
VIA_PRA1	= $0f

HIGH = 1
LOW = 0

; Conditionally import via functions in consuming modules.
.ifndef __via_asm__

.import viaInit
.import viaTimer2Delay
; .import viaFreqOut
; .import viaPulseOut
; .import viaPWNOut
; .import viaRCTime
.endif
