;==============================================================================
; hal_test.s - Hardware Abstraction Layer (HAL) for the Mench Reloaded SBC.
; Does not contain vectors as it is used with Mench monitor.
; Martin Heermance <mheermance@gmail.com>
;==============================================================================

__hal_s__ = 1


.include "constants.inc"
.include "dictionary.inc"
.include "macros.inc"

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

;------------------------------------------------------------------------------
; ZERO PAGE - Direct Page variables
; ca65 will use direct page addressing for these automatically
;------------------------------------------------------------------------------
        .segment "ZEROPAGE"

W:              .res 2          ; Working register (current CFA)
UP:             .res 2          ; User Pointer (base of user area)
RSP_INIT:       .res 2          ; RSP init value from ROM monitor or $01FF
SCRATCH0:       .res 2          ; General purpose scratch
SCRATCH1:       .res 2          ; General purpose scratch
TMPA:           .res 2          ; Temp for multiply/divide
TMPB:           .res 2          ; Temp for multiply/divide

; Export zero page symbols with .globalzp so other translation units
; use direct page addressing when referencing them
        .globalzp       W
        .globalzp       UP
        .globalzp       RSP_INIT
        .globalzp       SCRATCH0
        .globalzp       SCRATCH1
        .globalzp       TMPA
        .globalzp       TMPB

;==============================================================================
; CODE SEGMENT - Entry from ROM monitor
;==============================================================================
.segment "CODE"
.import MAIN			; unit test entry point
.proc MONITOR_ENTRY
	ON16MEM
	ON16X
	lda #$0D
	jsr hal_putch
	ldx #PSP_INIT
	TSC				; S initialized by HAL ROM Vector.
	STA RSP_INIT			; Save S to reinitialize stack pointer

	; Perform Forth interpreter initialization
	LDA #UP_BASE			; Initialize User Pointer
	STA UP

	LDY #U_BASE			; --- User area: BASE = 10 ---
	LDA #10
	STA (UP),Y

	LDY #U_STATE  			; --- User area: STATE = 0 (interpret) ---
	LDA #0
	STA (UP),Y

	LDY #U_DP			; --- User area: DP = DICT_BASE ---
	LDA #DICT_BASE
	STA (UP),Y

	LDY #U_LATEST			; --- User area: LATEST = last ROM word ---
	LDA #LAST_WORD			; Defined at end of dictionary.s
	STA (UP),Y

	LDY #U_TIB			; --- User area: TIB = TIB_BASE ---
	LDA #TIB_BASE
	STA (UP),Y

	LDY #U_TOIN			; --- User area: >IN = 0 and SOURCE-LEN = 0 ---
	LDA #0
	STA (UP),Y			; >IN = 0

        LDY #U_SOURCELEN		; SOURCE-LEN = $20
	LDA #$20
	STA (UP),Y

	ldy #RTS_CFA_LIST

	jsr MAIN
	rtl
.endproc

; CFA used to handle the NEXT at the end of code were testing.
RTS_CFA_LIST:
	.word RTS_CFA
HEADER "RTS", RTS_ENTRY, RTS_CFA, 0, 0
CODEPTR RTS_CODE
PUBLIC  RTS_CODE
	ldy #RTS_CFA_LIST
	rts
ENDPUBLIC

PUBLIC  DOCOL
        .a16
        .i16
        rts
ENDPUBLIC

; reads a CR terminated line from console into buffer
PUBLIC hal_cgets
	rts
ENDPUBLIC

;------------------------------------------------------------------------------
; hal_kbhit - Check if a character is available (non-blocking)
;
; Entry: nothing
; Exit:  A = $FFFF if character available, $0000 if not
;        X, Y preserved
;
; If a byte is available it is stored in HAL_RXBUF / HAL_RXREADY
; so that hal_getch can return it without losing it.
;------------------------------------------------------------------------------
        PUBLIC  hal_kbhit
        LDA     #$0000          ; Return FALSE
        RTS
        ENDPUBLIC

; hal_cputs - prints a null terminated string to the console
; Inputs:
;   C - address of the string within the current bank
; Outputs:
;   C - preserved
PUBLIC hal_cputs	
	STRPTR = 1
	php
	phd
	phy
	phx
	pha
	tsc
	tcd
	ldy #$0000
	OFF16MEM
@while:	lda (STRPTR),y
	beq @return
	jsr hal_putch
	iny
	bra @while
@return:
	ON16MEM
	pla
	plx
	ply
	pld
	plp
	rts
ENDPUBLIC

; hal_lpputs - prints a length-prefixed string to the console
; Inputs:
;   C - address of the string within the current bank
; Outputs:
;   C - preserved
PUBLIC hal_lpputs
	STRPTR = 1
	phy
	phx
	pha
	ldy #$0000
	lda (STRPTR,S),Y	; Load the length byte
	and #$00ff
	tax
	beq @return		; Nothing to print if zero
@loop:	iny
	lda (STRPTR,S),Y
	jsr hal_putch
	dex
	bne @loop
@return:
	pla			; Clean off stack and return
	plx
	ply
	rts
ENDPUBLIC

; returns true if data in in buffer
PUBLIC hal_cready
	lda #$ffff
	rts
ENDPUBLIC

; returns a character from the terminal input buffer.
; Note: Resets DP to zero to allow monitor to work.
PUBLIC hal_getch
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

; returns a character in A into the terminal input buffer.
PUBLIC hal_ungetch
	rts
ENDPUBLIC

; puts a character in A to console.
; Note: Resets DP to zero to allow monitor to work.
PUBLIC hal_putch
@loop:	jsl SEND_BYTE_TO_PC	; retry until buffer is ready
	bcs @loop
	rts
ENDPUBLIC

; enable/disable character echo during line editing.
PUBLIC hal_setecho
	rts
ENDPUBLIC

; sets a callback for a BRK instruction handler.
PUBLIC hal_set_brk	
	rts
ENDPUBLIC

; sets a callback for an interrupt handler.
PUBLIC hal_set_isr
	rts
ENDPUBLIC

; sets a callback for a non-maskable interrupt handler.
PUBLIC hal_set_nmi
	rts
ENDPUBLIC
