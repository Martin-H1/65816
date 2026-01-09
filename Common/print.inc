; -----------------------------------------------------------------------------
; Print related functions that are platform independant, unlike console I/O
; which is platform dependant.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

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
	lda #L_FEED
	jsr putch
.endmacro
