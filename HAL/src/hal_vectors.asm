; =============================================================================
; hal_vectors.asm — W65C265S interrupt vector tables
;
; Native mode vectors:   $FF80–$FFBF  (used by HAL — 65816 runs in native mode)
; Emulation mode vectors:$FFC0–$FFFF  (safety fallback only)
;
; The W65C265S has 32 two-byte vectors in each table, covering the full
; priority-encoded interrupt controller. See datasheet section 2.4.
;
; All unimplemented vectors point to hal_isr_unused, which disables the
; interrupt source and RTIs — prevents spurious interrupt lockup.
;
; Vector table addresses (native mode, from datasheet):
;   $FF80/$FF81   IRQT0   Timer 0 (watchdog — resets system, not here)
;   $FF82/$FF83   IRQT1   Timer 1 (time of day)
;   $FF84/$FF85   IRQT2   Timer 2 (prescaled)
;   $FF86/$FF87   IRQT3   Timer 3 (baud rate — does not interrupt)
;   $FF88/$FF89   IRQT4   Timer 4 (baud rate — does not interrupt)
;   $FF8A/$FF8B   IRQT5   Timer 5 (tone)
;   $FF8C/$FF8D   IRQT6   Timer 6 (tone)
;   $FF8E/$FF8F   IRQT7   Timer 7 (pulse width)
;   $FF90/$FF91   IRPE56  Positive edge P56
;   $FF92/$FF93   IRNE57  Negative edge P57
;   $FF94/$FF95   IRPE60  Positive edge P60
;   $FF96/$FF97   IRPE62  PWM edge P62
;   $FF98/$FF99   IRNE64  Negative edge P64
;   $FF9A/$FF9B   IRNE66  Negative edge P66
;   $FF9C/$FF9D   IRQPIB  PIB interrupt
;   $FF9E/$FF9F   IRQ     Level interrupt (IRQB pin)
;   $FFA0/$FFA1   IRQAR0  UART0 receiver
;   $FFA2/$FFA3   IRQAT0  UART0 transmitter
;   $FFA4/$FFA5   IRQAR1  UART1 receiver
;   $FFA6/$FFA7   IRQAT1  UART1 transmitter
;   $FFA8/$FFA9   IRQAR2  UART2 receiver
;   $FFAA/$FFAB   IRQAT2  UART2 transmitter
;   $FFAC/$FFAD   IRQAR3  UART3 receiver
;   $FFAE/$FFAF   IRQAT3  UART3 transmitter
;   $FFB0/$FFB1   reserved
;   $FFB2/$FFB3   reserved
;   $FFB4/$FFB5   IRQCOP  COP software interrupt
;   $FFB6/$FFB7   IRQBRK  BRK software interrupt
;   $FFB8/$FFB9   IABORT  ABORT
;   $FFBA/$FFBB   IRQNMI  NMI
;   $FFBC/$FFBD   reserved
;   $FFBE/$FFBF   reserved
; =============================================================================

        .setcpu "65816"
        .smart  on

        .include "hal_sfr.inc"

        ; Forward declarations — defined in hal_isr.asm
        .global hal_isr_unused
        .global hal_isr_irq
        .global hal_isr_nmi
        .global hal_isr_brk
        .global hal_isr_cop
        .global hal_isr_uart0_rx
        .global hal_isr_uart0_tx
        .global hal_isr_uart1_rx
        .global hal_isr_uart1_tx

