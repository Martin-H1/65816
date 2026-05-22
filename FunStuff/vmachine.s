;==============================================================================
; vruntime.s - routines used by the Virtual Machine macros.
; Martin Heermance <mheermance@gmail.com>
;==============================================================================

__vmachine_s__ = 1
.include "vmachine.inc"

; Mench Monitor subroutine entry points.

Alter_Memory		= $E000	; Support Subroutine For 'M Command.
BACKSPACE	  	= $E003	; Outputs a <BACKSPACE> ($08) Character.
CONTROL_TONES	  	= $E009	; Configures tone generators: TG0 & TG1.
DO_LOW_POWER_PGM  	= $E00C	; Vector to force LOW POWER MODE on system.
DUMPREGS	  	= $E00F	; Support Subroutine For 'R' Command.
Dump528		    	= $E012	; Support Subroutine For 'R' Command
Dump_1_line_to_Output	= $E015	; Requests/Accepts Starting Address & dumps 8 b
Dump_1_line_to_Screen	= $E018	; Requests/Accepts Starting Address & dumps 8 b
Dump_to_Output		= $E01B	; Dumps specified range of memory data to port3
Dump_to_Printer		= $E01E	; Dumps specified range of memory data to port3
Dump_to_Screen		= $E021	; Dumps specified range of memory data to port3
Dump_to_Screen_ASCII	= $E024	; Dumps memory block in ASCII format.
Dump_It			= $E027	; Custom dump support.
FILL_Memory		= $E02A	; Support Subroutine For 'F' Command.
GET_3BYTE_ADDR		= $E02D	; Accepts 3-byte address as 6 ASCII Hex digits.
GET_ALARM_STATUS	= $E030	; Retrieves & resets current system alarm stats.
GET_BYTE_FROM_PC	= $E033	; Reads next available input from serial port 3.
GET_CHR			= $E036	; Accepts on character from serial port #3.
GET_HEX			= $E039	; Accepts two ASCII Hex digits via serial port3.
GET_PUT_CHR		= $E03C	; Accepts & echoes 1 character via serial port3.
GET_STR			= $E03F	; Uses GET_PUT_CHR to build string buffer.
Get_Address		= $E042	; Requests/Accepts 3-byte addr as ASCII Hex.
Get_E_Address		= $E045	; Requests/Accepts HIGHEST ADDRESS via serial 3
Get_S_Address		= $E048	; Requests/Accepts LOWEST ADDRESS via serial 3.
PUT_CHR			= $E04B	; Output one character to serial console port3.
PUT_STR			= $E04E	; Output specified string of characters to port3
READ_ALARM		= $E051	; Reads current system Alarm setting.
READ_DATE		= $E054	; Reads current system Date setting.
READ_TIME		= $E057	; Reads current system Time setting.
RESET_ALARM		= $E05A	; Resets the system Alarm function.
SBREAK			= $E05D	; Invokes the software breakpoint logic.
SELECT_COMMON_BAUD_RATE	= $E060	; Configures baud rate generator for serial 3.
SEND_BYTE_TO_PC		= $E063	; Outputs byte to serial port #3.
SEND_CR			= $E066	; Outputs ASCII ENTER ($0D) character.
SEND_SPACE		= $E069	; Outputs ASCII SPACE ($20) character.
SEND_HEX_OUT		= $E06C	; Outputs byte as two ASCII Hex characters.
SET_ALARM		= $E06F	; Set the System Alarm time from specified str.
SET_Breakpoint		= $E072	; Sets a breakpoint (BRK) instruction at addr.
SET_DATE		= $E075	; Sets the System Time-Of-Day Clock: Date
SET_TIME		= $E078	; Sets the System Time-Of-Day Clock: Time
VERSION			= $E07B	; Gets firmware (W65C265 ROM) version info.
WR_3_ADDRESS		= $E07E	; Outputs a 3-byte addr as ASCII Hex characters
XS28IN			= $E081	; Accepts & loads Motorola type "S28" records.
RESET			= $E084	; Invokes the Start-Up vector to Reset system.
ASCBIN			= $E087	; Converts two ASCII Hex chars to binary byte.
BIN2DEC			= $E08B	; Converts binary byte to packed BCD digits.
BINASC			= $E08F	; Converts binary to ASCII Hex characters.
HEXIN			= $E093	; Converts ASCII Hexadecimal chars to Binary.
IFASC			= $E097	; Checks for displayable ASCII character.
ISDECIMAL		= $E09B	; Checks character for ASCII Decimal Digit.
ISHEX			= $E09F	; Checks character for ASCII Hexadecimal Digit
UPPER_CASE		= $E0A3	; Converts lower-case ASCII chars to upper-case.

