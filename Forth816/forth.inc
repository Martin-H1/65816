;==============================================================================
; forth.inc - common constants and entry exports
;==============================================================================

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

.globalzp W			; Working register (current CFA)
.globalzp UP			; User Pointer (base of user area)
.globalzp SCRATCH0		; General purpose scratch
.globalzp SCRATCH1		; General purpose scratch
.globalzp TMPA			; Temp for multiply/divide
.globalzp TMPB			; Temp for multiply/divide

.ifndef __forth_s__
.import DOCOL
.import FORTH_INIT
.endif
