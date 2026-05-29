; =============================================================================
; hal_sfr.inc — W65C265S Special Function Register definitions
;
; Source: WDC W65C265S Internal ROM Monitor EQU265.H (authoritative)
;         https://github.com/WesternDesignCenter/W65C265S-Internal-ROM-Monitor
;
; Include this file in any HAL source that accesses hardware registers.
; All addresses are in bank $00.
; =============================================================================

        .ifndef HAL_SFR_INC
        HAL_SFR_INC = 1

; =============================================================================
; I/O Port Registers
; =============================================================================

PD0     = $DF00         ; Port 0 Data Register
PD1     = $DF01         ; Port 1 Data Register
PD2     = $DF02         ; Port 2 Data Register
PD3     = $DF03         ; Port 3 Data Register
PDD0    = $DF04         ; Port 0 Data Direction Register
PDD1    = $DF05         ; Port 1 DDR
PDD2    = $DF06         ; Port 2 DDR
PDD3    = $DF07         ; Port 3 DDR

                        ; $DF08–$DF0F reserved

; =============================================================================
; Internal VIA (W65C265S on-chip) — $DF10
; NOTE: This is the WDC monitor's internal VIA, used on the WDC eval board.
;       Your external W65C22 is at $DFE0 — see section below.
;       Listed here for completeness; do not use in HAL code.
; =============================================================================

VCS0            = $DF10         ; Internal VIA base (WDC eval board only)

                        ; $DF11–$DF1F reserved

; =============================================================================
; I/O Port Registers (continued)
; =============================================================================

PD4     = $DF20         ; Port 4 Data Register
PD5     = $DF21         ; Port 5 Data Register
PD6     = $DF22         ; Port 6 Data Register
PD7     = $DF23         ; Port 7 Data Register
PDD4    = $DF24         ; Port 4 DDR
PDD5    = $DF25         ; Port 5 DDR
PDD6    = $DF26         ; Port 6 DDR

PCS7    = $DF27         ; Port 7 Chip Select Enable Register
                        ; Bit 0 — PCS70: port replacement & expansion
                        ; Bit 1 — PCS71: coprocessor expansion
                        ; Bit 2 — PCS72: on-chip peripherals
                        ; Bit 3 — PCS73: $000200–$007FFF cache memory
                        ; Bit 4 — PCS74: $8000–$DEFF & $E000–$FFFF ROM
                        ; Bit 5 — PCS75: 4M banks $00–$3F
                        ; Bit 6 — PCS76: 8M banks $40–$BF
                        ; Bit 7 — PCS77: 4M banks $C0–$CF

                        ; $DF28–$DF3F reserved

; =============================================================================
; Control and Status Registers  $DF40–$DF49
; =============================================================================

BCR     = $DF40         ; Bus Control Register
                        ; Bit 0 — external memory bus enable
                        ; Bit 1 — tone generator 0 enable
                        ; Bit 2 — tone generator 1 enable
                        ; Bit 3 — ICE enable (1 = ICE mode)
                        ; Bit 4 — monitor watchdog enable
                        ; Bit 5 — ABORT enable on P40
                        ; Bit 6 — NMI enable on P40
                        ; Bit 7 — external $E000–$FFFF = 1

; BCR bit masks
BCR_EXT_BUS     = $01   ; External memory bus enable
BCR_TG0_EN      = $02   ; Tone generator 0 enable
BCR_TG1_EN      = $04   ; Tone generator 1 enable
BCR_ICE_EN      = $08   ; ICE enable
BCR_WDOG_EN     = $10   ; Watchdog enable
BCR_ABORT_EN    = $20   ; ABORT enable on P40
BCR_NMIB_EN     = $40   ; NMI enable on P40
BCR_EXT_ROM     = $80   ; External $E000–$FFFF

SSCR    = $DF41         ; System Speed Control Register
                        ; Bit 0 — FCLK start/stop (1 = start)
                        ; Bit 1 — PHI2 (1 = PHI2 clk as FCLK/4)
                        ; Bit 2 — external RAM select (1 = ext $0000–$01FF)
                        ; Bit 3 — sys CS0–CS7 speed (1 = fast FCLK)
                        ; Bit 4 — CS4 speed (1 = fast)
                        ; Bit 5 — CS5 speed (1 = fast)
                        ; Bit 6 — CS6 speed (1 = fast)
                        ; Bit 7 — CS7 speed (1 = fast)

TCR     = $DF42         ; Timer Control Register
                        ; Bit 0 — Timer 4 input clock (0 = FCLK)
                        ; Bit 1 — Timer 4 output enable on P61
                        ; Bit 2 — PWM (00=disable, 01=pos edge,
                        ; Bit 3 —      10=neg edge, 11=both edges)
                        ; Bit 4 — UART0 timer select (0=T3, 1=T4)
                        ; Bit 5 — UART1 timer select (0=T3, 1=T4)
                        ; Bit 6 — UART2 timer select (0=T3, 1=T4)
                        ; Bit 7 — UART3 timer select (0=T3, 1=T4)

