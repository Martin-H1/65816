;==============================================================================
; hal_test.s - Hardware Abstraction Layer (HAL) for the Mench Reloaded SBC.
; Does not contain vectors as it is used with Mench monitor.
; Martin Heermance <mheermance@gmail.com>
;==============================================================================

__hal_s__ = 1


.include "constants.inc"
.include "dictionary.inc"
.include "macros.inc"

;------------------------------------------------------------------------------
; ZERO PAGE - Direct Page variables
; ca65 will use direct page addressing for these automatically
;------------------------------------------------------------------------------
        .segment "ZEROPAGE"

W:              .res 2          ; Working register (current CFA)
UP:             .res 2          ; User Pointer (base of user area)
SCRATCH0:       .res 2          ; General purpose scratch
SCRATCH1:       .res 2          ; General purpose scratch
TMPA:           .res 2          ; Temp for multiply/divide
TMPB:           .res 2          ; Temp for multiply/divide
HAL_RXBUF:      .res 1          ; HAL receive lookahead buffer (1 byte)
HAL_RXREADY:    .res 1          ; HAL receive buffer flag (0=empty, 1=full)

; Export zero page symbols with .globalzp so other translation units
; use direct page addressing when referencing them
        .globalzp       W
        .globalzp       UP
        .globalzp       SCRATCH0
        .globalzp       SCRATCH1
        .globalzp       TMPA
        .globalzp       TMPB
        .globalzp       HAL_RXBUF
        .globalzp       HAL_RXREADY

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
	ldy #CFA_LIST

	jsr MAIN
	rtl
.endproc

; CFA used to handle the NEXT at the end of code were testing.
CFA_LIST:
	.word RTS_CFA
HEADER "RTS", RTS_CFA, 0, 0
CODEPTR RTS_CODE
PUBLIC  RTS_CODE
	ldy #CFA_LIST
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
        OFF16MEM
        JSL     GET_BYTE_FROM_PC
        ON16MEM
        BCS     @none           ; Carry set = nothing available
        ; A byte arrived - stash it in the lookahead buffer
        SEP     #MEM16
        .A8
        STA     HAL_RXBUF       ; Save byte
        LDA     #1
        STA     HAL_RXREADY     ; Mark buffer full
        REP     #MEM16
        .A16
        LDA     #$FFFF          ; Return TRUE
        RTS
@none:
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

; returns true if data in in buffer
PUBLIC hal_cready
	lda #$ffff
	rts
ENDPUBLIC

; returns a character from the terminal input buffer.
PUBLIC hal_getch
	OFF16MEM
@loop1:	jsl GET_BYTE_FROM_PC
	bcs @loop1
	ON16MEM
	and #$00ff
	rts
ENDPUBLIC

; returns a character in A into the terminal input buffer.
PUBLIC hal_ungetch
	rts
ENDPUBLIC

; puts a character in A to console.
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
