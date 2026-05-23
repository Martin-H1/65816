; =============================================================================
; hal_page2.asm — HAL private page variable declarations ($0200–$02FF)
;
; This page lives in external SRAM. It is initialised (zeroed) by hal_init
; at boot. No bytes are emitted into the EEPROM image — these are BSS
; declarations only.
;
; Layout:
;   $0200–$0202   brk_vector      24-bit BRK callback address
;   $0203–$0205   irq_vector      24-bit IRQ callback address
;   $0206–$0208   nmi_vector      24-bit NMI callback address
;   $0209–$0248   u0_rx_buf       UART0 RX ring buffer (64 bytes)
;   $0249         u0_rx_head      UART0 RX write index
;   $024A         u0_rx_tail      UART0 RX read index
;   $024B–$026A   u0_tx_buf       UART0 TX ring buffer (32 bytes)
;   $026B         u0_tx_head      UART0 TX write index
;   $026C         u0_tx_tail      UART0 TX read index
;   $026D–$02AC   u1_rx_buf       UART1 RX ring buffer (64 bytes)
;   $02AD         u1_rx_head
;   $02AE         u1_rx_tail
;   $02AF–$02CE   u1_tx_buf       UART1 TX ring buffer (32 bytes)
;   $02CF         u1_tx_head
;   $02D0         u1_tx_tail
;   $02D1         via_ddra_shad   VIA Port A DDR shadow
;   $02D2         via_ddrb_shad   VIA Port B DDR shadow
;   $02D3         hal_ver_lo      HAL version low byte
;   $02D4         hal_ver_hi      HAL version high byte
;   $02D5–$02FF   reserved
; =============================================================================

        .p816
        .smart  off

        ; Export all symbols so other files can reference them via .global
        .export brk_vector, irq_vector, nmi_vector
        .export u0_rx_buf, u0_rx_head, u0_rx_tail
        .export u0_tx_buf, u0_tx_head, u0_tx_tail
        .export u1_rx_buf, u1_rx_head, u1_rx_tail
        .export u1_tx_buf, u1_tx_head, u1_tx_tail
        .export via_ddra_shad, via_ddrb_shad
        .export hal_ver_lo, hal_ver_hi

        .segment "BSS_PAGE2"

; ── Interrupt callback vectors (24-bit JSL targets) ──────────────────────────
; Set by hal_set_brk / hal_set_isr / hal_set_nmi.
; Default (zero) = no handler installed; HAL dispatcher checks before calling.

brk_vector:     .res 3      ; $0200

irq_vector:     .res 3      ; $0203

nmi_vector:     .res 3      ; $0206

; ── UART0 RX ring buffer ─────────────────────────────────────────────────────
; Power-of-2 size (64) allows head/tail wrap with AND #$3F.

u0_rx_buf:      .res 64     ; $0209–$0248
u0_rx_head:     .res 1      ; $0249 — ISR writes (next empty slot)
u0_rx_tail:     .res 1      ; $024A — hal_uart_getc reads (oldest byte)

; ── UART0 TX ring buffer ─────────────────────────────────────────────────────
; Power-of-2 size (32) allows head/tail wrap with AND #$1F.

u0_tx_buf:      .res 32     ; $024B–$026A
u0_tx_head:     .res 1      ; $026B — hal_uart_putc writes
u0_tx_tail:     .res 1      ; $026C — TX ISR reads

; ── UART1 RX ring buffer ─────────────────────────────────────────────────────

u1_rx_buf:      .res 64     ; $026D–$02AC
u1_rx_head:     .res 1      ; $02AD
u1_rx_tail:     .res 1      ; $02AE

; ── UART1 TX ring buffer ─────────────────────────────────────────────────────

u1_tx_buf:      .res 32     ; $02AF–$02CE
u1_tx_head:     .res 1      ; $02CF
u1_tx_tail:     .res 1      ; $02D0

; ── VIA shadow registers ─────────────────────────────────────────────────────
; Shadows let the HAL do read-modify-write on port direction without
; a hardware read (which would read pin state, not the DDR value).

via_ddra_shad:  .res 1      ; $02D1
via_ddrb_shad:  .res 1      ; $02D2

; ── HAL metadata ─────────────────────────────────────────────────────────────

hal_ver_lo:     .res 1      ; $02D3
hal_ver_hi:     .res 1      ; $02D4

; ── Reserved ─────────────────────────────────────────────────────────────────

                .res 43     ; $02D5–$02FF
