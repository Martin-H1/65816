; =============================================================================
; hal_sfr.inc — W65C265S Special Function Register definitions
;
; Include this file in any HAL source that accesses hardware registers.
; All addresses are absolute in bank $00.
;
; Sources: W65C265S Datasheet rev 2.2 (March 2024), section 2.5
; =============================================================================

.ifndef HAL_SFR_INC
HAL_SFR_INC = 1

; =============================================================================
; Control and Status Registers  $DF40–$DF4F
; =============================================================================

BCR     = $DF40             ; Bus Control Register
SSCR    = $DF41             ; System Speed Control Register
TCR     = $DF42             ; Timer Control Register
TER     = $DF43             ; Timer Enable Register
TIFR    = $DF44             ; Timer Interrupt Flag Register
EIFR    = $DF45             ; Edge Interrupt Flag Register
TIER    = $DF46             ; Timer Interrupt Enable Register
EIER    = $DF47             ; Edge Interrupt Enable Register
UIFR    = $DF48             ; UART Interrupt Flag Register
UIER    = $DF49             ; UART Interrupt Enable Register
                            ; $DF4A–$DF4F reserved

; ── BCR bit masks ────────────────────────────────────────────────────────────
BCR_EXT_BUS     = 1 << 0   ; 1 = Ports 0–3 are address/data bus
BCR_TG0_EN      = 1 << 1   ; 1 = Enable Tone Generator 0
BCR_TG1_EN      = 1 << 2   ; 1 = Enable Tone Generator 1
BCR_ICE_EN      = 1 << 3   ; 1 = In-circuit emulation mode
BCR_WDOG_EN     = 1 << 4   ; 1 = Enable watchdog (Timer 0)
BCR_ABORTB_EN   = 1 << 5   ; 1 = Enable ABORTB on P40
BCR_NMIB_EN     = 1 << 6   ; 1 = Enable NMIB on P40
BCR_EXT_ROM     = 1 << 7   ; 1 = External ROM ($E000–$FFFF)

; ── TCR bit masks ─────────────────────────────────────────────────────────────
; UARTn timer select: 0 = Timer 3, 1 = Timer 4
TCR_T4_CLK      = 1 << 0   ; Timer 4 clock: 0=FCLK, 1=P60
TCR_T4_OUT_EN   = 1 << 1   ; Timer 4 output enable on P61
TCR_PWM_POS     = 1 << 2   ; PWM edge: bit2/3 select
TCR_PWM_NEG     = 1 << 3
TCR_UART0_T4    = 1 << 4   ; UART0: 0=T3, 1=T4
TCR_UART1_T4    = 1 << 5   ; UART1: 0=T3, 1=T4
TCR_UART2_T4    = 1 << 6   ; UART2: 0=T3, 1=T4
TCR_UART3_T4    = 1 << 7   ; UART3: 0=T3, 1=T4

; ── UIER / UIFR bit masks ────────────────────────────────────────────────────
UIER_UART0R     = 1 << 0   ; UART0 receiver interrupt enable/flag
UIER_UART0T     = 1 << 1   ; UART0 transmitter interrupt enable/flag
UIER_UART1R     = 1 << 2
UIER_UART1T     = 1 << 3
UIER_UART2R     = 1 << 4
UIER_UART2T     = 1 << 5
UIER_UART3R     = 1 << 6
UIER_UART3T     = 1 << 7

; =============================================================================
; Timer Registers  $DF50–$DF6F
; =============================================================================

