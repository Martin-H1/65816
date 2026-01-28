; -----------------------------------------------------------------------------
; PBasic function definitions.
; This module is a set of PBasic like functions to use for pin I/O. The goal
; is to ease porting applications from the Basic Stamp to this platform.
; Register linkage is used for efficiency. For more information see:
; www.parallax.com/go/PBASICHelp/Content/LanguageTopics/Reference/AlphaRef.htm
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

__pbasic_asm__ = 1

.include "common.inc"
.include "pbasic.inc"
.include "via.inc"

;
; Aliases
;
CLK_FREQ = 3686400		; cycles per second
ONE_MS = CLK_FREQ / 1000	; cycles per ms
ONE_US = CLK_FREQ / 1000000	; cycles per us
T2IF = $20			; Timer 2 interupt flag bit

;
; Macros
;

;
; Static data
;
bitsetMask:	.word $0100, $0200, $0400, $0800, $1000, $2000, $4000, $8000
		.word $0001, $0002, $0004, $0008, $0010, $0020, $0040, $0080

;
; Functions
;

; Debugged: pbHigh, pbInput, pbLow, pbOutput, pbPause, pbToggle
; Todo: pbCount, pbFreqOut, pbPulsin, pbPulsout, pbRCTime


; pbCount - counts the number of cycles (0-1-0 or 1-0-1) on the specified pin
; during the duration time frame and return that number.
; Inputs:
;   A - index (0-15) of the I/O pin to use. Pin is set to input mode.
;   X - unsigned quantity (1-65535) specifying the time in milliseconds.
; Outputs:
;   A - the number of transitions.
PUBLIC pbCount
	LAST_VALUE = 0		; stack offsets for local variables.
	PIN_MASK = 2
	COUNT = 4
	pea $0000		; initialize count stack local
	txy			; save time parameter to Y
	jsr pbInput		; set pin to input
	phx			; initialize pin mask stack local
	txa
	ora VIA_BASE+VIA_PRB	; Get initial the value
	pha			; initial value stack local

@while:	OFF16MEM		; enter byte transfer mode.
	stz VIA_BASE+VIA_ACR	; select one shot mode
	lda #<ONE_MS
	sta VIA_BASE+VIA_T2CL	; store a word in lower and upper latch.
	lda #>ONE_MS
	sta VIA_BASE+VIA_T2CH	; set upper latch
	ON16MEM

@loop:	lda PIN_MASK,s
	ora VIA_BASE+VIA_PRB	; get the current state
	eor LAST_VALUE,s	; compare with previous state
	beq @endif

	lda COUNT,s		; increment the count
	inc
	sta COUNT,s
	lda VIA_BASE+VIA_PRB	; update current state.
	sta LAST_VALUE,s

@endif:	lda #T2IF		; timer 2 mask
	bit VIA_BASE+VIA_IFR	; timed out?
	beq @loop

	lda VIA_BASE+VIA_T2CL	; clear timer 2 interrupt flag
	dey
	bpl @while

	pla			; drop last value
	pla			; drop pin mask
	pla			; return count in A
	rts
ENDPUBLIC

; pbFreqOut - outputs a square wave for specified duration and frequency.
; Inputs:
;   A - index (0-15) of the I/O pin to use. Pin is set to output mode.
;   X - unsigned quantity (1-65535) specifying the duration in milliseconds.
;   Y - unsigned quantity (1-65535) specifying the frequnecy in hertz.
; Outputs:
;   None
PUBLIC pbFreqOut
	rts
ENDPUBLIC

; pbHigh - puts the specified pin in output mode and high state.
; Inputs:
;   A - index (0-15) of the I/O pin to use. Pin is set to output mode.
; Outputs:
;   None
PUBLIC pbHigh
	jsr pbOutput
	lda bitsetMask,x	; transform the index into a bitmask.
	ora VIA_BASE+VIA_PRB	; use mask to set pin high
	sta VIA_BASE+VIA_PRB
	rts
ENDPUBLIC

; pbInput - puts the specified pin in input mode.
; Inputs:
;   A - index (0-15) of the I/O pin to use. Pin is set to input mode.
; Outputs:
;   None
PUBLIC pbInput
	ora #$000f		; contrain input to valid values.
	asl			; convert to word index.
	tax
	lda bitsetMask,x	; transform the index into a bitmask.
	eor #$ffff		; invert to clear the bit.
	and VIA_BASE+VIA_DDRB	; or with existing pin state.
	sta VIA_BASE+VIA_DDRB	; set the pin's bit high.
	rts
ENDPUBLIC

; pbLow - puts the specified pin in output mode and low state.
; Inputs:
;   A - index (0-15) of the I/O pin to use. Pin is set to output mode.
; Outputs:
;   None
PUBLIC pbLow
	jsr pbOutput
	lda bitsetMask,x	; transform the index into a bitmask.
	eor #$ffff		; invert mask to clear bit.
	and VIA_BASE+VIA_PRB
	sta VIA_BASE+VIA_PRB
	rts
ENDPUBLIC

