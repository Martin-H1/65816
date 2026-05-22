; =============================================================================
; hal_via.asm — W65C22 VIA driver
;
; Provides:
;   hal_via_init      — initialise VIA, Port A (GPIO), Port B (SPI)
;   hal_via_set_dir   — set Port A or Port B data direction
;   hal_via_write     — write a value to Port A or Port B
;   hal_via_read      — read Port A or Port B pin state
;
; Port assignments:
;   Port A  — general purpose GPIO, all inputs by default
;   Port B  — SPI to SD card
;               PB0  MOSI  (output)
;               PB1  MISO  (input)
;               PB2  SCK   (output)
;               PB3  /CS   (output, active low — deasserted high on init)
;               PB4–PB7  reserved for future SPI devices
;
; Calling convention (matches HAL standard):
;   A  8-bit  first argument / return value
;   X  8-bit  second argument
;   A, X, Y   caller-saved (HAL may clobber)
;   D, B      HAL saves and restores
;
; All public routines are reached via JSL from the jump table and
; end with RTL. hal_via_init is also called via JSR from hal_reset
; (same bank) and ends with RTS for that path — see note below.
; =============================================================================

        .setcpu "65816"
        .smart  on

        .include "hal_sfr.inc"

        ; Page-two shadow registers (defined in hal_page2.asm)
        .global via_ddra_shad
        .global via_ddrb_shad

        .segment "HAL_CODE"

; =============================================================================
; hal_via_init — initialise the W65C22 VIA
;
; Called via JSL from hal_reset
; Also reachable via JSL through the jump table (24-bit return).
; =============================================================================

        .export hal_via_init
        .proc   hal_via_init

        SEP     #$30            ; 8-bit A and X
        .a8
        .i8

        ; ── Disable VIA interrupts ────────────────────────────────────────────
        ; Write $7F to IER clears all interrupt enable bits (bit 7 = 0 → clear)
        LDA     #$7F
        STA     VIA_IER

        ; ── ACR — disable latching, shift register off, timer modes ──────────
        ; ACR = 0: T1 one-shot, T2 timed interrupt, SR disabled, no latching
        LDA     #$00
        STA     VIA_ACR

        ; ── PCR — CA1/CA2/CB1/CB2 all negative edge / input ──────────────────
        LDA     #$00
        STA     VIA_PCR

        ; ── Port B — SPI outputs ─────────────────────────────────────────────
        ; Set initial output states BEFORE setting DDR to avoid glitches:
        ;   SCK  low  (idle)
        ;   MOSI low  (idle)
        ;   /CS  high (deasserted — SD card not selected)
        LDA     #SPI_CS_SD      ; CS high, SCK low, MOSI low
        STA     VIA_ORB

        ; Set DDR: MOSI, SCK, /CS = outputs; MISO = input
        LDA     #SPI_DDRB_VAL
        STA     VIA_DDRB
        STA     via_ddrb_shad   ; update shadow

        ; ── Port A — all inputs by default ───────────────────────────────────
        LDA     #$00
        STA     VIA_DDRA
        STA     via_ddra_shad   ; update shadow

        ; ── Clear IFR — acknowledge any pending interrupt flags ───────────────
        LDA     #$7F
        STA     VIA_IFR

        RTS

        .endproc

; =============================================================================
; hal_via_set_dir — set data direction for Port A or Port B
;
;   In:  A (8-bit) = port select: 0 = Port A, 1 = Port B
;        X (8-bit) = DDR value (1 = output, 0 = input, per bit)
;
; Updates the shadow register and writes the VIA DDR.
; For Port B, the caller is responsible for not clobbering the SPI bits
; unless they intend to reconfigure SPI — the HAL does not enforce this.
; =============================================================================

        .export hal_via_set_dir
        .proc   hal_via_set_dir

        SEP     #$30
        .a8
        .i8

        CMP     #0
        BNE     @port_b

@port_a:
        STX     VIA_DDRA
        STX     via_ddra_shad
        RTL

@port_b:
        STX     VIA_DDRB
        STX     via_ddrb_shad
        RTL

        .endproc

; =============================================================================
; hal_via_write — write a value to Port A or Port B output register
;
;   In:  A (8-bit) = port select: 0 = Port A, 1 = Port B
;        X (8-bit) = value to write
;
; Writes to VIA_ORA (no handshake) for Port A, VIA_ORB for Port B.
; Note: only bits configured as outputs in the DDR will drive the pins.
; =============================================================================

        .export hal_via_write
        .proc   hal_via_write

        SEP     #$30
        .a8
        .i8

        CMP     #0
        BNE     @port_b

@port_a:
        STX     VIA_ORAH        ; ORA without handshake
        RTL

@port_b:
        STX     VIA_ORB
        RTL

        .endproc

; =============================================================================
; hal_via_read — read pin state from Port A or Port B
;
;   In:  A (8-bit) = port select: 0 = Port A, 1 = Port B
;   Out: A (8-bit) = port pin state (reads IRA/IRB, not output latch)
;
; Reading VIA_ORA triggers handshake; VIA_ORAH reads without handshake.
; Reading VIA_ORB on the W65C22 returns the output latch for output pins
; and pin state for input pins — this is standard W65C22 behaviour.
; =============================================================================

        .export hal_via_read
        .proc   hal_via_read

        SEP     #$30
        .a8
        .i8

        CMP     #0
        BNE     @port_b

@port_a:
        LDA     VIA_ORAH        ; read Port A without handshake
        RTL

@port_b:
        LDA     VIA_ORB         ; read Port B
        RTL

        .endproc