T0LL    = $DF50             ; Timer 0 Latch Low  (watchdog)
T0LH    = $DF51             ; Timer 0 Latch High
T1LL    = $DF52             ; Timer 1 Latch Low  (time of day)
T1LH    = $DF53
T2LL    = $DF54             ; Timer 2 Latch Low  (prescaled interrupt)
T2LH    = $DF55
T3LL    = $DF56             ; Timer 3 Latch Low  (UART baud rate A)
T3LH    = $DF57             ; Timer 3 Latch High
T4LL    = $DF58             ; Timer 4 Latch Low  (UART baud rate B)
T4LH    = $DF59             ; Timer 4 Latch High
T5LL    = $DF5A             ; Timer 5 Latch Low  (tone generator)
T5LH    = $DF5B
T6LL    = $DF5C             ; Timer 6 Latch Low  (tone generator)
T6LH    = $DF5D
T7LL    = $DF5E             ; Timer 7 Latch Low  (pulse width measurement)
T7LH    = $DF5F

T0CL    = $DF60             ; Timer 0 Counter Low  (read-only)
T0CH    = $DF61
T1CL    = $DF62
T1CH    = $DF63
T2CL    = $DF64
T2CH    = $DF65
T3CL    = $DF66
T3CH    = $DF67
T4CL    = $DF68
T4CH    = $DF69
T5CL    = $DF6A
T5CH    = $DF6B
T6CL    = $DF6C
T6CH    = $DF6D
T7CL    = $DF6E
T7CH    = $DF6F

; =============================================================================
; UART Registers  $DF70–$DF77
; =============================================================================

ACSR0   = $DF70             ; UART0 Async Control/Status Register
ARTD0   = $DF71             ; UART0 Async Data Register (TX write / RX read)
ACSR1   = $DF72             ; UART1 Control/Status
ARTD1   = $DF73             ; UART1 Data
ACSR2   = $DF74             ; UART2 Control/Status
ARTD2   = $DF75             ; UART2 Data
ACSR3   = $DF76             ; UART3 Control/Status
ARTD3   = $DF77             ; UART3 Data

; ── ACSRx bit masks ──────────────────────────────────────────────────────────
; Written to control TX/RX; read to check status.
; Bits 0–1 are control-only (write). Bits 4–7 are status (read).
; Verify exact bit positions against WDC EQUATES.ASM before finalising.

ACSR_TX_EN      = 1 << 0   ; Enable transmitter
ACSR_TX_INT_SEL = 1 << 1   ; TX interrupt: 0=DR empty, 1=DR+SR empty
ACSR_8BIT       = 1 << 2   ; 1=8-bit data, 0=7-bit
ACSR_PARITY_EN  = 1 << 3   ; Enable parity
ACSR_RX_EN      = 1 << 5   ; Enable receiver
                            ; bit 4: parity select (when ACSR_PARITY_EN)
ACSR_RX_FULL    = 1 << 6   ; Status: RX data register full (read)
ACSR_TX_EMPTY   = 1 << 7   ; Status: TX data register empty (read)

; ── Baud divisors for Timer 3 / Timer 4 @ 3.6864 MHz FCLK ───────────────────
; Formula: N = (FCLK / (16 * bps)) - 1
; Load N into TnLH:TnLL (write TnLH last — triggers counter reload)

BAUD_300    = $02FF
BAUD_1200   = $00BF
BAUD_2400   = $005F
BAUD_4800   = $002F
BAUD_9600   = $0017
BAUD_19200  = $000B
BAUD_38400  = $0005
BAUD_57600  = $0003
BAUD_115200 = $0001

; =============================================================================
; PIB Registers  $DF78–$DF7F
; =============================================================================

PIBFR   = $DF78             ; PIB Flag Register
PIBER   = $DF79             ; PIB Enable Register
PIR2    = $DF7A             ; PIB Register 2
PIR3    = $DF7B             ; PIB Register 3
PIR4    = $DF7C             ; PIB Register 4
PIR5    = $DF7D             ; PIB Register 5
PIR6    = $DF7E             ; PIB Register 6
PIR7    = $DF7F             ; PIB Register 7

; =============================================================================
; I/O Port Registers  $DF00–$DF27
; =============================================================================