PSP_INIT		= $03FF

; Nibble masks (from monitor ROM listing)
LOWNIB  = $0F
HINIB   = $F0

; Control bits for REP and SEP
MEM16   = $20                   ; Accumulator width bit
IND16   = $10                   ; Index register width bit

CELL_SIZE = 2

;==============================================================================
; REGISTER WIDTH MACROS
; These match the W65C265 monitor ROM conventions exactly.
; NOTE: ON16MEM/OFF16MEM comments below describe the RESULT, not the operation:
;   ON16MEM  - REP #MEM16 - accumulator becomes 16-bit
;   OFF16MEM - SEP #MEM16 - accumulator becomes 8-bit
;==============================================================================

.macro ON16MEM
        REP     #MEM16          ; Accumulator = 16-bit
        .A16
.endmacro

.macro OFF16MEM
        SEP     #MEM16          ; Accumulator = 8-bit
        .A8
.endmacro

.macro ON16X
        REP     #IND16          ; Index registers = 16-bit
        .I16
.endmacro

.macro OFF16X
        SEP     #IND16          ; Index registers = 8-bit
        .I8
.endmacro

.macro ON16
        REP     #(MEM16 | IND16) ; All registers = 16-bit
        .A16
        .I16
.endmacro

.macro OFF16
        SEP     #(MEM16 | IND16) ; All registers = 8-bit
        .A8
        .I8
.endmacro

.segment "ZEROPAGE"
SCRATCH0:	.res 2		; General purpose scratch
SCRATCH1:	.res 2		; General purpose scratch
TMPA:		.res 2		; Temp for multiply/divide
TMPB:		.res 2		; Temp for multiply/divide

.segment "CODE"

.import MAIN

; INIT - External entry point and initialization.
; Initializes parameter stack and calls main.
PUBLIC INIT
	REP	#(MEM16|IND16)	; All registers = 16-bit
	CLEAR			; Initialize the parameter stack
	JMP	MAIN
ENDPUBLIC

PUBLIC vm_clear
	LDX	#PSP_INIT	; Parameter stack pointer
	RTS
ENDPUBLIC

;------------------------------------------------------------------------------
; ROLL ( xu xu-1 ... x0 u -- xu-1 ... x0 xu )
; Remove u. Rotate u+1 items on the top of the stack. An ambiguous condition
; exists if there are less than u+2 items on the stack before ROLL is executed.
PUBLIC	vm_roll
	POP	SCRATCH0	; save n
	CMP	#00		; n=0, nothing to do
	BEQ	@return

	ASL	SCRATCH0	; SCRATCH0 = n*2 (byte offset)

	; Fetch x_n
	TXA
	CLC
	ADC	SCRATCH0
	STA	SCRATCH1	; SCRATCH1 = addr of x_n
	LDA	(SCRATCH1)	; fetch x_n
	PHA			; save on return stack

	; Shift x_0..x_n-1 up by one cell
@shift_loop:
	LDA	SCRATCH1
	SEC
	SBC	#CELL_SIZE
	STA	SCRATCH1	; point to next lower item
	LDA	(SCRATCH1)	; fetch it
	LDY	#CELL_SIZE
	STA	(SCRATCH1),Y	; store one cell higher
	TXA
	CMP	SCRATCH1	; reached PSP (x_0 position)?
	BNE	@shift_loop

	PLA			; restore x_n
	STA	TOS,X		; store at TOS (x_0 position)
@return:
	RTS
ENDPUBLIC



; vm_stod - sign extend a word to a long.
PUBLIC	vm_stod
	DEX
	DEX
	LDA	NOS,X		; n
	BPL	@positive
	LDA	#MINUS_ONE	; negative -> high cell = -1
	STA	TOS,X
	RTS
