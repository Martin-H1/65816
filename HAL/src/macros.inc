;==============================================================================
; macros.inc - ca65 Macros for 65816 Forth Kernel
;==============================================================================
.ifndef MACROS_INC
MACROS_INC = 1
;==============================================================================
; W65C265 ROM MONITOR CONSTANTS
; From the WDC W65C265 monitor ROM listing.
;==============================================================================
; Nibble masks (from monitor ROM listing)
LOWNIB  = $0F
HINIB   = $F0
; Control bits for REP and SEP
MEM16   = $20                   ; Accumulator width bit
IND16   = $10                   ; Index register width bit
;==============================================================================
; REGISTER WIDTH MACROS
; These match the W65C265 monitor ROM conventions exactly.
; NOTE: ON16MEM/OFF16MEM comments below describe the RESULT, not the operation:
;   ON16MEM  -> REP #MEM16 -> accumulator becomes 16-bit
;   OFF16MEM -> SEP #MEM16 -> accumulator becomes 8-bit
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
.endmacro
.macro  ENDPUBLIC
        .endproc
.endmacro
.endif ; MACROS_INC