; =============================================================================
; Native mode vector table  $FF80–$FFBF
; =============================================================================

        .segment "NATIVE_VECTORS"

        ; Each entry is a 16-bit address (low byte, then high byte).
        ; All addresses are within bank $00 (the EEPROM bank).

        .word   hal_isr_unused      ; $FF80  IRQT0  Timer 0 (watchdog resets)
        .word   hal_isr_unused      ; $FF82  IRQT1  Timer 1
        .word   hal_isr_unused      ; $FF84  IRQT2  Timer 2
        .word   hal_isr_unused      ; $FF86  IRQT3  Timer 3 (baud, no IRQ)
        .word   hal_isr_unused      ; $FF88  IRQT4  Timer 4 (baud, no IRQ)
        .word   hal_isr_unused      ; $FF8A  IRQT5  Timer 5
        .word   hal_isr_unused      ; $FF8C  IRQT6  Timer 6
        .word   hal_isr_unused      ; $FF8E  IRQT7  Timer 7
        .word   hal_isr_unused      ; $FF90  IRPE56
        .word   hal_isr_unused      ; $FF92  IRNE57
        .word   hal_isr_unused      ; $FF94  IRPE60
        .word   hal_isr_unused      ; $FF96  IRPE62 PWM
        .word   hal_isr_unused      ; $FF98  IRNE64
        .word   hal_isr_unused      ; $FF9A  IRNE66
        .word   hal_isr_unused      ; $FF9C  IRQPIB
        .word   hal_isr_irq         ; $FF9E  IRQ level — dispatches to irq_vector
        .word   hal_isr_uart0_rx    ; $FFA0  UART0 RX — enqueues to u0_rx_buf
        .word   hal_isr_uart0_tx    ; $FFA2  UART0 TX — drains u0_tx_buf
        .word   hal_isr_uart1_rx    ; $FFA4  UART1 RX
        .word   hal_isr_uart1_tx    ; $FFA6  UART1 TX
        .word   hal_isr_unused      ; $FFA8  UART2 RX  (not initialised by default)
        .word   hal_isr_unused      ; $FFAA  UART2 TX
        .word   hal_isr_unused      ; $FFAC  UART3 RX
        .word   hal_isr_unused      ; $FFAE  UART3 TX
        .word   hal_isr_unused      ; $FFB0  reserved
        .word   hal_isr_unused      ; $FFB2  reserved
        .word   hal_isr_cop         ; $FFB4  COP — dispatches by operand byte
        .word   hal_isr_brk         ; $FFB6  BRK — dispatches to brk_vector
        .word   hal_isr_unused      ; $FFB8  ABORT
        .word   hal_isr_nmi         ; $FFBA  NMI — dispatches to nmi_vector
        .word   hal_isr_unused      ; $FFBC  reserved
        .word   hal_isr_unused      ; $FFBE  reserved

; =============================================================================
; Emulation mode vector table  $FFC0–$FFFF
; =============================================================================
;
; The HAL runs in native mode. Emulation mode vectors are a safety net —
; if the system somehow enters emulation mode (e.g. stray XCE), the RESET
; vector here switches back to native mode immediately.
;
; All other emulation-mode vectors point to hal_isr_unused.
; =============================================================================

        .segment "EMUL_VECTORS"

        ; Forward declaration for emulation-mode reset handler
        .global hal_reset_emul

        .word   hal_isr_unused      ; $FFC0  IRQT0
        .word   hal_isr_unused      ; $FFC2  IRQT1
        .word   hal_isr_unused      ; $FFC4  IRQT2
        .word   hal_isr_unused      ; $FFC6  IRQT3
        .word   hal_isr_unused      ; $FFC8  IRQT4
        .word   hal_isr_unused      ; $FFCA  IRQT5
        .word   hal_isr_unused      ; $FFCC  IRQT6
        .word   hal_isr_unused      ; $FFCE  IRQT7
        .word   hal_isr_unused      ; $FFD0  IRPE56
        .word   hal_isr_unused      ; $FFD2  IRNE57
        .word   hal_isr_unused      ; $FFD4  IRPE60
        .word   hal_isr_unused      ; $FFD6  IRPE62
        .word   hal_isr_unused      ; $FFD8  IRNE64
        .word   hal_isr_unused      ; $FFDA  IRNE66
        .word   hal_isr_unused      ; $FFDC  IRQPIB
        .word   hal_isr_unused      ; $FFDE  IRQ
        .word   hal_isr_unused      ; $FFE0  UART0 RX
        .word   hal_isr_unused      ; $FFE2  UART0 TX
        .word   hal_isr_unused      ; $FFE4  UART1 RX
        .word   hal_isr_unused      ; $FFE6  UART1 TX
        .word   hal_isr_unused      ; $FFE8  UART2 RX
        .word   hal_isr_unused      ; $FFEA  UART2 TX
        .word   hal_isr_unused      ; $FFEC  UART3 RX
        .word   hal_isr_unused      ; $FFEE  UART3 TX
        .word   hal_isr_unused      ; $FFF0  reserved
        .word   hal_isr_unused      ; $FFF2  reserved
        .word   hal_isr_cop         ; $FFF4  COP
        .word   hal_isr_unused      ; $FFF6  reserved
        .word   hal_isr_unused      ; $FFF8  ABORT
        .word   hal_isr_unused      ; $FFFA  NMI
        .word   hal_reset_emul      ; $FFFC  RESET — switches to native mode
        .word   hal_isr_unused      ; $FFFE  IRQ/BRK (emulation mode)