@positive:
	STZ	TOS,X		; positive -> high cell = 0
	RTS
ENDPUBLIC

; vm_wmuls - multiplies TOS and NOS, and replaces T
PUBLIC vm_wmuls
	POP	TMPA		; b = multiplier
	LDA	TOS,X		; a = multiplicand
	STA	TMPB		; shifting multiplicand lives in TMPB
	STZ	SCRATCH0	; product accumulator = 0
.ifndef UNROLL
	PHY
	LDY	#16
@loop:
.else
.macro SHIFTADD16
.scope
.endif
	LSR	TMPA		; multiplier >>= 1; LSB -> carry
	BCC	@skip
	LDA	SCRATCH0
	CLC
	ADC	TMPB		; product += curr shifted multiplicand
	STA	SCRATCH0
@skip:
	ASL	TMPB		; shift multiplicand, not the sum
.ifndef UNROLL
	DEY
	BNE	@loop
.else
.endscope
.endmacro
	; Unroll the loop for performance.
	SHIFTADD16
	SHIFTADD16
	SHIFTADD16
	SHIFTADD16
	SHIFTADD16
	SHIFTADD16
	SHIFTADD16
	SHIFTADD16
	SHIFTADD16
	SHIFTADD16
	SHIFTADD16
	SHIFTADD16
	SHIFTADD16
	SHIFTADD16
	SHIFTADD16
	SHIFTADD16
.endif
	LDA	SCRATCH0
	STA	TOS,X
.ifndef UNROLL
	PLY
.endif
	RTS
ENDPUBLIC

; vm_umslashmod - subroutine: unsigned 32/16 -> 16r 16q
PUBLIC vm_umslashmod
	POP	TMPA		; TMPA = divisor
	; Now: TOS,X = ud_high (remainder register)
	;      NOS,X = ud_low  (quotient register)
.ifndef UNROLL
	PHY			; save IP
	LDY	#16		; 16 iterations
@loop:
.else
.macro SHIFTSUB32
.scope
.endif
	ASL	NOS,X		; quotient  <<= 1; old bit15 -> carry
	ROL	TOS,X		; remainder <<= 1; carry -> bit0
	LDA	TOS,X		; current remainder
	SEC
	SBC	TMPA		; remainder - divisor
	BCC	@restore	; borrow -> remainder < divisor, skip
	STA	TOS,X		  ; update remainder
	INC	NOS,X		; set quotient LSB
@restore:
.ifndef UNROLL
	DEY
	BNE	@loop
.else
.endscope
.endmacro
	; Unroll the loop for performance.
	SHIFTSUB32
	SHIFTSUB32
	SHIFTSUB32
	SHIFTSUB32
	SHIFTSUB32
	SHIFTSUB32
	SHIFTSUB32
	SHIFTSUB32
	SHIFTSUB32
	SHIFTSUB32
	SHIFTSUB32
	SHIFTSUB32
	SHIFTSUB32
	SHIFTSUB32
	SHIFTSUB32
	SHIFTSUB32
.endif
	; TOS,X = remainder, NOS,X = quotient
	; swap to ANS order TOS=quotient NOS=remainder
	LDA	TOS,X
	STA	SCRATCH0
	LDA	NOS,X
	STA	TOS,X
	LDA	SCRATCH0
	STA	NOS,X
.ifndef UNROLL
	PLY			; restore IP
.endif
	RTS
.endproc

PUBLIC vm_smrem
	SMREM_N	    = 1		; saved divisor (n)
	SMREM_DHIGH = 3		; saved d-high
	SMREM_SIGN  = 5		; saved sign indicator (d-high XOR n)

	; Save sign indicator, d-high, and n
	LDA	NOS,X		; d-high
	EOR	TOS,X		; XOR with n for sign indicator
	PHA			; SMREM_SIGN
	LDA	NOS,X		; d-high
	PHA			; SMREM_DHIGH
	LDA	TOS,X		; n
	PHA			; SMREM_N

	; Take absolute value of n
	LDA	TOS,X
	BPL	@n_pos
	EOR	#UINT_MAX
	INC	A
	STA	TOS,X
