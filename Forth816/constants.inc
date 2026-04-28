;==============================================================================
; constants.inc - Shared numeric constants for 65816 Forth kernel
;
; Included by both forth.s and primitives.s (and any other files that
; need these values). Numeric constants defined with = can't be exported
; via .global/.import in ca65 -- the solution is a shared include file.
;==============================================================================

.ifndef CONSTANTS_INC
CONSTANTS_INC = 1

; Stack addresses
PSP_INIT        = $03FF         ; Parameter stack initial pointer
PSP_EMPTY       = $0400         ; Parameter stack pointer underflow

; Scratch pad buffer
PAD_BASE        = $0400         ; PAD at $0400
PAD_SIZE        = $00FF         ; PAD area is one page.
PAD_END         = PAD_BASE + PAD_SIZE

; User area base and offsets
UP_BASE         = $0500
U_BASE          = $00           ; Numeric base          (cell)
U_STATE         = $02           ; Compile state         (cell, 0=interp)
U_DP            = $04           ; Dictionary pointer    (cell)
U_LATEST        = $06           ; Latest definition     (cell)
U_TIB           = $08           ; TIB address           (cell)
U_TOIN          = $0A           ; >IN parse offset      (cell)
U_SOURCELEN     = $0C           ; Source string length  (cell)
U_HANDLER       = $0E           ; Exception handler     (cell)
U_PAD           = $10           ; PAD address in user area
U_HLD           = $12           ; Address within PAD for formated I/O
U_CURDEF        = $14           ; CFA of word being compiled

; Terminal Input Buffer
TIB_BASE        = $0600
TIB_SIZE        = $0100

; RAM dictionary
DICT_BASE       = $0700         ; RAM dictionary

; ANS Forth boolean values
FORTH_TRUE      = $FFFF
FORTH_FALSE     = $0000

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

.endif ; CONSTANTS_INC
