; -----------------------------------------------------------------------------
; Common aliases and macros useful in any file.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

;
; Put assembler in 16 bit mode, as 8 bit mode is the exception
; selected at module level.
;
.A16
.I16

;
; Aliases
;

; stack offsets
ARG1	= $02
ARG2	= $04

; masking building symbols
LOWNIB	= $0F
HINIB	= $F0

Bit0	= $01
Bit1	= $02
Bit2	= $04
Bit3	= $08
Bit4	= $10
Bit5	= $20
Bit6	= $40
Bit7	= $80

; control bits for REP and SEP
MEM16	= $20
IND16	= $10

;
; Macros
;

; These are from the WDC 65c265 monitor ROM listing. Reusing them allows
; using code from the monitor with minimal changes.

.macro ON16MEM
       .A16		; tell the assembler about mode
       rep #MEM16	; set 8-bit accumulator mode
.endmacro

.macro OFF16MEM
       .A8
       sep #MEM16
.endmacro

.macro ON16X
       .I16
       rep #IND16
.endmacro

.macro OFF16X
       .I8
       sep #IND16
.endmacro

.macro ON16
       .A16
       .I16
       rep #(MEM16 | IND16)
.endmacro

.macro OFF16
       .A8
       .I8
       sep #(MEM16 | IND16)
.endmacro

.macro PUBLIC function_name
.export function_name
.proc function_name
.endmacro

.macro ENDPUBLIC
.endproc
.endmacro