@n_pos:
	; Take absolute value of 32-bit dividend
	LDA	NOS,X		; d-high
	BPL	@d_pos
	LDA	4,X		; d-low
	EOR	#UINT_MAX	; invert
	CLC
	ADC	#1		; +1, carry set if result = 0
	STA	4,X
	LDA	NOS,X		; d-high
	EOR	#UINT_MAX	; invert
	ADC	#0		; add carry
	STA	NOS,X
@d_pos:
	JSR	vm_umslashmod	; ( rem quot )

	; Apply sign to quotient: sign(d-high XOR n)
	LDA	SMREM_SIGN,S
	BPL	@quot_pos
	LDA	TOS,X
	BEQ	@quot_pos
	EOR	#UINT_MAX
	INC	A
	STA	TOS,X
@quot_pos:
	; Apply sign to remainder: sign of original d-high
	LDA	SMREM_DHIGH,S
	BPL	@rem_pos
	LDA	NOS,X
	BEQ	@rem_pos
	EOR	#UINT_MAX
	INC	A
	STA	NOS,X
@rem_pos:
	PLA			; drop SMREM_N
	PLA			; drop SMREM_DHIGH
	PLA			; drop SMREM_SIGN
	RTS
ENDPUBLIC

; FM/MOD ( d1 n1 -- n2 n3 ) Divide d1 by n1, giving the floored quotient n3 and
; the remainder n2. Input and output stack arguments are signed.
PUBLIC  vm_fmmod
	LDA	NOS,X		; d-high
	EOR	TOS,X		; sign indicator
	PHA			; save sign indicator
	LDA	TOS,X		; n
	PHA			; save n
	JSR	vm_smrem	; ( rem quot )
	; Floor correction
	LDA	3,S		; sign indicator
	BPL	@done		; same signs -> no correction
	LDA	NOS,X		; remainder
	BEQ	@done		; zero -> no correction
	DEC	TOS,X		; quot -= 1
	LDA	NOS,X
	CLC
	ADC	1,S		; rem += n
	STA	NOS,X
@done:
	PLA			; drop n
	PLA			; drop sign indicator
	RTS
ENDPUBLIC

PUBLIC vm_slashmod
	SWAP
	STOD
	ROT
	JSR	vm_fmmod
	RTS
ENDPUBLIC

; vm_wdivs - ( n1 n2 -- quotient )
PUBLIC vm_wdivs
	JSR	vm_slashmod
	NIP
	RTS
ENDPUBLIC

; vm_cputs - prints a null terminated string to the console
; Inputs:
;   C - address of the string within the current bank
; Outputs:
;   C - preserved
PUBLIC vm_cputs	
	STRPTR = 1
	phy
	phx
	pha
	ldy #$0000
	OFF16MEM
@while:	lda (STRPTR,S),y
	beq @return
	jsr vm_putch
	iny
	bra @while
@return:
	ON16MEM
	pla
	plx
	ply
	rts
ENDPUBLIC

PUBLIC	vm_calc_depth
	TXA
	EOR	#UINT_MAX	; Two's complement
	INC
	CLC
	ADC	#PSP_INIT	; PSP_INIT - result / 2
	CMP	#INT_MIN	; if bit 15 is set, carry = 1
	ROR			; Divide by 2 (cells)
	RTS
ENDPUBLIC

; vm_print_num - prints a 16 bit signed number to the console.
; Inputs:
;   C - number to print
;   Y - numeric base
; Outputs:
;   C - clobbered
;   Y - clobbered
PUBLIC	vm_print_num
	CMP	#0
	BPL	vm_print_unum
	; Negative: negate value, then print minus sign
	EOR	#UINT_MAX
	INC	A
	PHA
	LDA	#'-'
	JSR	vm_putch
	PLA
ENDPUBLIC

