; =============================================================================
; hal_init.asm — Boot sequence and ISR dispatchers
;
; This file provides:
;   - hal_reset        — HAL entry point (entered via JMP $8004 from masked ROM)
;   - hal_reset_emul   — safety fallback if CPU somehow enters emulation mode
;   - hal_isr_unused   — safe default for unimplemented interrupt vectors
;   - hal_isr_irq      — IRQ dispatcher -> irq_vector callback
;   - hal_isr_nmi      — NMI dispatcher -> nmi_vector callback
;   - hal_isr_brk      — BRK dispatcher -> brk_vector callback
;   - hal_version      — returns HAL_VERSION in A
;   - hal_set_brk      — install BRK callback
;   - hal_set_isr      — install IRQ callback
;   - hal_set_nmi      — install NMI callback
; =============================================================================

        .p816
        .smart  off

        .include "hal_sfr.inc"
        .include "macros.inc"

        ; Zero page variables (defined in hal_zp.asm)
        .globalzp hal_tmp0, hal_tmp1, hal_tmp_ptr, hal_flags, hal_errflg

        ; Page-two variables (defined in hal_page2.asm)
        .global brk_vector, irq_vector, nmi_vector
        .global u0_rx_buf, u0_rx_head, u0_rx_tail
        .global u0_tx_buf, u0_tx_head, u0_tx_tail
        .global u1_rx_buf, u1_rx_head, u1_rx_tail
        .global u1_tx_buf, u1_tx_head, u1_tx_tail
        .global via_ddra_shad, via_ddrb_shad
        .global hal_ver_lo, hal_ver_hi

        ; Imports from other HAL modules
        .import hal_via_init
        .import hal_uart_init
        .import hal_uart_set_timer
        .import hal_baud_set_timer
        .import hal_isr_cop

        .segment "HAL_CODE"

; =============================================================================
; IRQ_TRAMPOLINE — dispatch an interrupt to a 24-bit user callback
;
; Usage: IRQ_TRAMPOLINE vector_addr
;
;   vector_addr  — 3-byte page-two address holding the 24-bit JSL target
;
; PHA/PHX/PHY are 16-bit (ON16 is in effect) preserving full register state.
; Zero-check uses OFF16MEM/ON16MEM to read exactly 3 bytes without overlap
; into adjacent vectors. REP (ON16MEM) does not affect the Z flag, so BEQ
; correctly reflects the ORA result after the width is restored.
; Handler is entered with 16-bit registers and must end with RTL.
; =============================================================================

.macro IRQ_TRAMPOLINE vector_addr
        PHA
        PHX
        PHY

        ; Check if vector is installed — 8-bit reads to avoid overlap
        OFF16MEM                    ; 8-bit A for check
        LDA     vector_addr
        ORA     vector_addr+1
        ORA     vector_addr+2
        ON16MEM                     ; restore 16-bit A (Z flag unchanged by REP)
        BEQ     @return             ; zero = no handler installed

        .local @trampoline
        JSL     @trampoline         ; pushes 24-bit return, lands at @trampoline

        .local @return
@return:
        PLY
        PLX
        PLA
        RTI                         ; restore PBR, PC, P

@trampoline:
        JML     [vector_addr]       ; indirect 24-bit jump; handler RTLs back here
.endmacro

; =============================================================================
; hal_reset — cold start entry point
;
; Entered via JMP $8004 from the W65C265S masked ROM after it finds
; the "WDC" signature at $8000. Register state on entry:
;   native mode, A=8-bit (M=1), X/Y=16-bit (X=0), I=1, D=0, SP=$01FF
; =============================================================================

PUBLIC  hal_reset

        ; ── 1. Set CPU to a known state ───────────────────────────────────────
        SEI                         ; interrupts off (already set, be explicit)
        CLD                         ; decimal off (already clear, be explicit)
        ; Entry state: A=8-bit, X/Y=16-bit. Widen A to match X/Y.
        .a8
        .i16
        ON16MEM                     ; A -> 16-bit (X/Y already 16-bit)

        ; Set direct page to $0000
        LDA     #$0000
        TCD

        ; Set data bank register to $00
        PEA     $0000
        PLB                         ; discard high byte
        PLB                         ; DBR = $00

        ; ── 2. Init BCR ───────────────────────────────────────────────────────
        OFF16MEM                    ; 8-bit A only
        LDA     #BCR_NMIB_EN
        STA     BCR

        ; ── 3. Zero HAL zero-page variables ($00-$0F) ─────────────────────────
        ON16                        ; 16-bit A and X
        LDX     #$000E
        LDA     #$0000
:       STA     $00,X
        DEX
        DEX
        BPL     :-

        ; ── 4. Zero HAL page-two ($0200-$02FF) ───────────────────────────────
        LDX     #$00FE
        LDA     #$0000
