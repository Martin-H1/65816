; -----------------------------------------------------------------------------
; Test for conio functions under 65816 simulator
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

.include "../common.inc"
.include "../conio.inc"

RamSize = $7EFF			; def $8000 for 32 kb x 8 bit RAM

; Main entry point for the interpreter test
.export main
main:
	jsr putch_test
	jsr getch_test
	jsr cputs_test
	jsr cgets_test
	jsr echo_test
	jsr ungetch_test
	brk

putch_test:
	println @name
	jsr conioInit
	lda #'B'
	jsr putch
	printcr
	rts
@name:	.asciiz "*** putch test ***"

getch_test:
	println _name
	pea _data
	jsr conioInit
	jsr getch
	jsr putch
	jsr getch
	jsr putch
	jsr getch
	jsr putch
	printcr
	rts
@data:	.byte "A string",0
@name:	.byte "*** getch test ***",0

cputs_test:
	println _name
	pea _data
	jsr cputs
	printcr
	rts
@data:	.byte "printing some text.",0
@name:	.byte "*** cputs test ***",0

cgets_test:
	println _name
	pea _data
	jsr conioInit
_loop:	jsr getch
	cmp #$00
	beq _end
	jsr putch
	bra _loop
_end:	printcr
	rts
@data:	.byte "This is the first line to buffer.",AscCR,AscLF
	.byte "Now another line to fill the buffer.",AscCR,AscLF
	.byte "This is the final line.",0
@name:	.byte "*** cgets test ***",0

echo_test:
	println _name
	pea _data
	jsr conioInit
	lda #$ff
	jsr conioSetEcho
	jsr cgets
	printcr
	rts
@data:	.byte "This is the first line to buffer.",AscCR,AscLF,0
@name:	.byte "*** echo test ***",0

ungetch_test:
	println _name
	pea _data
	jsr conioInit
	lda #'B'
	jsr ungetch
	lda #'A'
	jsr ungetch
	jsr getch
	jsr putch
	jsr getch
	jsr putch
	jsr getch
	jsr putch
	jsr getch
	jsr putch
	printcr
	rts
_data:	.byte "some data.",0
_name:	.byte "*** ungetch test ***",0
