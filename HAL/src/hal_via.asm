; =============================================================================
; hal_via.asm — W65C22 VIA driver
;
; Provides:
;   hal_via_init      — initialise VIA, Port A (GPIO), Port B (SPI)
;   hal_via_init_jsr  — JSR entry point for boot sequence (same bank)
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
;               PB4-PB7  reserved for future SPI devices
;
; Calling convention:
;   A  8-bit  first argument / return value
;   X  8-bit  second argument
;   A, X, Y   caller-saved
;   D, B      HAL saves and restores
;
; Jump table entries use JSL (24-bit) and end with RTL.
; hal_via_init_jsr is called via JSR from hal_reset and ends with RTS.
; =============================================================================

        .p816
        .smart  off

        .include "macros.inc"
        .include "hal_sfr.inc"

        .global via_ddra_shad
        .global via_ddrb_shad

        .segment "HAL_CODE"

; =============================================================================
; via_init_body — shared VIA initialisation, called via JSR, ends with RTS
; =============================================================================

        .proc   via_init_body

        OFF16                   ; 8-bit A and X

        ; ── Disable VIA interrupts ────────────────────────────────────────────
        ; Bit 7 = 0 with $7F clears all interrupt enable bits
        LDA     #$7F
        STA     VIA_IER

        ; ── ACR — disable latching, shift register off, timer one-shot ───────
        LDA     #$00
        STA     VIA_ACR

        ; ── PCR — CA1/CA2/CB1/CB2 all negative edge / input ──────────────────
        LDA     #$00
        STA     VIA_PCR

        ; ── Port B — set output states BEFORE enabling outputs ────────────────
        ; SCK low (idle), MOSI low (idle), /CS high (SD deasserted)
        LDA     #SPI_CS_SD
        STA     VIA_ORB

        ; Set DDR: MOSI, SCK, /CS = outputs; MISO = input
        LDA     #SPI_DDRB_VAL
        STA     VIA_DDRB
        STA     via_ddrb_shad

        ; ── Port A — all inputs by default ───────────────────────────────────
        LDA     #$00
        STA     VIA_DDRA
        STA     via_ddra_shad

        ; ── Clear IFR — acknowledge any pending interrupt flags ───────────────
        LDA     #$7F
        STA     VIA_IFR

        RTS

        .endproc

; =============================================================================
; hal_via_init_jsr — JSR entry point called from hal_reset (same bank)
; =============================================================================

PUBLIC  hal_via_init_jsr
        JSR     via_init_body
        RTS
ENDPUBLIC

; =============================================================================
; hal_via_init — jump table entry point (JSL, ends with RTL)
; =============================================================================

PUBLIC  hal_via_init
        JSR     via_init_body
        RTL
ENDPUBLIC

; =============================================================================
; hal_via_set_dir — set data direction for Port A or Port B
;
;   In:  A (8-bit) = port select: 0 = Port A, 1 = Port B
;        X (8-bit) = DDR value (1 = output, 0 = input per bit)
;
; Updates shadow register and writes VIA DDR.
; =============================================================================

PUBLIC  hal_via_set_dir
        OFF16                   ; 8-bit A and X

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
ENDPUBLIC

; =============================================================================
; hal_via_write — write a value to Port A or Port B output register
;
;   In:  A (8-bit) = port select: 0 = Port A, 1 = Port B
;        X (8-bit) = value to write
;
; Note: only bits configured as outputs in DDR will drive pins.
; =============================================================================

PUBLIC  hal_via_write
        OFF16                   ; 8-bit A and X

        CMP     #0
        BNE     @port_b

@port_a:
        STX     VIA_ORAH        ; ORA without handshake
        RTL

@port_b:
        STX     VIA_ORB
        RTL
ENDPUBLIC

; =============================================================================
; hal_via_read — read pin state from Port A or Port B
;
;   In:  A (8-bit) = port select: 0 = Port A, 1 = Port B
;   Out: A (8-bit) = port pin state
;
; Reading VIA_ORAH reads Port A without triggering handshake.
; Reading VIA_ORB returns output latch for output pins, pin state for inputs.
; =============================================================================

PUBLIC  hal_via_read
        OFF16                   ; 8-bit A and X

        CMP     #0
        BNE     @port_b

@port_a:
        LDA     VIA_ORAH
        RTL

@port_b:
        LDA     VIA_ORB
        RTL
ENDPUBLIC