:       STA     $0200,X
        DEX
        DEX
        BPL     :-

        ; ── 5. Write HAL version into page-two metadata ───────────────────────
        OFF16MEM                    ; 8-bit A
        LDA     #<HAL_VERSION
        STA     hal_ver_lo
        LDA     #>HAL_VERSION
        STA     hal_ver_hi

        ; ── 6. Init VIA ───────────────────────────────────────────────────────
        JSL     hal_via_init

        ; ── 7. Configure baud timer and init UART0 ───────────────────────────
        ON16X                       ; 16-bit X for baud divisor
        LDA     #HAL_TIMER3
        LDX     #BAUD_19200
        JSL     hal_baud_set_timer

        OFF16X                      ; 8-bit X
        LDA     #HAL_UART0
        LDX     #HAL_TIMER3
        JSL     hal_uart_set_timer

        LDA     #HAL_UART0
        JSL     hal_uart_init

        ; ── 8. Enable interrupts ──────────────────────────────────────────────
        CLI

        ; ── 9. Probe for Forth kernel at $8000 ───────────────────────────────
        JSR     hal_probe_forth

        ; ── 10. Minimal HAL idle loop ─────────────────────────────────────────
hal_idle:
        WAI
        BRA     hal_idle

ENDPUBLIC

; =============================================================================
; hal_probe_forth — check for Forth signature, JSL if found
;
; Forth lives somewhere in $8004–$BEEF alongside the HAL.
; FORTH_PROBE_ADDR and FORTH_ENTRY_ADDR are defined in hal_sfr.inc.
; The signature is "FTH\0" (4 bytes) at FORTH_PROBE_ADDR.
; Forth entry point is at FORTH_ENTRY_ADDR. Forth returns via RTL if it exits.
; =============================================================================

        .proc   hal_probe_forth

        OFF16MEM                    ; 8-bit A
        LDA     FORTH_PROBE_ADDR
        CMP     #FORTH_SIG_0
        BNE     @no_forth
        LDA     FORTH_PROBE_ADDR+1
        CMP     #FORTH_SIG_1
        BNE     @no_forth
        LDA     FORTH_PROBE_ADDR+2
        CMP     #FORTH_SIG_2
        BNE     @no_forth
        LDA     FORTH_PROBE_ADDR+3
        CMP     #FORTH_SIG_3
        BNE     @no_forth

        JSL     FORTH_ENTRY_ADDR    ; call Forth — RTL returns here if it exits

@no_forth:
        RTS

        .endproc

; =============================================================================
; hal_reset_emul — safety fallback if CPU enters emulation mode
;
; Normal boot enters via JMP $8004 from the masked ROM — already in native
; mode. This handler is a safety net in case something goes wrong and the
; CPU ends up in emulation mode unexpectedly.
; =============================================================================

PUBLIC  hal_reset_emul
        CLC
        XCE                         ; switch to native mode
        JMP     hal_reset
ENDPUBLIC

; =============================================================================
; hal_isr_unused — safe default for unimplemented interrupt vectors
; =============================================================================

PUBLIC  hal_isr_unused
        RTI
ENDPUBLIC

; =============================================================================
; hal_isr_irq — level IRQ dispatcher -> irq_vector
; =============================================================================

PUBLIC  hal_isr_irq
        ON16
        IRQ_TRAMPOLINE irq_vector
ENDPUBLIC

; =============================================================================
; hal_isr_nmi — NMI dispatcher -> nmi_vector
; =============================================================================

PUBLIC  hal_isr_nmi
        ON16
        IRQ_TRAMPOLINE nmi_vector
ENDPUBLIC

; =============================================================================
; hal_isr_brk — BRK dispatcher -> brk_vector
; =============================================================================

PUBLIC  hal_isr_brk
        ON16
        IRQ_TRAMPOLINE brk_vector
ENDPUBLIC

; =============================================================================
; hal_version — return HAL version
;   Out: A (16-bit) = HAL_VERSION ($0100 = v1.0)
; =============================================================================

PUBLIC  hal_version
        ON16MEM
        LDA     #HAL_VERSION
        RTL
ENDPUBLIC

; =============================================================================
; hal_set_brk — install a BRK interrupt callback
; hal_set_isr — install an IRQ callback
; hal_set_nmi — install an NMI callback
;
;   In:  X (16-bit) = handler address (low word)
;        Y (8-bit)  = handler bank byte
;
; Stores the 24-bit JSL target into the appropriate page-two vector.
; Pass X=0, Y=0 to clear (disable) a handler.
;
; The vectors are read by IRQ_TRAMPOLINE in the ISR dispatchers:
;   brk_vector  $0200  — read by hal_isr_brk
;   irq_vector  $0203  — read by hal_isr_irq
;   nmi_vector  $0206  — read by hal_isr_nmi
; =============================================================================

PUBLIC  hal_set_brk
        ON16X                       ; 16-bit X = handler address
        STX     brk_vector          ; store low word
        OFF16X
        STY     brk_vector+2        ; store bank byte
        RTL
ENDPUBLIC

PUBLIC  hal_set_isr
        ON16X
        STX     irq_vector
        OFF16X
        STY     irq_vector+2
        RTL
ENDPUBLIC

PUBLIC  hal_set_nmi
        ON16X
        STX     nmi_vector
        OFF16X
        STY     nmi_vector+2
        RTL
ENDPUBLIC
