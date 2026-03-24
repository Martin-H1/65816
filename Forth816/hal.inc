; -----------------------------------------------------------------------------
; Hardware absraction layer (HAL) definitions and macros.
; Defines the interfact any machine specific HAL is required to implement.
; The HAL handles power on, reset vectors, hardware initialization (e.g. ACIA,
; VIA, keyboard), and interrupts.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

; Conditionally import via functions in consuming modules.
.ifndef HAL_INC
HAL_INC = 1

.import hal_cgets	; blocks to read a CR terminated line from console

.import hal_cputs	; prints a null terminated string to the console.

.import hal_lpputs	; prints a length prefixed string to the console.

.import hal_cready	; returns true if characters are available.

.import hal_getch	; returns a character from the terminal input buffer.

.import hal_ungetch	; returns a character to the terminal input buffer.

.import hal_putch	; puts a character in A to console

.import hal_setecho	; enable/disable character echo during line editing.

.import hal_set_brk	; sets a callback for a BRK instruction handler.

.import hal_set_isr	; sets a callback for an interrupt handler.

.import hal_set_nmi	; sets a callback for a non-maskable interrupt handler.

.endif ; HAL_INC