; vm_print_unum - prints a 16 bit unsigned number to the console.
; Inputs:
;   C - number to print
;   Y - numeric base
; Outputs:
;   C - clobbered
;   Y - clobbered
PUBLIC vm_print_unum
	; Print SCRATCH0 as unsigned decimal via repeated division
	; Digits pushed onto hardware stack in reverse, then printed
	NUM_MSB = 4		; Offsets to locals
	NUM_LSB = 3
	BCD = 2
	BASE = 1

	PHD			; save direct page register
	PHA			; Establish working area
	PHY			; BASE (10 or 16)
	TSC			; Xfer RSP to direct page reg
	TCD			; stack local space is now direct page.

	OFF16MEM		; Switch to byte mode.

	LDA	#0		; null delimiter for print loop
	PHA
@while:				; divide TOS by base
	STZ	BCD		; clr BCD
	LDY	#16		; {>} = loop counter
@foreachbit:
	ASL	NUM_LSB		; TOS is gradually replaced
	ROL	NUM_MSB		; with the quotient
	ROL	BCD		; BCD result is gradually replaced
	LDA	BCD		; with the remainder
	SEC
	SBC	BASE		; partial BCD >= base ?
	BCC	@else
	STA	BCD		; yes: update the partial result
	INC	NUM_LSB		; set low bit in partial quotient
@else:
	DEY
	BNE	@foreachbit	; loop 16 times
	LDA	BCD
	CMP	#10
	BCC	@decdigit
	ADC	#6		; 'A'-10-1+carry
@decdigit:	ADC	#'0'		; convert BCD result to ASCII
	PHA			; stack digits in ascending
	LDA	NUM_LSB		; order ('0' for zero)
	ORA	NUM_MSB
	BNE	@while		; } until TOS is 0
@print:
	PLA
@loop:
	JSR	vm_putch       ; print digits in descending order
	PLA			; until null delimiter is encountered
	BNE	@loop
	ON16MEM			; exit byte mode
	PLY			; clean up working area
	PLA
	PLD
	RTS
ENDPUBLIC

; vm_print_stack - prints the stack elements
; Inputs:
;   X - parameter stack pointer.
; Outputs:
;   X - preserverd
;   C - clobbered
;   Y - clobbered
PUBLIC	vm_print_stack
	PHX			; Save PSP

	JSR	vm_calc_depth
	BEQ	@ds_done	; no items on stack, we're done.

	PHA			; print "<depth> "
	LDA	#'<'
	JSR	vm_putch
	PLA
	JSR	vm_print_num
	LDA	#'>'
	JSR	vm_putch
	LDA	#SPACE
	JSR	vm_putch
	LDX	#PSP_INIT

@print_loop:
	TXA			; Print stack items bottom to top.
	CMP	1,S
	BEQ	@ds_done
	ADVANCE
	LDA	TOS,X
	JSR	vm_print_num
	LDA	#SPACE
	JSR	vm_putch
	BRA	@print_loop
@ds_done:
	PLX			; Restore PSP
	RTS
ENDPUBLIC

; returns a character from the terminal input buffer.
; Note: Resets DP to zero to allow monitor to work.
PUBLIC vm_getch
	phd
	lda #$0000
	tcd

	OFF16MEM
@loop1:	jsl GET_BYTE_FROM_PC
	bcs @loop1
	ON16MEM
	and #$00ff

	pld
	rts
ENDPUBLIC

; vm_putahex - prints low eight bits of the accumulator in hex to the console.
; Inputs:
;   A - byte to print
; Outputs:
;   A - retained
PUBLIC vm_putahex
	pha
	pha
	lsr
	lsr
	lsr
	lsr
	jsr @print_nybble
	pla
	jsr @print_nybble
	pla
	rts

@print_nybble:
	and #LOWNIB
	sed
	clc
	adc #$9990	        	; Produce $90-$99 or $00-$05
	adc #$9940			; Produce $30-$39 or $41-$46
	cld
	jmp vm_putch
ENDPUBLIC

; vm_putchex - prints C as a 16 bit hex number to the console.
; Inputs:
;   C - number
; Outputs:
;   C - preserved
PUBLIC vm_putchex
	pha
	pha
	xba
	jsr vm_putahex
	pla
	jsr vm_putahex
	pla
	rts
ENDPUBLIC

; puts a character in A to console.
; Note: Resets DP to zero to allow monitor to work.
PUBLIC vm_putch
@loop:	jsl SEND_BYTE_TO_PC	; retry until buffer is ready
	bcs @loop
	rts
ENDPUBLIC
