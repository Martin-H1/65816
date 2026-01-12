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

; Ideally create a set of PBasic like functions for pin I/O
; CONFIGPIN	CONFIGPIN Mode, PinMask
; COUNT		COUNT Pin, Duration, Variable
; FREQOUT		FREQOUT Pin, Duration, Freq1 {, Freq2 }
; HIGH		HIGH Pin
; INPUT		INPUT Pin
; LOW		LOW Pin
; OUTPUT		OUTPUT Pin
; PAUSE		PAUSE Duration
; PULSIN		PULSIN Pin, State, Variable
; PULSOUT		PULSOUT Pin, Duration
; PWM		PWM Pin, Duty, Duration
; RCTIME		RCTIME Pin, State, Variable
; TOGGLE		TOGGLE Pin

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

PUBLIC viaTimer2Delay
	php
	OFF16MEM		; Enter byte transfer mode.
	lda #$00
	sta VIA_BASE+VIA_ACR	; select one shot mode
	sta VIA_BASE+VIA_T2CL	; set lower latch to zero
	lda #$ff		; delay duration
	sta VIA_BASE+VIA_T2CH	; high part = 01.  Start
	lda #$20		; mask
@loop:	bit VIA_BASE+VIA_IFR	; time out?
	beq @loop
	lda VIA_BASE+VIA_T2CL	; clear timer 2 interrupt
	plp
	rts
ENDPUBLIC