; TCR UART timer select masks (one bit per UART, set=T4, clear=T3)
TCR_UART0_T4    = $10
TCR_UART1_T4    = $20
TCR_UART2_T4    = $40
TCR_UART3_T4    = $80

TER     = $DF43         ; Timer Enable Register (bit n = enable timer n)
T0FLG   = $01           ; Timer 0 flag (also used in TIFR/TIER)
T1FLG   = $02
T2FLG   = $04
T3FLG   = $08
T4FLG   = $10
T5FLG   = $20
T6FLG   = $40
T7FLG   = $80

TIFR    = $DF44         ; Timer Interrupt Flag Register (bit n = timer n pending)
EIFR    = $DF45         ; Edge Interrupt Flag Register
                        ; Bit 0 — PE56 edge IRQ
                        ; Bit 1 — NE57 edge IRQ
                        ; Bit 2 — PE60 edge IRQ
                        ; Bit 3 — PWM programmable edge IRQ (P62)
                        ; Bit 4 — NE64 edge IRQ
                        ; Bit 5 — NE66 edge IRQ
                        ; Bit 6 — PIB IRQ
                        ; Bit 7 — IRQ level IRQ

TIER    = $DF46         ; Timer Interrupt Enable Register (bit n = enable timer n IRQ)
EIER    = $DF47         ; Edge Interrupt Enable Register
PE56ENABLE   = $01
NE57ENABLE   = $02
PE60ENABLE   = $04
PWMENABLE    = $08
NE64ENABLE   = $10
NE66ENABLE   = $20
PIBIRQENABLE = $40

UIFR    = $DF48         ; UART Interrupt Flag Register
                        ; Bit 0 — UART0 receive  (1 = pending)
                        ; Bit 1 — UART0 transmit (1 = pending)
                        ; Bit 2 — UART1 receive
                        ; Bit 3 — UART1 transmit
                        ; Bit 4 — UART2 receive
                        ; Bit 5 — UART2 transmit
                        ; Bit 6 — UART3 receive
                        ; Bit 7 — UART3 transmit
UART0R  = $01
UART0T  = $02
UART1R  = $04
UART1T  = $08
UART2R  = $10
UART2T  = $20
UART3R  = $40
UART3T  = $80

UIER    = $DF49         ; UART Interrupt Enable Register (same bit layout as UIFR)

                        ; $DF4A–$DF4F reserved

; =============================================================================
; Timer Latch Registers  $DF50–$DF5F
;
; Timer assignments:
;   T0 — monitor watchdog
;   T1 — time of day clock
;   T2 — prescaled interrupt (up counter)
;   T3 — UART baud rate generator A
;   T4 — UART baud rate generator B
;   T5 — tone generator
;   T6 — tone generator
;   T7 — PWM
; =============================================================================

T0LL    = $DF50         ; Timer 0 Latch Low
T0LH    = $DF51         ; Timer 0 Latch High
T1LL    = $DF52         ; Timer 1 Latch Low
T1LH    = $DF53
T2LL    = $DF54         ; Timer 2 Latch Low
T2LH    = $DF55
T3LL    = $DF56         ; Timer 3 Latch Low  (baud rate A)
T3LH    = $DF57         ; Timer 3 Latch High
T4LL    = $DF58         ; Timer 4 Latch Low  (baud rate B)
T4LH    = $DF59
T5LL    = $DF5A         ; Timer 5 Latch Low
T5LH    = $DF5B
T6LL    = $DF5C
T6LH    = $DF5D
T7LL    = $DF5E
T7LH    = $DF5F

; =============================================================================
; Timer Counter Registers  $DF60–$DF6F  (read-only)
; =============================================================================

T0CL    = $DF60
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

ACSR0   = $DF70         ; UART0 Async Control/Status Register
ARTD0   = $DF71         ; UART0 Async Receiver/Transmitter Data Register
ACSR1   = $DF72         ; UART1 Control/Status
ARTD1   = $DF73         ; UART1 Data
ACSR2   = $DF74         ; UART2 Control/Status
ARTD2   = $DF75         ; UART2 Data
ACSR3   = $DF76         ; UART3 Control/Status
ARTD3   = $DF77         ; UART3 Data

; ACSRx bit definitions (from EQU265.H)
;   Bit 0 — SON:     transmit port enable (serial on)
;   Bit 1 — DISCH:   transmit IRQ source (0=data reg empty, 1=shift reg empty)
;   Bit 2 —          data bits (0=7-bit, 1=8-bit)
;   Bit 3 —          parity enable
;   Bit 4 —          parity select (0=odd, 1=even)
;   Bit 5 —          receive enable
;   Bit 6 —          software semaphore (not a status flag)
;   Bit 7 —          receive error flag (read) — framing/overrun
;
; NOTE: There are NO rx-ready or tx-empty status bits in ACSRx.
;       UART interrupt status is in UIFR; enable bits are in UIER.
;       The interrupt-driven ring buffer design is the correct approach.

