; -----------------------------------------------------------------------------
; Test of recursive macros and other odd ball ideas.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

.include "vmachine32.inc"

; Main entry point for the test
PUBLIC MAIN
	JSR	LOOP_EXAMPLE
	JSR	STACK_EXAMPLE
	JSR	CALC_PI
	HALT			; return to monitor.
ENDPUBLIC

; Count down from ten
PUBLIC LOOP_EXAMPLE
	PRINTCR
	PUSHI 10
@loop:	CPUTS	"Count = "
	DUP
	PRINTTOS
	PRINTCR
	DECTOS
	BNE @loop
	DROP
	RTS
ENDPUBLIC

; Count down from ten
PUBLIC STACK_EXAMPLE
	PRINTCR
	PUSHI	10
	PUSHI	20
	PUSHI	30
	CPUTS	"Stack contents = "
	PRINT_STACK
	PRINTCR
	ADDS			; ( 10 50 )
	ADDS			; ( 60 )
	CPUTS	"Sum of contents = "
	PRINTTOS
	PRINTCR
	CPUTS	"Stack contents = "
	PRINT_STACK
	PRINTCR
	RTS
ENDPUBLIC


N:	WORD 0

RESCALE = INT_MIN / 8		; ( 1 sign bit and 3 integer bits )
THREE = 3 * RESCALE
FOUR = 4 * RESCALE

; Pi calculation
; Described in C syntax n starts at 2 and iterates to the desired precision.
; pi = 3 + 4/((n)*(++n)*(++n)) - 4/((n)*(++n)*(++n)) + ...

PUBLIC	CALC_PI
	PUSHI	THREE
@while:	JSR	CALC_TERM
 	TOSZERO			; Nondestructively compare TOS with zero.
	BEQ	@done
	ADDS			; add term to the sum
	BRA	@while
@done:
	DROP			; drop unneeded zero
	CPUTS	"Pi = "
	PRINTTOS			; pop the results

	CPUTS	" / "
	PUSHI	RESCALE
	PRINTTOS
	PRINTCR

	CPUTS	"N = "
	PUSH	N
	PRINTTOS
	PRINTCR
	RTS
ENDPUBLIC

PUBLIC CALC_TERM
	JSR	QUOTIENT
	JSR	QUOTIENT
	SUBS
ENDPUBLIC

; quotient: calculates a single scaled quotient term
PUBLIC QUOTIENT
	PUSH	FOUR		; numerator of fixed point four
	JSR	DENOMINATOR	; calculate N*++N*++N
	WDIVS
	rts
ENDPUBLIC

; denominator: calculates (n)*(++n)*(++n)
; Inputs:
;   memory N
; Outputs:
;   N updated
;   Data stack contains product
PUBLIC DENOMINATOR
	PUSH N			; ( N )
	DUP			; ( N N )
	INCTOS			; ( N ++N )
	DUP			; ( N ++N ++N )
	INCTOS			; ( N ++N ++N )
	DUP			; ( N ++N ++N ++N )
	PUSHI N			; ( N ++N ++N ++N addr )
	WSTORE			; ( N ++N ++N )
	WMULS			; ( N ++N*++N+ )
	WMULS			; ( N*++N*++N )
	RTS
ENDPUBLIC
