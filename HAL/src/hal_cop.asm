; =============================================================================
; hal_cop.asm -- COP instruction dispatcher
;
; COP #n provides a bank-transparent 2-byte HAL call. The operand byte n
; selects the HAL function, matching the jump table function numbers.
;
; On entry (native mode COP frame):
;   1,S  PCL  ]  return PC -- points to byte AFTER the COP operand
;   2,S  PCH  ]
;   3,S  PBR     caller's program bank register
;   4,S  P       saved processor status
;
; The COP operand byte is at [PCH:PCL - 1] in bank PBR.
;
; Register save/restore:
;   ON16 before PHA/PHX/PHY saves full 16-bit register state.
;   Registers are restored before dispatch so handlers receive the
;   caller's register state (same as a JSL through the jump table).
;   A, X, Y are caller-saved per HAL convention.
;
; Dispatch:
;   cop_table holds 16-bit addresses (handlers are all in bank $00).
;   offset = n * 2. Handler is called via JSL to a JMP [ptr] trampoline
;   since handlers end with RTL (need 3-byte return address on stack).
;   JSL returns to hal_isr_cop after handler RTLs, then RTI to caller.
; =============================================================================

        .p816
        .smart  off

        .include "macros.inc"
        .include "hal_sfr.inc"

        .globalzp hal_tmp_ptr

        .global hal_baud_set_timer
        .global hal_uart_set_timer
        .global hal_uart_init
        .global hal_uart_putc
        .global hal_uart_getc
        .global hal_uart_puts
        .global hal_uart_status
        .global hal_uart_rx_ready
        .global hal_via_init
        .global hal_via_set_dir
        .global hal_via_write
        .global hal_via_read
        .global hal_set_brk
        .global hal_set_isr
        .global hal_set_nmi
        .global hal_version

        .segment "HAL_CODE"

; =============================================================================
; hal_isr_cop -- COP dispatcher
; =============================================================================

PUBLIC  hal_isr_cop

        ; Save caller's full 16-bit register state
        ON16                    ; all registers 16-bit before saving
        PHA                     ; 2 bytes
        PHX                     ; 2 bytes
        PHY                     ; 2 bytes

        ; Stack layout (1,S = top, all 2-byte saves):
        ;   1,S   Y  (2 bytes)
        ;   3,S   X  (2 bytes)
        ;   5,S   A  (2 bytes)
        ;   7,S   PCL:PCH  COP return address
        ;   9,S   PBR
        ;  10,S   P

        ; Read stacked PC, back up one byte to point at COP operand
        LDA     7,S             ; PCL:PCH (16-bit)
        DEC     A               ; address of COP operand
        TAX                     ; X = operand address

        ; Switch DBR to caller's bank to read operand
        OFF16MEM                ; 8-bit A for bank byte ops
        LDA     9,S             ; stacked PBR
        PHA
        PLB                     ; DBR = caller's bank

        ; Read COP operand byte n
        LDA     $0000,X         ; n = function number

        ; Restore DBR to $00
        PEA     $0000
        PLB
        PLB

        ; Compute cop_table offset = n * 2 (16-bit table)
        AND     #$FF            ; clean 8-bit value
        ON16MEM                 ; 16-bit A
        AND     #$00FF          ; zero-extend
        ASL     A               ; n * 2
        TAX                     ; X = table offset

        ; Load handler address from cop_table into hal_tmp_ptr
        LDA     cop_table,X     ; 16-bit address of handler
        STA     hal_tmp_ptr
        ; Bank is always $00 — all handlers are in EEPROM bank 0
        OFF16MEM
        .a8
        LDA     #$00
        STA     hal_tmp_ptr+2

        ; Restore caller's registers before dispatch
        ON16
        PLY
        PLX
        PLA

        ; Call handler via JSL to trampoline
        ; JSL pushes 3-byte return address; handler RTLs back to trampoline
        ; trampoline RTS returns here; RTI returns to interrupted caller
        JSL     cop_call
        RTI

cop_call:
        JMP     [hal_tmp_ptr]   ; indirect jump; bank $00 from hal_tmp_ptr+2
                                ; handler RTL returns to cop_call+3 (RTS)

ENDPUBLIC

; =============================================================================
; cop_table -- 16-bit handler addresses (all in bank $00)
; Order must match HAL_FN_* constants in hal_jumptable.asm
; =============================================================================

cop_table:
        .word   hal_baud_set_timer  ; 0  HAL_FN_BAUD_SET_TIMER
        .word   hal_uart_set_timer  ; 1  HAL_FN_UART_SET_TIMER
        .word   hal_uart_init       ; 2  HAL_FN_UART_INIT
        .word   hal_uart_putc       ; 3  HAL_FN_UART_PUTC
        .word   hal_uart_getc       ; 4  HAL_FN_UART_GETC
        .word   hal_uart_puts       ; 5  HAL_FN_UART_PUTS
        .word   hal_uart_status     ; 6  HAL_FN_UART_STATUS
        .word   hal_uart_rx_ready   ; 7  HAL_FN_UART_RX_READY
        .word   hal_via_init        ; 8  HAL_FN_VIA_INIT
        .word   hal_via_set_dir     ; 9  HAL_FN_VIA_SET_DIR
        .word   hal_via_write       ; 10 HAL_FN_VIA_WRITE
        .word   hal_via_read        ; 11 HAL_FN_VIA_READ
        .word   hal_set_brk         ; 12 HAL_FN_SET_BRK
        .word   hal_set_isr         ; 13 HAL_FN_SET_ISR
        .word   hal_set_nmi         ; 14 HAL_FN_SET_NMI
        .word   hal_version         ; 15 HAL_FN_VERSION