SON             = $01   ; Transmit enable (serial on)
DISCH           = $02   ; TX IRQ source select
ACSR_8BIT       = $04   ; 8-bit data (vs 7-bit)
ACSR_PAR_EN     = $08   ; Parity enable
ACSR_PAR_EVEN   = $10   ; Even parity (0 = odd)
ACSR_RX_EN      = $20   ; Receive enable
ACSR_SEMAPHORE  = $40   ; Software semaphore
ACSR_RX_ERR     = $80   ; Receive error flag (read-only)

; Convenience: standard 8N1 configuration word
ACSR_8N1        = SON | ACSR_8BIT | ACSR_RX_EN

; =============================================================================
; Baud rate divisors for Timer 3 / Timer 4 @ 3.6864 MHz FCLK
;
; Formula: N = (FCLK / (16 * bps)) - 1
; Write N low byte to TnLL, high byte to TnLH.
; Both T3 and T4 must also be enabled in TER.
; =============================================================================

BAUD_300        = $02FF
BAUD_1200       = $00BF
BAUD_2400       = $005F
BAUD_4800       = $002F
BAUD_9600       = $0017
BAUD_19200      = $000B
BAUD_38400      = $0005
BAUD_57600      = $0003
BAUD_115200     = $0001

; =============================================================================
; W65C22 VIA — external, memory mapped at $00:DFE0
; =============================================================================

VIA_BASE        = $DFE0

VIA_ORB         = VIA_BASE + $00    ; Output Register Port B
VIA_ORA         = VIA_BASE + $01    ; Output Register Port A
VIA_DDRB        = VIA_BASE + $02    ; Data Direction Register B (1=output)
VIA_DDRA        = VIA_BASE + $03    ; Data Direction Register A
VIA_T1CL        = VIA_BASE + $04    ; Timer 1 Counter Low
VIA_T1CH        = VIA_BASE + $05    ; Timer 1 Counter High
VIA_T1LL        = VIA_BASE + $06    ; Timer 1 Latch Low
VIA_T1LH        = VIA_BASE + $07    ; Timer 1 Latch High
VIA_T2CL        = VIA_BASE + $08    ; Timer 2 Counter Low
VIA_T2CH        = VIA_BASE + $09    ; Timer 2 Counter High
VIA_SR          = VIA_BASE + $0A    ; Shift Register
VIA_ACR         = VIA_BASE + $0B    ; Auxiliary Control Register
VIA_PCR         = VIA_BASE + $0C    ; Peripheral Control Register
VIA_IFR         = VIA_BASE + $0D    ; Interrupt Flag Register
VIA_IER         = VIA_BASE + $0E    ; Interrupt Enable Register
VIA_ORAH        = VIA_BASE + $0F    ; Output Register A (no handshake)

; ── VIA Port B — SPI to SD card ──────────────────────────────────────────────
SPI_MOSI        = $01               ; PB0 — Master Out Slave In  (output)
SPI_MISO        = $02               ; PB1 — Master In Slave Out  (input)
SPI_SCK         = $04               ; PB2 — SPI clock            (output)
SPI_CS_SD       = $08               ; PB3 — SD card /CS          (output, active low)
                                    ; PB4–PB7 reserved

SPI_DDRB_VAL    = SPI_MOSI | SPI_SCK | SPI_CS_SD   ; MISO is input

; ── VIA Port A — general purpose GPIO ────────────────────────────────────────
; Direction configured at runtime via hal_via_set_dir.

; =============================================================================
; HAL constants
; =============================================================================

HAL_VERSION     = $0100     ; BCD: major=$01 minor=$00

; Timer select constants
HAL_TIMER3      = 0
HAL_TIMER4      = 1

; UART channel constants
HAL_UART0       = 0
HAL_UART1       = 1
HAL_UART2       = 2
HAL_UART3       = 3

; Forth kernel boot signature and probe locations
; Forth lives in the $8004-$BEEF region alongside the HAL.
; These addresses must match the Forth build's linker configuration.
FORTH_PROBE_ADDR = $B000    ; "FTH\0" signature checked by hal_probe_forth
FORTH_ENTRY_ADDR = $B004    ; Forth entry point (JSL target)
FORTH_SIG_0     = $46       ; 'F'
FORTH_SIG_1     = $54       ; 'T'
FORTH_SIG_2     = $48       ; 'H'
FORTH_SIG_3     = $00       ; NUL

        .endif  ; HAL_SFR_INC
