;==============================================================================
; forth.s - 65816 ANS Forth Kernel (ITC)
;
; Architecture:
;   Threading:  Indirect Threaded Code (ITC)
;   Cell size:  16-bit
;   ROM:        Kernel primitives ($8000-$FFBF)
;   RAM:        Dictionary, stacks, user area
;
; Register conventions:
;   C  (16-bit) Working register / scratch
;   X  (16-bit) Parameter Stack Pointer (PSP) - points to TOS
;   Y  (16-bit) Instruction Pointer (IP)      - points to next CFA
;   S  (16-bit) Return Stack Pointer (RSP)    - hardware stack
;   D           Direct Page base ($0000)
;   DB          Data Bank ($00)
;
; ITC execution model:
;   Each word's Code Field contains the ADDRESS of a pointer.
;   That pointer holds the address of the actual machine code.
;
;   Dictionary entry layout:
;   +--------+-------+--------+-----+--------+-----------+
;   | LINK   | FLAGS | NAME.. | $00 | CFA    | body...   |
;   | 2 bytes| 1 byte| n bytes|     | 2 bytes| ...       |
;   +--------+-------+--------+-----+--------+-----------+
;                                    ^-- Code Field (CFA)
;                                        contains address of
;                                        code pointer
;==============================================================================

__forth_s__ = 1

.p816				; Enable 65816 instruction set
.smart off			; Manual size tracking (safer for Forth)

.include "macros.inc"
.include "dictionary.inc"

;------------------------------------------------------------------------------
; ZERO PAGE - Direct Page variables
; ca65 will use direct page addressing for these automatically
;------------------------------------------------------------------------------
.segment "ZEROPAGE"

IP:		.res 2		; Instruction Pointer
W:		.res 2		; Working register (current CFA)
UP:		.res 2		; User Pointer (base of user area)
SCRATCH0:	.res 2		; General purpose scratch
SCRATCH1:	.res 2		; General purpose scratch
TMPA:		.res 2		; Temp for multiply/divide
TMPB:		.res 2		; Temp for multiply/divide

;------------------------------------------------------------------------------
; CONSTANTS
;------------------------------------------------------------------------------

; Stack addresses
PSP_INIT	= $03FF		; Parameter stack initial pointer
RSP_INIT	= $01FF		; Return stack initial pointer (hardware)

; User area base and offsets
UP_BASE		= $0400
U_BASE		= $00		; Numeric base		(cell)
U_STATE		= $02		; Compile state		(cell, 0=interp)
U_DP		= $04		; Dictionary pointer	(cell)
U_LATEST	= $06		; Latest definition	(cell)
U_TIB		= $08		; TIB address		(cell)
U_TOIN		= $0A		; >IN parse offset	(cell)
U_SOURCELEN	= $0C		; Source string length	(cell)
U_HANDLER	= $0E		; Exception handler	(cell)

; Terminal Input Buffer
TIB_BASE	= $0500
TIB_SIZE	= $0100

; RAM dictionary
DICT_BASE	= $0600

; UART registers - adjust for your hardware
UART_STATUS	= $7F00
UART_DATA	= $7F01
UART_TXRDY	= $02		; TX ready bit mask
UART_RXRDY	= $01		; RX ready bit mask

; ANS Forth boolean values
FORTH_TRUE	= $FFFF
FORTH_FALSE	= $0000

; Dictionary header flag bits
F_IMMEDIATE	= $80		; Immediate word flag
F_HIDDEN	= $40		; Hidden word flag (during compilation)
F_LENMASK	= $1F		; Name length mask

;==============================================================================
; CODE SEGMENT - ROM kernel
;==============================================================================
.segment "CODE"

;------------------------------------------------------------------------------
; INNER INTERPRETER
;
; NEXT - advance IP and jump through the code field pointer.
;
; This is inlined as a macro for speed. It performs:
;   1. Fetch cell at IP (Y) into W         W = *IP  (this is the CFA)
;   2. Advance IP by 2                     IP += 2
;   3. Fetch code pointer from W           temp = *W
;   4. Jump to that address
;
; Because Y is our IP and ca65/65816 doesn't have (Y) addressing,
; we use a small trampoline via SCRATCH0.
;------------------------------------------------------------------------------

; NEXT is defined as a macro in macros.inc and inlined into each primitive.

;------------------------------------------------------------------------------
; DOCOL - Code pointer for all colon (:) definitions
;
; On entry: W = CFA of the word being entered
; Action:   Push current IP (Y) onto return stack,
;           set IP to first cell of body (W+2),
;           then NEXT.
;------------------------------------------------------------------------------
.proc DOCOL
	.a16
	.i16
	tya			; Current IP → A
	pha			; Push IP onto return stack
	lda W			; W = CFA of this word
	clc
	adc #2			; Body starts at CFA+2
	tay			; IP = body start
	NEXT			; Execute first body word
