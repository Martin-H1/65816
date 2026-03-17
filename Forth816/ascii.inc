; -----------------------------------------------------------------------------
; Ascii / UTF-8 codes for commonly used unprintable control characters.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

NULL	= $00	; null termination character
SOH	= $01	; start of header
S_TEXT	= $02	; start of text
ETX	= $03	; end of text
EOT	= $04	; end of transmission
ENQ	= $05	; enquire
ACK	= $06	; acknowledgement
BELL	= $07	; It goes ding when there's stuff!
BKSP	= $08	; backspace
HTAB	= $09	; horizontal tab
L_FEED	= $0A	; line feed
VTAB	= $0B	; veritcal tab
F_FEED	= $0C	; form feed
C_RETURN  = $0D	; carriage return
SO	= $0E	; shift out
SI	= $0F	; shift in

DC1	= $11	; device control 1
DC2	= $12	; device control 2
DC3	= $13	; device control 3
DC4	= $14	; device control 4
NAK	= $15	; negative acknowledgement
SYN	= $16	; sync character
ETB	= $17	; end of transmission block

CAN	= $18	; cancel
EM	= $19	; end of messsage
SUB	= $1A	; substitute
ESC	= $1B	; escape
FS	= $1C	; field separator
GS	= $1D	; group separator
RS	= $1E	; record separator
US	= $1F	; unit separator
SPACE	= $20	; space

XON	= DC1	; puunch (send) ON
XOFF	= DC3	; punch (send) OFF
