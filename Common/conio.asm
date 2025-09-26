; -----------------------------------------------------------------------------
; conio provides an MS DOS stylee interface to character stream devices.
; The functions use indirection to allow retargeting to diffent devices
; as well as null or simulated devices.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

.include "common.inc"

; establish module level scope to hide module locals.
.scope

;
; Module assumes native mode with 16 bit registers.
;
.A16
.I16

;
; Numeric constants
;
_tibSize = _tibEnd - _tib

;
; Data segments
;
.segment "BSS"
_tib:		.res $50	; a line buffer for buffered reads.
_tibEnd:	.res $00	; end marker to compute buffer size.
_writeIdx:	.res $02	; current write position in the buffer.
_readIdx:	.res $03	; current read position in the buffer.
_STDOUT:	.res $02	; pointer to console output routine.
_STDIN:		.res $02	; pointer to console input routine.
_echo:		.res $02	; control echo during line edit mode.

.segment "CODE"

;
; Macros
;
.macro _incIdx
.scope
	iny
	cpy #_tibSize
	bne _skip
	ldy #$0000
_skip:
.endscope
.endmacro

.macro _decIdx
.scope
	dey
	bpl _skip
	ldy #_tibSize - 1
_skip:
.endscope
.endmacro

;
; Functions
;

; Routine to initialize console pointers and state.
; input - two pointers on the stack
; output - none
.export conioInit
conioInit:
.scope
	lda ARG1,s
	sta _STDOUT
	lda ARG2,s
	sta _STDIN
	stz _echo
	stz _readIdx
	stz _writeIdx
	rts
.endscope

; Enable or disable character echo during line editing mode.
; input - boolean in accumulator
; output - none
.export conioSetEcho
conioSetEcho:
.scope
	sta _echo
	rts
.endscope

; cgets is similar to the MSDOS console I/O function that reads an entire
; line from _stdin. A line is terminated by a CR, and backspace deletes
; the previous character in the buffer.
; input - implicit from init function.
; output - implicit in that the line buffer is filled.
.export cgets
cgets:
.scope
	ACC8
	phy
	ldy _writeIdx
_while:
	jsr _getch
	sta _tib,y
	lda _echo
	beq noecho
	lda _tib,y
	jsr putch
noecho:	lda _tib,y
	cmp #AscBS
	bne keepchar
	_decIdx
	bra _while
keepchar:
	_incIdx
	cmp #AscCR
	beq _end
	cmp #AscNull
	bne _while
_end:
	sty _writeIdx
	ply
	ACC16
	rts

_getch:
	jmp (_STDIN)
.endscope

; cputs is like the MSDOS console I/O function. It prints a null terminated
; string to the console using putch.
.export cputs
cputs:
.scope
	ACC8
	phy
	ldy #$0000
_loop:	lda (ARG1, s),y		; get the string via address from zero page
	beq _exit		; if it is a zero, we quit and leave
	jsr putch		; if not, write one character
	iny			; get the next byte
	bra _loop
_exit:	ply
	ACC16
	rts
.endscope

; gets a character from the terminal input buffer, or gets more
; characters if it is empty.
.export getch
getch:
.scope
	ACC8
	phy
	ldy _readIdx
	cpy _writeIdx
	bne noget
	jsr cgets		; buffer empty, get more characters.
noget:	lda _tib,y
	_incIdx
	sty _readIdx		; store next read index.
	ply
	ACC16
	and #$00FF		; clear high byte .
	rts
.endscope

; puts a character in the accumulator back into the terminal input buffer.
.export ungetch
ungetch:
.scope
	ACC8
	phy
	ldy _readIdx
	_decIdx
	sta _tib,y
	sty _readIdx
	ply
	ACC16
	rts
.endscope

; puts a character in accumulator to stdout by doing an indirect jump to
; that handler. The handler will RTS to our caller.
.export putch
putch:
.scope
        jmp (_STDOUT)
.endscope

.endscope
