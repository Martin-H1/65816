; -----------------------------------------------------------------------------
; Print related functions that are platform independant, unlike console I/O
; which is platform dependant.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

;
; Aliases
;

;
; Data segments
;

;
; Macros
;

; Syntactic sugar around print to package the argument.
.macro print
	pea _1
        jsr cputs
.endmacro

; Prints the string an adds a line feed.
.macro println
	print _1
	printcr
.endmacro

; Prints a line feed.
.macro printcr
        lda #AscLF
        jsr putch
.endmacro

;
; Functions
;
