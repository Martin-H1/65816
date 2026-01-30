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
bitsetMask:
         .word %0000000100000000 ; port 'A' masks.
         .word %0000001000000000
         .word %0000010000000000
         .word %0000100000000000
         .word %0001000000000000
         .word %0010000000000000
         .word %0100000000000000
         .word %1000000000000000

         .word %0000000000000001 ; port 'B' masks.
         .word %0000000000000010
         .word %0000000000000100
         .word %0000000000001000
         .word %0000000000010000
         .word %0000000000100000
         .word %0000000001000000
         .word %0000000010000000

;
; Functions
;

; Debugged: pbHigh, pbInput, pbLow, pbOutput, pbPause, pbToggle
; Todo: pbCount, pbFreqOut, pbINX, pbPulsin, pbPulsout, pbPWM, pbRCTime


; pbCount - counts the number of cycles (0-1-0 or 1-0-1) on the specified pin
; during the duration time frame and return that number.
; Inputs:
;   C - index (0-15) of the I/O pin to use. Pin is set to input mode.
;   X - unsigned quantity (1-65535) specifying the time in milliseconds.
; Outputs:
;   C - the number of transitions.
PUBLIC pbCount
	COUNT = 4
	PORT_MASK = 2
	LAST_VALUE = 0		; stack offsets for local variables.
	pea $0000		; initialize count stack local
	txy			; save time parameter to Y
	jsr pbInput		; set pin to input, return C as port mask
	pha			; initialize port mask stack local
	and VIA_BASE+VIA_PRB	; Get initial the value and set
	pha			; initial value stack local

@while:	OFF16MEM		; enter byte transfer mode.
	stz VIA_BASE+VIA_ACR	; select one shot mode
	lda #<ONE_MS
	sta VIA_BASE+VIA_T2CL	; store a word in lower and upper latch.
	lda #>ONE_MS
	sta VIA_BASE+VIA_T2CH	; set upper latch
	ON16MEM

@loop:	lda PORT_MASK,s
	and VIA_BASE+VIA_PRB	; get the current state
	eor LAST_VALUE,s	; compare with previous state
	beq @endif

	lda COUNT,s		; increment the count
	inc
	sta COUNT,s

	lda PORT_MASK,s
	and VIA_BASE+VIA_PRB	; get the current state
	sta LAST_VALUE,s	; update current state.

@endif:	OFF16MEM
	lda #T2IF		; timer 2 mask
	bit VIA_BASE+VIA_IFR	; timed out?
	ON16MEM
	beq @loop

	OFF16MEM
	lda VIA_BASE+VIA_T2CL	; clear timer 2 interrupt flag
	ON16MEM
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
;   Port mask in C, mask table index in X
;
; Notes:
;   pbHigh calls pbOutput, which results in A returning with the required
;   mask. Hence pbHigh doesn't need to reload it.
PUBLIC pbHigh
	jsr pbOutput		; set data direction...see above note
	tsb VIA_BASE+VIA_PRB	; use mask to set pin high
	rts
ENDPUBLIC

; pbInput - puts the specified pin in input mode.
; Inputs:
;   A - index (0-15) of the I/O pin to use. Pin is set to input mode.
; Outputs:
;   Port mask in C, mask table index in X
PUBLIC pbInput
	and #%1111		; constrain input to valid values.
	asl			; convert to word index.
	tax
	lda bitsetMask,x      	; transform the index into a bitmask.
	trb VIA_BASE+VIA_DDRB	; set the corresponding pin's bit high.
	rts
ENDPUBLIC

; pbINX - sets the pin as input and returns the current state.
; Inputs:
;   A - index (0-15) of the I/O pin to read. Pin is set to input mode.
; Outputs:
;   A - boolean pin state
PUBLIC pbINX
	jsr pbInput		; set pin to input, C contains port mask.
	and VIA_BASE+VIA_PRB	; Get initial the value
	beq @return
	lda #$0001
@return:
	rts
ENDPUBLIC

; pbLow - puts the specified pin in output mode and low state.
; Inputs:
;   A - index (0-15) of the I/O pin to use. Pin is set to output mode.
; Outputs:
;   Port mask in C, mask table index in X
;
; Notes:
;   pbLow calls pbOutput, which results in A returning with the required
;   mask. Hence pbLow doesn't need to reload it.
PUBLIC pbLow
	jsr pbOutput		; set pin to output and get port mask.
	trb VIA_BASE+VIA_PRB	; use mask to clear the bit.
	rts
ENDPUBLIC

; pbOutput - puts the specified pin into output mode.
; Inputs:
;   A - index (0-15) of the I/O pin to use. Pin is set to output mode.
; Outputs:
;   C - pin bitset mask
PUBLIC pbOutput
	and #%1111		; constrain input to valid values...
	asl			; convert to word index.
	tax
	lda bitsetMask,x      	; transform the index into a bitmask.
	tsb VIA_BASE+VIA_DDRB	; set the corresponding pin's bit high...
	rts
ENDPUBLIC

; pbPause - delays execution for the specified number of milliseconds.
; Inputs:
;   C - number of milliseconds to suspend execution.
; Outputs: None
PUBLIC pbPause
	tax
	OFF16MEM		; enter byte transfer mode.
