; =============================================================================
; hal_cop.asm -- COP instruction dispatcher
;
; COP #n provides a bank-transparent 2-byte HAL call. The operand byte n
; selects the HAL function, matching the jump table function numbers defined
; in hal_jumptable.asm.
;
; On entry (native mode COP frame, S growing downward):
;   1,S  PCL  ]  return PC -- points to byte AFTER the COP operand
;   2,S  PCH  ]
;   3,S  PBR     caller's program bank register
;   4,S  P       saved processor status
;
; The COP operand byte is at [PCH:PCL - 1] in bank PBR.
;
; Dispatch:
;   cop_table is a table of 3-byte far addresses, one per function.
;   Entry n corresponds to HAL function n (same numbering as jump table).
;
; The handler is called via a local JSR to a JML [ptr] trampoline:
;   - JSR cop_trampoline     pushes a 16-bit return address
;   - JML [hal_tmp_ptr]      does the 24-bit indirect jump
;   - handler ends with RTL  returns to cop_trampoline+1 = RTS in cop_call
;   - RTS                    returns to hal_isr_cop after the JSR
;   - RTI                    returns to the interrupted caller
;
; Caller registers A, X, Y are restored before the handler is called,
; so the handler receives the same register state as a JSL call would.
; A, X, Y are caller-saved per HAL convention.
; =============================================================================

        .p816
        .smart  off

        .include "macros.inc"
        .include "hal_sfr.inc"

        ; ZP temp for handler address (defined in hal_zp.asm)
        .globalzp hal_tmp_ptr

        ; Handler targets (defined in their respective modules)
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

        ; Save caller's registers
        ; All pushes are 8-bit (M=1, X=1 on COP entry after status save)
        ; but we don't know caller's M/X state. Push in current state.
        ; Convention: caller-saved, so we just need to restore them.
        PHA
        PHX
        PHY

        ; Stack layout after saves (1,S = top):
        ;   1,S   Y   (1 byte)
        ;   2,S   X   (1 byte)
        ;   3,S   A   (1 or 2 bytes depending on caller M flag)
        ;
        ; To keep stack math simple we enforce 8-bit saves.
        ; The OFF16 below ensures A and X are 8-bit for the PHA/PHX/PHY
        ; above -- but we already pushed before switching. 
        ;
        ; Safest: do OFF16 FIRST, then save registers.
        ; Restructure entry:

        PLY                     ; undo saves
        PLX
        PLA

        OFF16                   ; 8-bit A and X before saving
        PHA                     ; now all saves are 1 byte each
        PHX
        PHY

        ; Stack layout (all 1-byte saves):
        ;   1,S   Y
        ;   2,S   X
        ;   3,S   A
        ;   4,S   PCL  ]  COP return address
        ;   5,S   PCH  ]
        ;   6,S   PBR     caller's bank
        ;   7,S   P       saved processor status

        ; Read stacked PC as 16-bit value, back up to COP operand
        ON16MEM
        .a16
        LDA     4,S             ; PCL:PCH
        DEC     A               ; address of COP operand byte
        TAX                     ; X = operand address (16-bit)

        ; Switch DBR to caller's bank to read the operand
        OFF16MEM
        .a8
        LDA     6,S             ; stacked PBR
        PHA
        PLB                     ; DBR = caller's bank

        LDA     $0000,X         ; read COP operand byte n

        ; Restore DBR to $00
        PEA     $0000
        PLB
        PLB                     ; two PLBs from PEA word -> DBR = $00

        ; Compute cop_table offset = n * 3
        ; n is in A (8-bit), zero-extend and multiply
        ON16MEM
        .a16
        AND     #$00FF          ; zero-extend operand to 16-bit
        PHA                     ; save n
        ASL     A               ; n*2
        CLC
        ADC     1,S             ; n*2 + n = n*3
        TAX                     ; X = byte offset into cop_table

        ; Fetch 24-bit handler address into hal_tmp_ptr (ZP)
        OFF16MEM
        .a8
        LDA     cop_table,X     ; low byte
        STA     hal_tmp_ptr
        LDA     cop_table+1,X   ; high byte
        STA     hal_tmp_ptr+1
        LDA     cop_table+2,X   ; bank byte
        STA     hal_tmp_ptr+2

        ; Discard saved n
        ON16MEM
        .a16
        PLA
        OFF16MEM
        .a8

        ; Restore caller's registers before dispatching
        PLY
        PLX
        PLA

        ; Call handler via trampoline
        ; JSR pushes 16-bit return, JML [ptr] does 24-bit indirect jump,
        ; handler RTLs back to the RTS inside cop_call, RTS returns here,
        ; then RTI returns to the interrupted caller.
        JSR     cop_call
        RTI

cop_call:
        JML     [hal_tmp_ptr]   ; indirect 24-bit jump through ZP pointer
                                ; handler RTL returns to this RTS
ENDPUBLIC

; =============================================================================
; cop_table -- 3-byte far addresses indexed by COP operand byte
; Order must match HAL_FN_* constants in hal_jumptable.asm
; =============================================================================

cop_table:
        .faraddr hal_baud_set_timer ; 0  HAL_FN_BAUD_SET_TIMER
        .faraddr hal_uart_set_timer ; 1  HAL_FN_UART_SET_TIMER
        .faraddr hal_uart_init      ; 2  HAL_FN_UART_INIT
        .faraddr hal_uart_putc      ; 3  HAL_FN_UART_PUTC
        .faraddr hal_uart_getc      ; 4  HAL_FN_UART_GETC
        .faraddr hal_uart_puts      ; 5  HAL_FN_UART_PUTS
        .faraddr hal_uart_status    ; 6  HAL_FN_UART_STATUS
        .faraddr hal_uart_rx_ready  ; 7  HAL_FN_UART_RX_READY
        .faraddr hal_via_init       ; 8  HAL_FN_VIA_INIT
        .faraddr hal_via_set_dir    ; 9  HAL_FN_VIA_SET_DIR
        .faraddr hal_via_write      ; 10 HAL_FN_VIA_WRITE
        .faraddr hal_via_read       ; 11 HAL_FN_VIA_READ
        .faraddr hal_set_brk        ; 12 HAL_FN_SET_BRK
        .faraddr hal_set_isr        ; 13 HAL_FN_SET_ISR
        .faraddr hal_set_nmi        ; 14 HAL_FN_SET_NMI
        .faraddr hal_version        ; 15 HAL_FN_VERSION
