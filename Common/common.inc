; -----------------------------------------------------------------------------
; Common aliases and macros useful in any file.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

;
; Aliases
;

; stack offsets
ARG1	= $02
ARG2	= $04

; Common character codes (ASCII / UTF-8)
AscNull = $00	; null termination character
AscBell	= $07	; bell (Control-G) ASCII character
AscBS	= $08	; backspace ASCII character
AscCC	= $03	; break (Control-C) ASCII character
AscCR	= $0D	; carriage return ASCII character
AscDEL	= $7F	; DEL ASCII character
AscESC	= $1B	; Escape ASCII character
AscFF	= $0C	; Formfeed ASCII character
AscLF	= $0A	; line feed ASCII character
AscSP	= $20	; space ASCII character
AscTAB	= $09	; tab ASCII character
AscVT	= $0B	; vertical tab ASCII character

;
; Macros
;
.macro ACC8
	sep #$20		; set 8-bit accumulator mode
	.A8			; tell the assembler about it
.endmacro

.macro ACC16
	rep #$20		; set 16-bit accumulator mode
	.A16			; tell the assembler about it
.endmacro

; Syntactic sugar around print to package the argument.
.macro print str
	pea str
	jsr cputs
.endmacro

; Prints the string an adds a line feed.
.macro println str
	print str
	printcr
.endmacro

; Prints a line feed.
.macro printcr
	lda #AscLF
	jsr putch
.endmacro
