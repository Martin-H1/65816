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
.include "w65c265Monitor.inc"

;
; Aliases
;

;
; Macros
;

;
; Functions
;

; pbCount - counts the number of cycles (0-1-0 or 1-0-1) on the specified pin
; during the duration time frame and return that number.
; Inputs:
;   A - index (0-15) of the I/O pin to use. Pin is set to input mode.
;   X - unsigned quantity (1-65535) specifying the time in milliseconds.
; Outputs:
;   A - the number of transitions.
PUBLIC pbCount
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
	rts
ENDPUBLIC

; pbInput - puts the specified pin in input mode.
; Inputs:
;   A - index (0-15) of the I/O pin to use. Pin is set to input mode.
; Outputs:
;   None
PUBLIC pbInput
	rts
ENDPUBLIC

; pbLow - puts the specified pin in output mode and low state.
; Inputs:
;   A - index (0-15) of the I/O pin to use. Pin is set to output mode.
; Outputs:
;   None
PUBLIC pbLow
	rts
ENDPUBLIC

; pbOutput - puts the specified pin into output mode.
; Inputs:
;   A - index (0-15) of the I/O pin to use. Pin is set to output mode.
; Outputs:
;   None
PUBLIC pbOutput
	rts
ENDPUBLIC

; pbPause - delays execution for the specified number of milliseconds.
; Inputs:
;   A - index (0-15) of the I/O pin to use. Pin is set to input mode.
; Outputs: None
PUBLIC pbPause
	php
	tax
	OFF16MEM		; Enter byte transfer mode.
@while:	lda #$00
	sta VIA_BASE+VIA_ACR	; select one shot mode
	sta VIA_BASE+VIA_T2CL	; set lower latch to zero
	lda #$0f		; one ms delay duration
	sta VIA_BASE+VIA_T2CH	; high part = 01.  Start
	lda #$20		; mask
@loop:	bit VIA_BASE+VIA_IFR	; time out?
	beq @loop
	lda VIA_BASE+VIA_T2CL	; clear timer 2 interrupt
	dex
	bpl @while
	plp
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
	rts
ENDPUBLIC

; pbPulsout - generate a pulse on pin with a width of duration in uS.
; Inputs:
;   A - index (0-15) of the I/O pin to use. Pin is set to output mode.
;   X - specifies the duration (0-65535) of the pulse width in uS.
; Outputs:
;   None
PUBLIC pbPulsout
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
	rts
ENDPUBLIC

; pbToggle - inverts the state of an output pin.
; Inputs:
;   A - index (0-15) of the I/O pin to set. Pin is set to output mode.
; Outputs:
;   None
PUBLIC pbToggle
	rts
ENDPUBLIC
