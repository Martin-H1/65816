;------------------------------------------------------------------------------
; Platform specific initialization
;------------------------------------------------------------------------------

; Conditionally import virtual machine functions in consuming modules.
.ifndef __vmachine_s__
.import vm_clear
.import vm_cputs
.import vm_getch
.import vm_print_num
.import vm_print_unum
.import vm_print_stack
.import vm_putahex
.import vm_putchex
.import vm_putch
.import vm_stod
.import vm_wmuls
.import vm_wdivs
.endif

; Common constants

; Integer constants (based on C's limits.h)
INT_MIN         = $8000
INT_MAX         = $7FFF
MINUS_ONE       = $FFFF
UINT_MAX        = $FFFF

; Parameter stack offsets
TOS		= 0
NOS		= 2

; Ascii / UTF-8 codes for commonly used unprintable control characters.
NULL            = $00           ; null termination character
SOH             = $01           ; start of header
S_TEXT          = $02           ; start of text
ETX             = $03           ; end of text
EOT             = $04           ; end of transmission
ENQ             = $05           ; enquire
ACK             = $06           ; acknowledgement
BELL            = $07           ; It goes ding when there's stuff!
BKSP            = $08           ; backspace
HTAB            = $09           ; horizontal tab
L_FEED          = $0A           ; line feed
VTAB            = $0B           ; veritcal tab
F_FEED          = $0C           ; form feed
C_RETURN        = $0D           ; carriage return
SO              = $0E           ; shift out
SI              = $0F           ; shift in

DC1             = $11           ; device control 1
DC2             = $12           ; device control 2
DC3             = $13           ; device control 3
DC4             = $14           ; device control 4
NAK             = $15           ; negative acknowledgement
SYN             = $16           ; sync character
ETB             = $17           ; end of transmission block

CAN             = $18           ; cancel
EM              = $19           ; end of messsage
SUB             = $1A           ; substitute
ESC             = $1B           ; escape
FS              = $1C           ; field separator
GS              = $1D           ; group separator
RS              = $1E           ; record separator
US              = $1F           ; unit separator
SPACE           = $20           ; space
DEL             = $7F           ; Delete

XON             = DC1           ; puunch (send) ON
XOFF            = DC3           ; punch (send) OFF


;------------------------------------------------------------------------------
; PUBLIC / ENDPUBLIC - Export a subroutine as a global symbol
;
; Usage:
;   PUBLIC my_function
;       ... code ...
;   ENDPUBLIC
;------------------------------------------------------------------------------
.macro  PUBLIC function_name
        .export function_name
        .proc   function_name
	.A16
	.I16
.endmacro

.macro  ENDPUBLIC
        .endproc
.endmacro


;==============================================================================
; Stack operations
;==============================================================================

;------------------------------------------------------------------------------
; ADVANCE - Increments the parameter stack pointer.
;------------------------------------------------------------------------------
.macro  ADVANCE
        DEX
        DEX
.endmacro

;------------------------------------------------------------------------------
; CLEAR - Reset the stack to its empty state.
;------------------------------------------------------------------------------
.macro  CLEAR
        JSR	vm_clear
.endmacro

;------------------------------------------------------------------------------
; DROP - Drops the top of stack (TOS)
;------------------------------------------------------------------------------
.macro	DROP
	INX
	INX
.endmacro

;------------------------------------------------------------------------------
; DUP - Duplicates the top of stack (TOS)
;------------------------------------------------------------------------------
.macro	DUP
	LDA	TOS,X
	DEX
	DEX
	STA	TOS,X
.endmacro

;------------------------------------------------------------------------------
; QDUP - Conditionally Ddplicates the TOS ( x -- 0 | x x )
;------------------------------------------------------------------------------
.macro	QDUP
	LDA	TOS,X
	.local @skip
	BEQ	@skip
	DEX
	DEX
	STA	TOS,X
@skip:
.endmacro

;------------------------------------------------------------------------------
; NIP - Replace NOS with TOS and drop a cell
;------------------------------------------------------------------------------
.macro  NIP
	LDA	TOS,X
	DROP
	STA	TOS,X
.endmacro

;------------------------------------------------------------------------------
; PEEK - Copies the value at TOS to the address arg.
;------------------------------------------------------------------------------
.macro  PEEK addr
	LDA	TOS,X
	STA	addr
.endmacro

;------------------------------------------------------------------------------
; PUSH - Push value at address arg onto parameter stack
;------------------------------------------------------------------------------
.macro  PUSH addr
	LDA	addr
	DEX
	DEX
	STA	TOS,X
.endmacro

;------------------------------------------------------------------------------
; PUSHI - Push immediate onto the stack
;------------------------------------------------------------------------------
.macro	PUSHI arg
	LDA	#arg
	DEX
	DEX
	STA	TOS,X
.endmacro

;------------------------------------------------------------------------------
; POP - Pop top of parameter stack to address
;------------------------------------------------------------------------------
.macro  POP addr
	LDA	TOS,X
	STA	addr
	INX
	INX
.endmacro

;------------------------------------------------------------------------------
; ROT - ( a b c -- b c a )
;------------------------------------------------------------------------------
.macro	ROT
	LDA	4,X		; a (bottom)
	PHA
	LDA	NOS,X		; b
	STA	4,X		; bottom slot = b
	LDA	TOS,X		; c (TOS)
	STA	NOS,X		; middle slot = c
	PLA
	STA	TOS,X		; TOS = a
.endmacro

;------------------------------------------------------------------------------
; MROT - ( a b c -- c a b )
;------------------------------------------------------------------------------
.macro	MROT
	LDA	4,X		; a (bottom)
	PHA
	LDA	TOS,X		; b
	STA	4,X		; bottom slot = b
	LDA	NOS,X		; c (TOS)
	STA	TOS,X		; middle slot = c
	PLA
	STA	NOS,X		; TOS = a
.endmacro

;------------------------------------------------------------------------------
; SWAP - exchanges top two stack elements ( a b - b a )
;------------------------------------------------------------------------------
.macro  SWAP
        LDA	TOS,X
        PHA
        LDA	NOS,X
	STA	TOS,X
	PLA
	STA	NOS,X
.endmacro

;------------------------------------------------------------------------------
; TUCK - ( a b - b a b )
;------------------------------------------------------------------------------
.macro  TUCK
	DUP				; TOS = b
	LDA	4,X			; a
	STA	NOS,X			; NOS = a
	LDA	TOS,X			; b
	STA	4,X			; Slot below a = b
.endmacro


;==============================================================================
; Double cell stack operations
;==============================================================================

;------------------------------------------------------------------------------
; TWODROP - Drops the top two stack elements (TOS NOS)
;------------------------------------------------------------------------------
.macro	TWODROP
	INX
	INX
	INX
	INX
.endmacro

;------------------------------------------------------------------------------
; TWODUP - ( a b -- a b a b )
;------------------------------------------------------------------------------
.macro	TWODUP
	LDA	NOS,X			; a
	DEX
	DEX
	STA	TOS,X			; ( a b a )
	LDA	NOS,X			; b
	DEX
	DEX
	STA	TOS,X			; ( a b a b )
.endmacro

;------------------------------------------------------------------------------
; TWOSWAP - ( a b c d -- c d a b )
;------------------------------------------------------------------------------
.macro	TWOSWAP
	LDA	TOS,X			; d
	PHA
	LDA	NOS,X			; c
	PHA
	LDA	4,X			; b
	STA	TOS,X
	LDA	6,X			; a
	STA	NOS,X
	PLA				; c
	STA	6,X
	PLA				; d
	STA     4,X
.endmacro

;------------------------------------------------------------------------------
; TWOOVER ( a b c d -- a b c d a b )
;------------------------------------------------------------------------------
.macro	TWOOVER
	LDA	6,X			; a
	ADVANCE
	STA	TOS,X			; Push a
	LDA	6,X			; b
	ADVANCE
	STA	TOS,X			; Push b
.endmacro

;==============================================================================
; Return stack operations
;==============================================================================

;------------------------------------------------------------------------------
; TOR - ( a - ) R: ( - a )
;------------------------------------------------------------------------------
.macro  TOR
	LDA	TOS,X			; a
	PHA
	DROP
.endmacro

;------------------------------------------------------------------------------
; FROMR - ( - a ) R: ( a - )
;------------------------------------------------------------------------------
.macro  FROMR
	PLA				; a
	DEX
	DEX
	STA	TOS,X			; a
.endmacro


;==============================================================================
; Memory operations
;==============================================================================

;------------------------------------------------------------------------------
; BFETCH - Replace TOS with the byte value at that address
;------------------------------------------------------------------------------
.macro  BFETCH
	JSR	vm_bfetch	; fetch 8-bit value
.endmacro

;------------------------------------------------------------------------------
; BSTORE - stores NOS byte value at TOS address and drops both cells.
;------------------------------------------------------------------------------
.macro  BSTORE
	JSR	vm_bstore	; fetch 8-bit value
.endmacro

;------------------------------------------------------------------------------
; WFETCH - Replace TOS with value at that address
;------------------------------------------------------------------------------
.macro  WFETCH
	LDY	TOS,X		; addr
	LDA	0,Y		; fetch 16-bit value
	STA	TOS,X
.endmacro

;------------------------------------------------------------------------------
; WSTORE - stores NOS value at TOS address and drops both cells.
;------------------------------------------------------------------------------
.macro  WSTORE
	LDY	TOS,X
	LDA	NOS,X
	STA	0,Y
	DROP
	DROP
.endmacro

;------------------------------------------------------------------------------
; WORD - allocates a word of storage and initializes it with arg
;------------------------------------------------------------------------------
.macro WORD arg
       .word arg
.endmacro

;==============================================================================
; Comparison operations
;==============================================================================

;------------------------------------------------------------------------------
; TOSZERO - Nondestructively compares TOS with zero.
;------------------------------------------------------------------------------
.macro  TOSZERO
	LDA	TOS,X
	CMP	#0
.endmacro

;==============================================================================
; Logical operations
;==============================================================================

;------------------------------------------------------------------------------
; ANDS - ANDs the NOS and TOS cells on the data stack
;------------------------------------------------------------------------------
.macro  ANDS
        LDA	TOS,X
	DROP
        AND	TOS,X
	STA	TOS,X
.endmacro

;------------------------------------------------------------------------------
; ORS - ORs the NOS and TOS cells on the data stack
;------------------------------------------------------------------------------
.macro  ORS
        LDA	TOS,X
	DROP
        ORA	TOS,X
	STA	TOS,X
.endmacro

;------------------------------------------------------------------------------
; NOTS - Inverts bits of TOS
;------------------------------------------------------------------------------
.macro	NOTS
	LDA	TOS,X
	EOR	#$FFFF
	STA	TOS,X
.endmacro

;------------------------------------------------------------------------------
; XORS - XORs the NOS and TOS on the data stack
;------------------------------------------------------------------------------
.macro  XORS
        LDA	TOS,X
	DROP
        EOR	TOS,X
	STA	TOS,X
.endmacro


;==============================================================================
; Arithmetic
;==============================================================================

;------------------------------------------------------------------------------
; ADDS - Adds the first two cells on the data stack
;------------------------------------------------------------------------------
.macro  ADDS
        LDA	TOS,X
	DROP
	CLC
	ADC	TOS,X
	STA	TOS,X
.endmacro

;------------------------------------------------------------------------------
; DECTOS - Decrements TOS
;------------------------------------------------------------------------------
.macro	DECTOS
	DEC	TOS,X
.endmacro

;------------------------------------------------------------------------------
; INCTOS - Increments TOS
;------------------------------------------------------------------------------
.macro	INCTOS
	INC	TOS,X
.endmacro

;------------------------------------------------------------------------------
; NEGATES - Perform two's compliment of TOS
;------------------------------------------------------------------------------
.macro	NEGATES
	NOTS
	INCTOS
.endmacro

;------------------------------------------------------------------------------
; SUBS - Subtracts the first two cells on the data stack
;------------------------------------------------------------------------------
.macro	SUBS
	LDA	NOS,X
	SEC
	SBC	TOS,X
	DROP
	DROP
.endmacro

;------------------------------------------------------------------------------
; STOD - sign extend a single to double
;------------------------------------------------------------------------------
.macro	STOD
	JSR	vm_stod
.endmacro

;------------------------------------------------------------------------------
; WMULS - multiply two words on stack and push result
;------------------------------------------------------------------------------
.macro	WMULS
	JSR	vm_wmuls
.endmacro

;------------------------------------------------------------------------------
; WDIVS - divide two words on stack
;------------------------------------------------------------------------------
.macro	WDIVS
	JSR	vm_wdivs
.endmacro


;==============================================================================
; Bit shifts
;==============================================================================

;------------------------------------------------------------------------------
; ASLS - Arithmetic left shift TOS
;------------------------------------------------------------------------------
.macro	ASLS
	ASL	TOS,X
.endmacro

;------------------------------------------------------------------------------
; LSRS - Logical right shift TOS
;------------------------------------------------------------------------------
.macro	LSRS
	LSR	TOS,X
.endmacro

;------------------------------------------------------------------------------
; ROLS - Rotagte left the TOS
;------------------------------------------------------------------------------
.macro	ROLS
	ROL	TOS,X
.endmacro

;------------------------------------------------------------------------------
; RORS - Rotate right the TOS
;------------------------------------------------------------------------------
.macro	RORS
	ROR	TOS,X
.endmacro

;==============================================================================
; Flow control
;==============================================================================

;------------------------------------------------------------------------------
; HALT - Return to monitor
;------------------------------------------------------------------------------
.macro  HALT
	RTL
.endmacro


;==============================================================================
; I/O functions
;==============================================================================

;------------------------------------------------------------------------------
; PRINTTOS - pops TOS and prints to console.
;------------------------------------------------------------------------------
.macro	PRINTTOS
	LDA	TOS,X
	DROP
	LDY	#10		; print in decimal
	JSR	vm_print_num
.endmacro

;------------------------------------------------------------------------------
; PRINTCR - prints a CR to the console.
;------------------------------------------------------------------------------
.macro	PRINTCR
	LDA	#C_RETURN
	JSR	vm_putch
	LDA	#L_FEED
	JSR	vm_putch
.endmacro

;------------------------------------------------------------------------------
; PRINT_STACK - prints parameter stack contents to the console.
;------------------------------------------------------------------------------
.macro	PRINT_STACK
	LDY	#10
	JSR	vm_print_stack
.endmacro

;------------------------------------------------------------------------------
; CPUTS - prints text to console.
;------------------------------------------------------------------------------
.macro	CPUTS arg
	.local @text
	.local @skip
	LDA	#@text
	JSR	vm_cputs
	BRA	@skip
@text:	.asciiz arg
@skip:
.endmacro
