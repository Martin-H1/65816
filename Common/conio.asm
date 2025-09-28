; -----------------------------------------------------------------------------
; conio provides an MS DOS stylee interface to character stream devices.
; The functions use indirection to allow retargeting to diffent devices
; as well as null or simulated devices.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

.include "ascii.inc"
.include "common.inc"

;
; Numeric constants
;
tibSize = tibEnd - tib

;
; Data segments
;
.segment "BSS"
tib:		.res $50	; a line buffer for buffered reads.
tibEnd:		.res $00	; end marker to compute buffer size.
writeIdx:	.res $02	; current write position in the buffer.
readIdx:	.res $03	; current read position in the buffer.
STDOUT:		.res $02	; pointer to console output routine.
STDIN:		.res $02	; pointer to console input routine.
echo:		.res $02	; control echo during line edit mode.

.segment "CODE"

;
; Macros
;
.macro incIdx
.scope
	iny
	cpy #tibSize
	bne skip
	ldy #$0000
skip:
.endscope
.endmacro

.macro decIdx
.scope
	dey
	bpl skip
	ldy #tibSize - 1
skip:
.endscope
.endmacro

;
; Functions
;

; Routine to initialize console pointers and state.
; input - two pointers on the stack
; output - none
PUBLIC conioInit
	lda ARG1,s
	sta STDOUT
	lda ARG2,s
	sta STDIN
	stz echo
	stz readIdx
	stz writeIdx
	rts
ENDPUBLIC

; Enable or disable character echo during line editing mode.
; input - boolean in accumulator
; output - none
PUBLIC conioSetEcho
	sta echo
	rts
ENDPUBLIC

; cgets is similar to the MSDOS console I/O function that reads an entire
; line from stdin. A line is terminated by a CR, and backspace deletes
; the previous character in the buffer.
; input - implicit from init function.
; output - implicit in that the line buffer is filled.
PUBLIC cgets
	OFF16MEM
	phy
	ldy writeIdx
while:
	jsr getch
	sta tib,y
	lda echo
	beq noecho
	lda tib,y
	jsr putch
noecho:	lda tib,y
	cmp #BKSP
	bne keepchar
	decIdx
	bra while
keepchar:
	incIdx
	cmp #C_RETURN
	beq end
	cmp #NULL
	bne while
end:
	sty writeIdx
	ply
	ON16MEM
	rts

getch:
	jmp (STDIN)
ENDPUBLIC

; cputs is like the MSDOS console I/O function. It prints a null terminated
; string to the console using putch.
PUBLIC cputs
	OFF16MEM
	phy
	ldy #$0000
loop:	lda (ARG1, s),y		; get the string via address from zero page
	beq exit		; if it is a zero, we quit and leave
	jsr putch		; if not, write one character
	iny			; get the next byte
	bra loop
exit:	ply
	ON16MEM
	rts
ENDPUBLIC

; gets a character from the terminal input buffer, or gets more
; characters if it is empty.
PUBLIC getch
	OFF16MEM
	phy
	ldy readIdx
	cpy writeIdx
	bne noget
	jsr cgets		; buffer empty, get more characters.
noget:	lda tib,y
	incIdx
	sty readIdx		; store next read index.
	ply
	ON16MEM
	and #$00FF		; clear high byte .
	rts
ENDPUBLIC

; puts a character in the accumulator back into the terminal input buffer.
PUBLIC ungetch
	OFF16MEM
	phy
	ldy readIdx
	decIdx
	sta tib,y
	sty readIdx
	ply
	ON16MEM
	rts
ENDPUBLIC

; puts a character in accumulator to stdout by doing an indirect jump to
; that handler. The handler will RTS to our caller.
PUBLIC putch
        jmp (STDOUT)
ENDPUBLIC
