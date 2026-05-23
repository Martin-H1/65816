; =============================================================================
; hal_jumptable.asm — Fixed HAL entry points at $FF00
;
; Each entry is a 3-byte JMP abs instruction. The caller does:
;
;     JSL $00:FF00    ; jump table entry for function 0
;     JSL $00:FF03    ; jump table entry for function 1
;     ...
;
; The JSL pushes a 24-bit return address (PBR + PC) and jumps here.
; The JMP reaches the implementation within bank $00.
; The implementation ends with RTL, which pops the 24-bit return address
; and returns to the caller in whatever bank they were in.
;
; JMP abs = $4C, 3 bytes. Each slot is 3 bytes. Total table: $FF00–$FF5F.
;
; COP callers:
;   COP #n dispatches through the COP vector to hal_cop_handler, which
;   reads operand byte n and JMPs to the same targets via a pointer table.
;   COP returns via RTI (not RTL) — the handler manages this.
;
; ADDING NEW ENTRIES:
;   1. Append a JMP line below (do not insert — this breaks ABI).
;   2. Assign the next sequential HAL_FN_ constant in hal_api.inc.
;   3. Update the COP dispatch table in hal_cop.asm to match.
;   4. Increment HAL_VERSION.
;
; SD CARD SLOTS ($FF60–$FF7F) are reserved but contain $FF until
; the SD subsystem is implemented. Do not place other code there.
; =============================================================================

        .p816
        .smart  off

        .include "hal_sfr.inc"

        ; Forward declarations for all jump targets.
        ; Defined in their respective implementation files.

        .global hal_baud_set_timer  ; hal_uart.asm
        .global hal_uart_set_timer  ; hal_uart.asm
        .global hal_uart_init       ; hal_uart.asm
        .global hal_uart_putc       ; hal_uart.asm
        .global hal_uart_getc       ; hal_uart.asm
        .global hal_uart_puts       ; hal_uart.asm
        .global hal_uart_status     ; hal_uart.asm
        .global hal_uart_rx_ready   ; hal_uart.asm
        .global hal_via_init        ; hal_via.asm
        .global hal_via_set_dir     ; hal_via.asm
        .global hal_via_write       ; hal_via.asm
        .global hal_via_read        ; hal_via.asm
        .global hal_set_brk         ; hal_isr.asm
        .global hal_set_isr         ; hal_isr.asm
        .global hal_set_nmi         ; hal_isr.asm
        .global hal_version         ; hal_init.asm

        .segment "JUMPTAB"

; ── UART subsystem ───────────────────────────────────────────────────────────

; $FF00  hal_baud_set_timer
;   In:  A (8-bit)  = HAL_TIMER3 or HAL_TIMER4
;        X (16-bit) = baud divisor (BAUD_9600 etc. from hal_sfr.inc)
;   Note: affects ALL UARTs currently bound to this timer
HAL_ENTRY_BAUD_SET_TIMER:
        JMP     hal_baud_set_timer      ; $FF00–$FF02

; $FF03  hal_uart_set_timer
;   In:  A (8-bit) = UART channel (HAL_UART0–HAL_UART3)
;        X (8-bit) = HAL_TIMER3 or HAL_TIMER4
HAL_ENTRY_UART_SET_TIMER:
        JMP     hal_uart_set_timer      ; $FF03–$FF05

; $FF06  hal_uart_init
;   In:  A (8-bit) = UART channel
;   Enables RX interrupt for channel. TX interrupt enabled on demand.
;   Requires baud timer already configured via hal_baud_set_timer.
HAL_ENTRY_UART_INIT:
        JMP     hal_uart_init           ; $FF06–$FF08

; $FF09  hal_uart_putc
;   In:  A (8-bit) = UART channel
;        X (8-bit) = character to send
;   Enqueues byte into TX ring buffer. Enables TX interrupt. Non-blocking
;   unless TX ring is full (spins briefly until ISR drains a slot).
HAL_ENTRY_UART_PUTC:
        JMP     hal_uart_putc           ; $FF09–$FF0B

; $FF0C  hal_uart_getc
;   In:  A (8-bit) = UART channel
;   Out: A (8-bit) = received character (blocks until available)
;        Carry set if no character after timeout (future)
HAL_ENTRY_UART_GETC:
        JMP     hal_uart_getc           ; $FF0C–$FF0E

; $FF0F  hal_uart_puts
;   In:  A (8-bit)  = UART channel
;        X (16-bit) = string address (bank assumed same as caller, or use Y)
;        Y (8-bit)  = string bank byte
;   Sends null-terminated string; translates LF→CRLF.
HAL_ENTRY_UART_PUTS:
        JMP     hal_uart_puts           ; $FF0F–$FF11

