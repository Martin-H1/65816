; -----------------------------------------------------------------------------
; PBasic definitions, macros, and function prototypes.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

; Machine dependent constants that are useful for real time control.
CLK_FREQ = 3686400		; cycles per second
ONE_MS = CLK_FREQ / 1000	; cycles per ms
ONE_US = CLK_FREQ / 1000000	; cycles per us

; Booleans used for pin state.
HIGH = 1
LOW = 0

; Conditionally import functions in consuming modules.
.ifndef __pbasic_asm__
.import pbCount
.import pbFreqOut
.import pbHigh
.import pbInput
.import pbINX
.import pbLow
.import pbOutput
.import pbPause
.import pbPulsin
.import pbPulsout
.import pbPWM
.import pbRCTime
.import pbToggle
.endif
