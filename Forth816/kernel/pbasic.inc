; -----------------------------------------------------------------------------
; PBasic definitions, macros, and function prototypes.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

; Machine dependent constants that are useful for real time control.
FCLK = 3686400			; fast clock in cycles per second
ONE_MS = FCLK / 1000		; cycles per ms
ONE_US = FCLK / 1000000		; cycles per us

; Conditionally import functions in consuming modules.
.ifndef __pbasic_asm__
        .global PBINIT_CFA
        .global PBCOUNT_CFA
        .global PBFREQOUT_CFA
        .global PBHIGH_CFA
        .global PBINPUT_CFA
        .global PBINX_CFA
        .global PBLOW_CFA
        .global PBOUTPUT_CFA
        .global PBPAUSE_CFA
        .global PBPULSIN_CFA
        .global PBPULSOUT_CFA
        .global PBPWM_CFA
        .global PBPWMMASK_CFA
        .global PBRCTIME_CFA
        .global PBTOGGLE_CFA
.endif