; $FF12  hal_uart_status
;   In:  A (8-bit) = UART channel
;   Out: A (8-bit) = raw ACSRx value
HAL_ENTRY_UART_STATUS:
        JMP     hal_uart_status         ; $FF12–$FF14

; $FF15  hal_uart_rx_ready
;   In:  A (8-bit) = UART channel
;   Out: Z clear = byte available in RX ring; Z set = ring empty
HAL_ENTRY_UART_RX_READY:
        JMP     hal_uart_rx_ready       ; $FF15–$FF17

; ── VIA / GPIO subsystem ─────────────────────────────────────────────────────

; $FF18  hal_via_init
;   Configures VIA: Port B = SPI outputs + CS, Port A = all inputs (default).
;   Writes via_ddra_shad and via_ddrb_shad.
HAL_ENTRY_VIA_INIT:
        JMP     hal_via_init            ; $FF18–$FF1A

; $FF1B  hal_via_set_dir
;   In:  A (8-bit) = port select (0=Port A, 1=Port B)
;        X (8-bit) = DDR value (1=output, 0=input per bit)
;   Updates shadow register and writes VIA DDR.
HAL_ENTRY_VIA_SET_DIR:
        JMP     hal_via_set_dir         ; $FF1B–$FF1D

; $FF1E  hal_via_write
;   In:  A (8-bit) = port select (0=Port A, 1=Port B)
;        X (8-bit) = value to write
HAL_ENTRY_VIA_WRITE:
        JMP     hal_via_write           ; $FF1E–$FF20

; $FF21  hal_via_read
;   In:  A (8-bit) = port select (0=Port A, 1=Port B)
;   Out: A (8-bit) = port pin state
HAL_ENTRY_VIA_READ:
        JMP     hal_via_read            ; $FF21–$FF23

; ── Interrupt callback API ────────────────────────────────────────────────────

; $FF24  hal_set_brk
;   In:  X (16-bit) = handler address low word
;        Y (8-bit)  = handler bank byte
;   Stores 24-bit JSL target in brk_vector ($0200).
;   Pass X=0, Y=0 to clear (disable user BRK handler).
HAL_ENTRY_SET_BRK:
        JMP     hal_set_brk             ; $FF24–$FF26

; $FF27  hal_set_isr
;   Same convention as hal_set_brk. Stores into irq_vector ($0203).
HAL_ENTRY_SET_ISR:
        JMP     hal_set_isr             ; $FF27–$FF29

; $FF2A  hal_set_nmi
;   Same convention. Stores into nmi_vector ($0206).
HAL_ENTRY_SET_NMI:
        JMP     hal_set_nmi             ; $FF2A–$FF2C

; ── System ───────────────────────────────────────────────────────────────────

; $FF2D  hal_version
;   Out: A (16-bit) = HAL version in BCD (major byte high, minor byte low)
;        e.g. $0100 = version 1.0
HAL_ENTRY_VERSION:
        JMP     hal_version             ; $FF2D–$FF2F

; ── Reserved slots $FF30–$FF5F ────────────────────────────────────────────────
; 16 slots × 3 bytes = 48 bytes reserved.
; First 4 slots ($FF30–$FF3B) are earmarked for the SD card API:
;   $FF30  hal_sd_init
;   $FF33  hal_sd_read_block   (512-byte block → caller buffer)
;   $FF36  hal_sd_write_block  (caller buffer → 512-byte block)
;   $FF39  hal_sd_status
; Remaining 12 slots ($FF3C–$FF5F) are unassigned.
; All fill with $FF (erased EEPROM) until implemented.

; ── HAL API function number constants (for COP dispatch and documentation) ───
; hal_api.inc exports these — defined here as local constants for the table.

HAL_FN_BAUD_SET_TIMER   = 0
HAL_FN_UART_SET_TIMER   = 1
HAL_FN_UART_INIT        = 2
HAL_FN_UART_PUTC        = 3
HAL_FN_UART_GETC        = 4
HAL_FN_UART_PUTS        = 5
HAL_FN_UART_STATUS      = 6
HAL_FN_UART_RX_READY    = 7
HAL_FN_VIA_INIT         = 8
HAL_FN_VIA_SET_DIR      = 9
HAL_FN_VIA_WRITE        = 10
HAL_FN_VIA_READ         = 11
HAL_FN_SET_BRK          = 12
HAL_FN_SET_ISR          = 13
HAL_FN_SET_NMI          = 14
HAL_FN_VERSION          = 15
; 16–27: reserved (SD card + future)