.endproc

;------------------------------------------------------------------------------
; DOVAR - Code pointer for VARIABLE definitions
;
; Pushes the address of the variable body (CFA+2) onto parameter stack.
;------------------------------------------------------------------------------
.proc DOVAR
	.a16
	.i16
	lda W			; CFA
	clc
	adc #2			; Address of body
	dex
	dex
	sta 0,X			; Push onto parameter stack
	NEXT
.endproc

;------------------------------------------------------------------------------
; DOCON - Code pointer for CONstaNT definitions
;
; Pushes the value stored in the body (CFA+2) onto parameter stack.
;------------------------------------------------------------------------------
.proc DOCON
	.a16
	.i16
	lda W			; CFA
	clc
	adc #2
	sta SCRATCH0
	lda (SCRATCH0)		; Fetch constant value
	dex
	dex
	sta 0,X			; Push value
	NEXT
.endproc

;------------------------------------------------------------------------------
; DODOES - Code pointer for DOES> defined words
;
; Pushes body address, then transfers control to the DOES> code.
; The DOES> code address is stored in the CFA+2 of the defining word.
;------------------------------------------------------------------------------
.proc DODOES
	.a16
	.i16
	; Push body address of THIS word (W+2)
	lda W
	clc
	adc #2
	dex
	dex
	sta 0,X			; Push body address

	; W points to CFA which contains address of DODOES.
	; The DOES> code address is stored after DOCOL saved IP.
	; IP (Y) was set by the caller to point to DOES> code.
	NEXT
.endproc

;==============================================================================
; SYSTEM INITIALIZATION
;==============================================================================
.proc FORTH_INIT
	; --- Switch to 65816 native mode ---
	clc
	xce			; Clear emulation bit → native mode

	; --- 16-bit registers ---
	rep #$30
	.a16
	.i16

	; --- Set Direct Page to $0000 ---
	lda #$0000
	tcd

	; --- Set Data Bank to $00 ---
	pea $0000
	plb			; pop extra zero off stack
	plb			; DB = $00

	; --- Initialize stacks ---
	ldx #PSP_INIT		; Parameter stack pointer
	lda #RSP_INIT
	tas			; Hardware (return) stack pointer

	; --- Initialize User Pointer ---
	lda #UP_BASE
	sta UP

	; --- User area: BASE = 10 ---
	lda #10
	sta UP_BASE + U_BASE

	; --- User area: STATE = 0 (interpret) ---
	stz UP_BASE + U_STATE

	; --- User area: DP = DICT_BASE ---
	lda #DICT_BASE
	sta UP_BASE + U_DP

	; --- User area: LATEST = last ROM word ---
	lda #LAST_WORD		; Defined at end of dictionary.
	sta UP_BASE + U_LATEST

	; --- User area: TIB = TIB_BASE ---
	lda #TIB_BASE
	sta UP_BASE + U_TIB

	; --- User area: >IN = 0 ---
	stz UP_BASE + U_TOIN

	; --- User area: SOURCE-LEN = 0 ---
	stz UP_BASE + U_SOURCELEN

	; --- Jump to QUIT (outer interpreter) ---
	; Load CFA of QUIT and execute it
	lda #QUIT_CFA		; CFA of QUIT word
	sta W
	lda (W)			; Fetch code pointer
	sta SCRATCH0
	jmp (SCRATCH0)
.endproc

;==============================================================================
; HARDWARE VECTORS
;==============================================================================
.segment "VECTORS"

; Emulation mode vectors ($FFE0-$FFEF are unused/reserved)

.word $0000			; $FFE0 - unused
.word $0000			; $FFE2 - unused
.word $0000			; $FFE4 - COP (emulation)
.word $0000			; $FFE6 - unused
.word $0000			; $FFE8 - ABORT (emulation)
.word $0000			; $FFEA - unused
.word $0000			; $FFEC - NMI (emulation)
.word FORTH_INIT		; $FFEE - RESET (emulation) → init

; Native mode vectors ($FFF0-$FFFF)
.word $0000			; $FFF0 - COP (native)
.word $0000			; $FFF2 - BRK (native)
.word $0000			; $FFF4 - ABORT (native)
.word $0000			; $FFF6 - unused
.word $0000			; $FFF8 - NMI (native)
.word FORTH_INIT		; $FFFA - unused
.word FORTH_INIT		; $FFFC - RESET (native)
.word $0000			; $FFFE - IRQ/BRK (native)
