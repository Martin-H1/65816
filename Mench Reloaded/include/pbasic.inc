; -----------------------------------------------------------------------------
; PBasic definitions, macros, and function prototypes.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

; Machine dependent constants that are useful for real time control.
FCLK = 3686400			; fast clock in cycles per second
ONE_MS = FCLK / 1000		; cycles per ms
ONE_US = FCLK / 1000000		; cycles per us

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
.import pbPWMmask
.import pbRCTime
.import pbToggle
.endif