; pbOutput - puts the specified pin into output mode.
; Inputs:
;   A - index (0-15) of the I/O pin to use. Pin is set to output mode.
; Outputs:
;   None
PUBLIC pbOutput
	and #$000f		; constrain input to valid values.
	asl			; convert to word index.
	tax
	lda bitsetMask,x	; transform the index into a bitmask.
	ora VIA_BASE+VIA_DDRB	; or with existing pin state.
	sta VIA_BASE+VIA_DDRB	; set the pin's bit high.
	rts
ENDPUBLIC

; pbPause - delays execution for the specified number of milliseconds.
; Inputs:
;   A - number of milliseconds to suspend execution.
; Outputs: None
PUBLIC pbPause
	tax
	OFF16MEM		; enter byte transfer mode.
@while:	lda #$00
	sta VIA_BASE+VIA_ACR	; select one shot mode
	lda #<ONE_MS		; one ms delay duration
	sta VIA_BASE+VIA_T2CL	; set lower latch
	lda #>ONE_MS
	sta VIA_BASE+VIA_T2CH	; set upper latch
	lda #T2IF		; start mask
@loop:	bit VIA_BASE+VIA_IFR	; time out?
	beq @loop
	lda VIA_BASE+VIA_T2CL	; clear timer 2 interrupt
	dex
	bpl @while
	ON16MEM
	rts
ENDPUBLIC

; pbPulsin - measures the width of a pulse on a pin and returns the results.
; Inputs:
;   A - index (0-15) of the I/O pin to use. Pin is set to input mode.
;   X - boolean (0-1) that specifies whether the pulse to be measured is
; 	low (0) or high (1). A low pulse begins with a 1-to-0 transition and
;	a high pulse begins with a 0-to-1 transition.
; Outputs:
;   A - the measured pulse duration in uS.
PUBLIC pbPulsin
	phx
	jsr pbInput
	txy

				; wait for pulse leading edge transition.
	OFF16MEM		; start VIA timer

	lda #$00
	sta VIA_BASE+VIA_ACR	; select one shot mode
	lda #$ff		; load timer with maximum value.
	sta VIA_BASE+VIA_T2CL	; set lower latch
	sta VIA_BASE+VIA_T2CH	; set upper latch
	lda #T2IF		; start mask
				; wait for pulse trailing edge transition.

@loop:	bit VIA_BASE+VIA_IFR	; time out?
	beq @loop
	lda VIA_BASE+VIA_T2CL	; clear timer 2 interrupt
	dex
	ON16MEM



	rts
ENDPUBLIC

; pbPulsout - generate a pulse on pin with a width of duration in uS.
; Inputs:
;   A - index (0-15) of the I/O pin to use. Pin is set to output mode.
;   X - specifies the duration (0-65535) of the pulse width in uS.
; Outputs:
;   None
PUBLIC pbPulsout
	pha
	phx
	jsr pbHigh
	pla
	jsr pbPause
	pla
	jsr pbLow
	rts
ENDPUBLIC

; pbPWM - converts a digital value (0-255) to analog output via pulse width
; modulation. This allows the generation of an analog voltage by emitting a
; burst of output high (5V) and low (0V) values whose ratio is proportional
; to the duty value specified. The duration is the amount of time the signal
; is generated to allow the analog device to average the voltage over time
; to duty/256* 5 volts.
; Inputs:
;   A - index (0-15) of the I/O pin to set. Pin is initially set to output
;	then to input mode when the command finishes.
;   X - the duty (0-255) of analog output as the number of 256ths of 5V.
;   Y - the duration (0-255) of the PWM output in mS.
; Outputs:
;   None
PUBLIC pbPWM
	rts
ENDPUBLIC

; pbRCTime - measures the time a pin remains in its initial state. This allows
; measurement of the charge/discharge time of resistor/capacitor (RC) circuit
; and indirectly an analog value via the RC circuit charge or discharge time.
; Commonly used with R or C sensors such as thermistors or potentiometers.
; Inputs:
;   A - index (0-15) of the I/O pin to set. Pin is set to input.
;   X - Initial state either HIGH or LOW to measure. Once Pin is not in State,
;	the command ends and returns that time.
; Outputs:
;   A - time measured in uS
PUBLIC pbRCTime
	phx
	jsr pbInput		; set the pin to input
	tay			; save the pin mask

	php
	OFF16MEM		; Enter byte transfer mode.
@while:	lda #$00
	sta VIA_BASE+VIA_ACR	; select one shot mode
	lda #<ONE_MS		; one ms delay duration
	sta VIA_BASE+VIA_T2CL	; set lower latch
	lda #>ONE_MS
	sta VIA_BASE+VIA_T2CH	; set upper latch
	lda #T2IF		; start mask
@loop:	bit VIA_BASE+VIA_IFR	; time out?
	beq @loop
	lda VIA_BASE+VIA_T2CL	; clear timer 2 interrupt


	ON16MEM
	plp

	rts
ENDPUBLIC

; pbToggle - inverts the state of an output pin.
; Inputs:
;   A - index (0-15) of the I/O pin to set. Pin is set to output mode.
; Outputs:
;   None
PUBLIC pbToggle
	jsr pbOutput
	lda bitsetMask,x	; transform the index into a bitmask.
	eor VIA_BASE+VIA_PRB
	sta VIA_BASE+VIA_PRB
	rts
ENDPUBLIC
