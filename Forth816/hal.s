;==============================================================================
; hal.s - Hardware Abstraction Layer for 65816 Forth Kernel
;
; All I/O goes through these routines. To port to a different UART or
; SBC, only this file needs to change.
;
; Uses the W65C265 ROM monitor entry points via JSL (long call).
;==============================================================================

        .p816
        .smart off

        .include "macros.inc"
        .include "constants.inc"

        .importzp       HAL_RXBUF
        .importzp       HAL_RXREADY

        .segment "CODE"

;------------------------------------------------------------------------------
; hal_putch - Send character in A to serial port 3
;
; Entry: A = character to send (8-bit, must be in 8-bit accumulator mode)
; Exit:  X, Y preserved
;        Retries until the monitor accepts the byte (carry clear = success)
;------------------------------------------------------------------------------
        PUBLIC  hal_putch
@loop:
        OFF16MEM                ; ROM monitor expects 8-bit A
        JSL     SEND_BYTE_TO_PC ; Long call to monitor ROM
        ON16MEM
        BCS     @loop           ; Carry set = buffer not ready, retry
        RTS
        ENDPUBLIC

;------------------------------------------------------------------------------
; hal_getch - Receive character from serial port 3 (blocking)
;
; Entry: nothing
; Exit:  A = character received (zero-extended to 16-bit)
;        X, Y preserved
;        Blocks until a character is available
;------------------------------------------------------------------------------
        PUBLIC  hal_getch
        ; Check lookahead buffer first (may have been filled by hal_kbhit)
        SEP     #MEM16
        .A8
        LDA     HAL_RXREADY
        BEQ     @fetch          ; Buffer empty, go get a byte
        STZ     HAL_RXREADY     ; Clear buffer flag
        LDA     HAL_RXBUF       ; Return buffered byte
        REP     #MEM16
        .A16
        AND     #$00FF
        RTS
@fetch:
        REP     #MEM16
        .A16
@loop:
        OFF16MEM
        JSL     GET_BYTE_FROM_PC
        ON16MEM
        BCS     @loop           ; Carry set = no byte yet, retry
        AND     #$00FF          ; Zero-extend to 16-bit
        RTS
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

;------------------------------------------------------------------------------
; hal_cputs - Print a null-terminated string to the console
;
; Entry: A (full 16-bit, aka C) = address of string in current bank
; Exit:  A preserved (all registers and flags preserved)
;
; Uses hardware stack frame: TSC/TCD sets direct page to current stack,
; so STRPTR (= 1,S) gives named access to the saved A (string address).
;------------------------------------------------------------------------------
        PUBLIC  hal_cputs
STRPTR  = 1
                PHP             ; Save flags
                PHD             ; Save direct page
                PHY             ; Save Y
                PHX             ; Save X
                PHA             ; Push string address (becomes STRPTR on stack)
                TSC             ; Stack pointer → A
                TCD             ; Set direct page to current stack frame
                LDY     #$0000
                OFF16MEM
@while:
                LDA     (STRPTR),Y      ; Fetch byte from string
                BEQ     @return         ; Null terminator = done
                JSR     hal_putch
                INY
                BRA     @while
@return:
                ON16MEM
                PLA             ; Restore string address (discard)
                PLX             ; Restore X
                PLY             ; Restore Y
                PLD             ; Restore direct page
                PLP             ; Restore flags
                RTS
        ENDPUBLIC