@while:	stz VIA_BASE+VIA_ACR	; select one shot mode
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

; pbPulsin - measures the width of a pulse on a pin and return the results.
; Inputs:
;   C - index (0-15) of the I/O pin to use. Pin is set to input mode.
;   X - boolean (0-1) that specifies whether the pulse to be measured is
; 	low (0) or high (1). A low pulse begins with a 1-to-0 transition and
;	a high pulse begins with a 0-to-1 transition. Both end with the
;	reverse transition.
; Outputs:
;   C - the measured pulse duration in cpu cycles.
PUBLIC pbPulsin
	INITIAL_VALUE = 2	; stack offsets for local variables
	PORT_MASK = 0
	pea $0000		; reserve space for the initial value
	txy			; retain parameter in x
	jsr pbInput		; set pin to input and get port mask
	pha			; initialize port mask stack local
	cpy #$0001		; test desired initial value
	bne @leading_edge
	sta INITIAL_VALUE,s	; set initial value bit using port mask.
@leading_edge:
	lda PORT_MASK,s		; wait for pulse leading edge transition.
	and VIA_BASE+VIA_PRB	; get the current value.
	eor INITIAL_VALUE,s	; test for leading edge transition.
	bne @leading_edge
	OFF16MEM		; start VIA timer
	stz VIA_BASE+VIA_ACR	; select one shot mode
	lda #$ff		; load timer with maximum value.
	sta VIA_BASE+VIA_T2CL	; set lower latch
	sta VIA_BASE+VIA_T2CH	; set upper latch
@while:
	lda PORT_MASK,s
	and VIA_BASE+VIA_PRB	; get the current value.
	eor INITIAL_VALUE,s	; test for edge transition.
	bne @trailing_edge

	OFF16MEM		; has timer reached zero?
	lda #T2IF		; start mask
	bit VIA_BASE+VIA_IFR	; time out?
	ON16MEM
	beq @while
@trailing_edge:
	lda #$ffff
	sbc VIA_BASE+VIA_T2CL	; get value and clear timer 2 interrupt
	plx			; clean up stack
	plx
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
	DUTY = 2
	PORT_MASK = 0
	phx			; initialize duty cycle stack local
	jsr pbOutput
	pha			; initialize port mask stack local

@while:
	OFF16MEM		; enter byte transfer mode.
	stz VIA_BASE+VIA_ACR	; select one shot mode
	lda #<ONE_MS		; one ms delay duration
	sta VIA_BASE+VIA_T2CL	; set lower latch
	lda #>ONE_MS
	sta VIA_BASE+VIA_T2CH	; set upper latch
	ON16MEM
@loop:				; generate waveform here
	lda PORT_MASK,s
	tsb VIA_BASE+VIA_PRB	; use mask to set pin high

	lda DUTY,s		; keep high during duty cycle
	tax
@duty_wait:
	dex
	bne @duty_wait

	lda PORT_MASK,s
	trb VIA_BASE+VIA_PRB	; use mask to set pin low

	lda #$ff		; compute remainder
	sbc DUTY,s
@remainder_wait:		; keep low during remainder
	dex
	bne @remainder_wait

	OFF16MEM
	lda #T2IF		; start mask
	bit VIA_BASE+VIA_IFR	; time out?
	ON16MEM
	beq @loop
	lda VIA_BASE+VIA_T2CL	; clear timer 2 interrupt
	dey
	bpl @while		; loop until no ms left

	plx			; clean up stack
	plx
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
;   C - time measured in cpu cycles.
PUBLIC pbRCTime
	INITIAL_VALUE = 2	; stack offsets for local variables.
	PORT_MASK = 0
	pea $0000		; reserve space for the initial value.
	txy			; retain parameter in x
	jsr pbInput		; set pin to input and get port mask.
	pha			; initialize port mask stack local
	cpy #$0001		; test desired initial value
	bne @skip
	sta INITIAL_VALUE,s	; set initial value bit using port mask.
@skip:
	OFF16MEM		; start VIA timer
	stz VIA_BASE+VIA_ACR	; select one shot mode
	lda #$ff		; load timer with maximum value.
	sta VIA_BASE+VIA_T2CL	; set lower latch
	sta VIA_BASE+VIA_T2CH	; set upper latch
@while:
	lda PORT_MASK,s
	and VIA_BASE+VIA_PRB	; get the current value.
	eor INITIAL_VALUE,s	; test for edge transition.
	bne @edge_transition

	OFF16MEM		; has timer reached zero?
	lda #T2IF		; start mask
	bit VIA_BASE+VIA_IFR	; time out?
	ON16MEM
	beq @while
@edge_transition:
	lda #$ffff
	sbc VIA_BASE+VIA_T2CL	; get value and clear timer 2 interrupt
	plx			; clean up stack
	plx
	rts
ENDPUBLIC

; pbToggle - inverts the state of an output pin.
; Inputs:
;   A - index (0-15) of the I/O pin to set. Pin is set to output mode.
; Outputs:
;   None
PUBLIC pbToggle
	jsr pbOutput		; set pin to output and get port mask.
	eor VIA_BASE+VIA_PRB
	sta VIA_BASE+VIA_PRB
	rts
ENDPUBLIC
