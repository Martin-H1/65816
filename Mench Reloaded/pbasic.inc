; -----------------------------------------------------------------------------
; PBasic definitions, macros, and function prototypes.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

HIGH = 1
LOW = 0

; Conditionally import functions in consuming modules.
.ifndef __pbasic_asm__
.import pbCount
.import pbFreqOut
.import pbHigh
.import pbInput
.import pbLow
.import pbOutput
.import pbPause
.import pbPulsin
.import pbPulsout
.import pbToggle
.import pbRCTime
.import pbToggle
.endif
