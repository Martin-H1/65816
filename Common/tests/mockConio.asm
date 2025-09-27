; -----------------------------------------------------------------------------
; Definitions for the py65mon emulator
; -----------------------------------------------------------------------------
.alias py65_putc    $f001
.alias py65_getc    $f004

;
; Data segments
;
.segment "BSS"
GETCHPTR:	.res 2

.segment "CODE"

mockConioInit:
.scope
	`pop GETCHPTR		; save the mock data pointer.
	`pushi getch_impl	; Initialize the console vectors.
	`pushi putch_impl
	jmp conIoInit
.scend

getch_impl:
.scope
	`push GETCHPTR
	`peek DBGPTR
	`inctos
	`pop GETCHPTR
	lda (DBGPTR)
	rts
.scend

putch_impl:
.scope
	sta py65_putc
	rts
.scend
