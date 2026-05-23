; =============================================================================
; hal_init.asm — Boot sequence and empty/stub implementations
;
; This file provides:
;   - hal_reset        — native-mode reset entry point (cold start)
;   - hal_reset_emul   — emulation-mode reset (switches to native, jumps above)
;   - hal_isr_unused   — safe default for unimplemented interrupt vectors
;   - hal_isr_irq      — IRQ dispatcher → irq_vector callback
;   - hal_isr_nmi      — NMI dispatcher → nmi_vector callback
;   - hal_isr_brk      — BRK dispatcher → brk_vector callback
;   - hal_isr_cop      — COP dispatcher (by operand byte)
;   - hal_version      — returns HAL_VERSION in A
;
; Stub implementations for subsystems not yet written:
;   - hal_set_brk, hal_set_isr, hal_set_nmi
;
; All stubs are .proc blocks that immediately RTL (or RTI for ISRs).
; Replace each stub with the real implementation as subsystems are built.
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

        .segment "HAL_CODE"

; =============================================================================
; IRQ_TRAMPOLINE — dispatch an interrupt to a 24-bit user callback
;
; Usage: IRQ_TRAMPOLINE vector_addr
;
;   vector_addr  — 3-byte page-two address holding the 24-bit JSL target
;                  (e.g. irq_vector, nmi_vector, brk_vector)
;
; Saves A, X, Y. Checks if the vector is non-zero before calling.
; Calls the handler via JML [vector_addr] (indirect 24-bit jump through
; a bank-zero pointer). Handler must end with RTL.
; Returns via RTI, restoring the interrupted context.
;
; Note: JML [addr] always reads the pointer from bank $00, which is
; correct since all three vectors live in the HAL private page at $02xx.
; =============================================================================

.macro IRQ_TRAMPOLINE vector_addr
        PHA
        PHX
        PHY

        LDA     vector_addr         ; low word of this vector
        ORA     vector_addr+2       ; bank byte of this vector
        BEQ     @return             ; zero = no handler installed

        .local @trampoline
        JSL     @trampoline         ; pushes 24-bit return, lands at @trampoline

        .local @return
@return:
        PLY
        PLX
        PLA
        RTI                         ; restore PBR, PC, P — back to interrupted code

@trampoline:
        JML     [vector_addr]       ; indirect 24-bit jump; handler RTLs back here
.endmacro

; =============================================================================
; hal_reset — cold start entry point
;
; RESET always vectors through the emulation-mode table ($FFFC/$FFFD).
; hal_reset_emul switches to native mode and jumps here.
;
; On entry: native mode, M=1, X=1, I=1, D=0.
; =============================================================================

PUBLIC  hal_reset

        ; ── 1. Set CPU to a known state ───────────────────────────────────────
        SEI                         ; interrupts off (explicit — already set by reset)
        CLD                         ; decimal mode off
        ON16                        ; 16-bit A and X/Y

        ; Set direct page to $0000
        LDA     #$0000
        TCD

        ; Set data bank register to $00
        LDA     #$0000
        XBA                         ; move $00 to high byte of A
        PHA
        PLB                         ; DBR = $00

        ; ── 2. Init BCR ───────────────────────────────────────────────────────
        OFF16MEM                    ; 8-bit A only
        LDA     #BCR_NMIB_EN
        STA     BCR

        ; ── 3. Zero HAL zero-page variables ($00–$0F) ─────────────────────────
        ON16                        ; 16-bit A and X
        LDX     #$000E              ; step by 2, covers $00–$0E then $00
        LDA     #$0000
:       STA     $00,X
        DEX
        DEX
        BPL     :-

        ; ── 4. Zero HAL page-two ($0200–$02FF) ───────────────────────────────
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
        ; T3 → 19200 baud; bind UART0 to T3 then initialise it
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
        JSR     hal_probe_forth     ; returns here if no Forth found

        ; ── 10. Minimal HAL idle loop ─────────────────────────────────────────
        ; (Replace with a monitor/prompt when that subsystem is built)
hal_idle:
        WAI
        BRA     hal_idle

ENDPUBLIC

; =============================================================================
; hal_probe_forth — check for Forth signature at $8000, JSL if found
;
; Signature: 4 bytes "FTH\0" at $00:8000.
; Entry point: $00:8004. Forth returns via RTL if it ever exits.
; =============================================================================

        .proc   hal_probe_forth

        OFF16MEM                    ; 8-bit A
        LDA     $8000
        CMP     #FORTH_SIG_0
        BNE     @no_forth
        LDA     $8001
        CMP     #FORTH_SIG_1
        BNE     @no_forth
        LDA     $8002
        CMP     #FORTH_SIG_2
        BNE     @no_forth
        LDA     $8003
        CMP     #FORTH_SIG_3
        BNE     @no_forth

        JSL     $008004             ; call Forth — RTL returns here if it exits

@no_forth:
        RTS

        .endproc

; =============================================================================
; hal_reset_emul — emulation-mode RESET handler ($FFFC/$FFFD vector)
;
; The 65816 always resets into emulation mode. Switch to native and
; jump to hal_reset.
; =============================================================================

PUBLIC  hal_reset_emul

        CLC
        XCE                         ; switch to native mode
        JMP     hal_reset

ENDPUBLIC

; =============================================================================
; hal_isr_unused — safe default for unimplemented interrupt vectors
;
; RTIs immediately. Prevents lockup on spurious interrupts.
; =============================================================================

PUBLIC  hal_isr_unused
        RTI
ENDPUBLIC

; =============================================================================
; hal_isr_irq — level IRQ dispatcher → irq_vector
; =============================================================================

PUBLIC  hal_isr_irq
        ON16
        IRQ_TRAMPOLINE irq_vector
ENDPUBLIC

; =============================================================================
; hal_isr_nmi — NMI dispatcher → nmi_vector
; =============================================================================

PUBLIC  hal_isr_nmi
        ON16
        IRQ_TRAMPOLINE nmi_vector
ENDPUBLIC

; =============================================================================
; hal_isr_brk — BRK dispatcher → brk_vector
; =============================================================================

PUBLIC  hal_isr_brk
        ON16
        IRQ_TRAMPOLINE brk_vector
ENDPUBLIC

; =============================================================================
; hal_isr_cop — COP dispatcher
;
; TODO: read COP operand byte, index cop_fn_table, call handler, RTI.
; Stub RTIs immediately.
; =============================================================================

PUBLIC  hal_isr_cop
        RTI
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
; The vectors are read by the IRQ_TRAMPOLINE macro in the ISR dispatchers:
;   brk_vector  $0200  — read by hal_isr_brk
;   irq_vector  $0203  — read by hal_isr_irq
;   nmi_vector  $0206  — read by hal_isr_nmi
; =============================================================================

PUBLIC  hal_set_brk
        ON16X                   ; 16-bit X = handler address
        STX     brk_vector      ; store low word
        OFF16X
        .i8
        TYA                     ; A = bank byte
        STA     brk_vector+2    ; store bank byte
        RTL
ENDPUBLIC

PUBLIC  hal_set_isr
        ON16X
        STX     irq_vector
        OFF16X
        .i8
        TYA
        STA     irq_vector+2
        RTL
ENDPUBLIC

PUBLIC  hal_set_nmi
        ON16X
        STX     nmi_vector
        OFF16X
        .i8
        TYA
        STA     nmi_vector+2
        RTL
ENDPUBLIC