PD0     = $DF00             ; Port 0 Data Register
PD1     = $DF01             ; Port 1 Data Register
PD2     = $DF02             ; Port 2 Data Register
PD3     = $DF03             ; Port 3 Data Register
PDD0    = $DF04             ; Port 0 Data Direction Register
PDD1    = $DF05             ; Port 1 DDR
PDD2    = $DF06             ; Port 2 DDR
PDD3    = $DF07             ; Port 3 DDR

PD4     = $DF20             ; Port 4 Data Register
PD5     = $DF21             ; Port 5 Data Register
PD6     = $DF22             ; Port 6 Data Register
PD7     = $DF23             ; Port 7 Data Register (chip selects)
PDD4    = $DF24             ; Port 4 DDR
PDD5    = $DF25             ; Port 5 DDR
PDD6    = $DF26             ; Port 6 DDR
PCS7    = $DF27             ; Port 7 Chip Select Register

; =============================================================================
; W65C22 VIA  — memory mapped at $00:DFE0
; =============================================================================

VIA_BASE    = $DFE0

VIA_ORB     = VIA_BASE + $00    ; Output Register Port B
VIA_ORA     = VIA_BASE + $01    ; Output Register Port A
VIA_DDRB    = VIA_BASE + $02    ; Data Direction Register B (1=output)
VIA_DDRA    = VIA_BASE + $03    ; Data Direction Register A
VIA_T1CL    = VIA_BASE + $04    ; Timer 1 Counter Low
VIA_T1CH    = VIA_BASE + $05    ; Timer 1 Counter High
VIA_T1LL    = VIA_BASE + $06    ; Timer 1 Latch Low
VIA_T1LH    = VIA_BASE + $07    ; Timer 1 Latch High
VIA_T2CL    = VIA_BASE + $08    ; Timer 2 Counter Low
VIA_T2CH    = VIA_BASE + $09    ; Timer 2 Counter High
VIA_SR      = VIA_BASE + $0A    ; Shift Register
VIA_ACR     = VIA_BASE + $0B    ; Auxiliary Control Register
VIA_PCR     = VIA_BASE + $0C    ; Peripheral Control Register
VIA_IFR     = VIA_BASE + $0D    ; Interrupt Flag Register
VIA_IER     = VIA_BASE + $0E    ; Interrupt Enable Register
VIA_ORAH    = VIA_BASE + $0F    ; Output Register A (no handshake)

; ── VIA Port B — SPI to SD card ──────────────────────────────────────────────
; Bit assignments for Port B (all outputs except MISO)
SPI_MOSI    = 1 << 0        ; PB0 — Master Out Slave In
SPI_MISO    = 1 << 1        ; PB1 — Master In Slave Out  (input)
SPI_SCK     = 1 << 2        ; PB2 — SPI clock
SPI_CS_SD   = 1 << 3        ; PB3 — SD card chip select (active low)
                            ; PB4–PB7 reserved for future SPI devices

SPI_DDRB_VAL = SPI_MOSI | SPI_SCK | SPI_CS_SD
                            ; MISO is input (bit clear), others output

; ── VIA Port A — general purpose GPIO ────────────────────────────────────────
; Direction configured at runtime via hal_via_set_dir.
; No fixed bit assignments — available to programs via HAL GPIO API.

; =============================================================================
; HAL constants
; =============================================================================

HAL_VERSION = $0100         ; BCD: major=$01 minor=$00

; Timer select constants (for hal_baud_set_timer / hal_uart_set_timer)
HAL_TIMER3  = 0
HAL_TIMER4  = 1

; UART channel constants
HAL_UART0   = 0
HAL_UART1   = 1
HAL_UART2   = 2
HAL_UART3   = 3

; Forth kernel signature (4 bytes at $8000)
FORTH_SIG_0 = $46           ; 'F'
FORTH_SIG_1 = $54           ; 'T'
FORTH_SIG_2 = $48           ; 'H'
FORTH_SIG_3 = $00           ; NUL

.endif  ; HAL_SFR_INC
