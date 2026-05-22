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
;   - hal_baud_set_timer, hal_uart_set_timer, hal_uart_init
;   - hal_uart_putc, hal_uart_getc, hal_uart_puts, hal_uart_status
;   - hal_uart_rx_ready, hal_isr_uart0_rx, hal_isr_uart0_tx
;   - hal_isr_uart1_rx, hal_isr_uart1_tx
;   - hal_via_init, hal_via_set_dir, hal_via_write, hal_via_read
;   - hal_set_brk, hal_set_isr, hal_set_nmi
;
; All stubs are .proc blocks that immediately RTL (or RTI for ISRs).
; Replace each stub with the real implementation as subsystems are built.
; =============================================================================

        .setcpu "65816"
        .smart  on

        .include "hal_sfr.inc"

        ; Page-two variables (defined in hal_page2.asm)
        .globalzp hal_tmp0, hal_tmp1, hal_tmp_ptr, hal_flags, hal_errflg

        .global brk_vector, irq_vector, nmi_vector
        .global u0_rx_buf, u0_rx_head, u0_rx_tail
        .global u0_tx_buf, u0_tx_head, u0_tx_tail
        .global u1_rx_buf, u1_rx_head, u1_rx_tail
        .global u1_tx_buf, u1_tx_head, u1_tx_tail
        .global via_ddra_shad, via_ddrb_shad
        .global hal_ver_lo, hal_ver_hi

        .segment "HAL_CODE"

; =============================================================================
; hal_reset — cold start entry point
;
; The native-mode RESET vector is not in the W65C265S native vector table —
; RESET always vectors through the emulation-mode table at $FFFC/$FFFD.
; hal_reset_emul (below) switches to native mode and jumps here.
;
; On entry: CPU is in native mode, all registers 8-bit (M=1, X=1 after XCE),
;           interrupt disable set (I=1), decimal clear (D=0).
; =============================================================================

        .export hal_reset
        .proc   hal_reset

        ; ── 1. Set CPU to a known state ──────────────────────────────────────
        SEI                         ; interrupts off (already set by reset, be explicit)
        CLD                         ; decimal mode off
        REP     #$30                ; 16-bit A and X/Y
        .a16
        .i16

        ; Set direct page to $0000 (default ZP access for HAL variables)
        LDA     #$0000
        TCD

        ; Set data bank to $00 (EEPROM and SRAM are all in bank 0)
        LDA     #$0000
        XBA                         ; swap: A low byte → A high byte
        PHA
        PLB                         ; pull bank byte: DBR = $00

        ; Stack is already at $01FF (65816 reset default for native mode)

        ; ── 2. Init BCR — internal ROM, normal (non-ICE) mode ────────────────
        SEP     #$20
        .a8
        ; BCR reset value depends on BE pin state; ensure sane defaults.
        ; Clear ICE bit, clear watchdog, keep internal ROM (BCR7=0).
        LDA     #BCR_NMIB_EN        ; enable NMI pin (optional — adjust for board)
        STA     BCR

        ; ── 3. Zero HAL zero-page variables ($00–$0F) ─────────────────────────
        REP     #$30
        .a16
        .i16
        LDX     #$000F
        LDA     #$0000
:       STA     $00,X
        DEX
        DEX
        BPL     :-                  ; note: X is 16-bit; stops at $0000

        ; ── 4. Zero HAL page-two ($0200–$02FF) ───────────────────────────────
        LDX     #$00FE
        LDA     #$0000
:       STA     $0200,X
        DEX
        DEX
        BPL     :-

        ; ── 5. Write HAL version into page-two metadata ───────────────────────
        SEP     #$20
        .a8
        LDA     #<HAL_VERSION
        STA     hal_ver_lo
        LDA     #>HAL_VERSION
        STA     hal_ver_hi

        ; ── 6. Init VIA ───────────────────────────────────────────────────────
        JSR     hal_via_init        ; same bank — JSR is fine

        ; ── 7. Configure baud timer and init UART0 ───────────────────────────
        ; T3 → 19200 baud; bind UART0 and UART1 to T3
        REP     #$10
        .i16
        LDA     #HAL_TIMER3
        LDX     #BAUD_19200
        JSR     hal_baud_set_timer

        SEP     #$10
        .i8
        LDA     #HAL_UART0
        LDX     #HAL_TIMER3
        JSR     hal_uart_set_timer

        LDA     #HAL_UART0
        JSR     hal_uart_init

        ; ── 8. Enable interrupts ──────────────────────────────────────────────
        ; UART RX interrupts are enabled by hal_uart_init.
        ; General IRQ enable last.
        CLI

        ; ── 9. Probe for Forth kernel at $8000 ───────────────────────────────
        JSR     hal_probe_forth     ; does not return if Forth is present

        ; ── 10. Fall through to minimal HAL idle loop ─────────────────────────
        ; (Replace with a monitor/prompt when that subsystem is built)
hal_idle:
        WAI                         ; wait for interrupt
        BRA     hal_idle

        .endproc

; =============================================================================
; hal_probe_forth — check for Forth signature at $8000, JSL if found
; =============================================================================

        .proc   hal_probe_forth

        SEP     #$20
        .a8
        LDA     $8000
        CMP     #FORTH_SIG_0
        BNE     :+
        LDA     $8001
        CMP     #FORTH_SIG_1
        BNE     :+
        LDA     $8002
        CMP     #FORTH_SIG_2
        BNE     :+
        LDA     $8003
        CMP     #FORTH_SIG_3
        BNE     :+

        ; Valid signature — Forth entry point is at $8004
        ; JSL is used so Forth can RTL back if it ever exits
        JSL     $008004             ; cross-bank call, 4 bytes
        ; If Forth returns, fall through to caller (hal_reset → hal_idle)

:       RTS

        .endproc

; =============================================================================
; hal_reset_emul — emulation-mode RESET handler ($FFFC vector)
;
; The 65816 always resets into emulation mode. This routine immediately
; switches to native mode and jumps to hal_reset.
; =============================================================================

        .export hal_reset_emul
        .proc   hal_reset_emul

        ; In emulation mode on entry. Switch to native mode.
        CLC
        XCE                         ; emulation→native; M and X set to 1 by hardware
        JMP     hal_reset           ; native mode from here

        .endproc

; =============================================================================
; hal_isr_unused — default handler for unimplemented vectors
;
; Clears the interrupt by reading the UIFR/TIFR (which doesn't hurt for
; unrelated sources) and RTIs. Prevents interrupt storms on stray vectors.
; =============================================================================

        .export hal_isr_unused
        .proc   hal_isr_unused

        ; No register save needed — RTI restores P, PC, PBR
        RTI

        .endproc

.macro JSL_INDIRECT vector_addr
	REP     #$20
        LDA     vector_addr         ; low word of target
	DEC     A                   ; RTL adds 1, so pre-decrement
	PHA                         ; push low word

	SEP     #$20
        .a8
        LDA     vector_addr+2       ; bank byte
	PHA                         ; push bank byte

        REP     #$20
        .a16
	RTL                         ; "returns" to IRQ target address
.endmacro

; =============================================================================
; hal_isr_irq — level IRQ dispatcher
;
; If user irq_vector is installed (non-zero), calls it via RTL to that address.
; User handler must end with RTL.
; =============================================================================

        .export hal_isr_irq
        .proc   hal_isr_irq

        REP     #$30
        .a16
        .i16
        PHA
        PHX

        ; Check if irq_vector is non-zero
        LDA     irq_vector          ; low word
        ORA     irq_vector+2        ; (second byte of 24-bit addr + padding)
        BEQ     :+                  ; zero → no handler, skip

	; 65816 has no indirect JSL, use macro to do the RTL trick
	JSL_INDIRECT irq_vector

:       PLX
        PLA
	RTI

        .endproc

; =============================================================================
; hal_isr_nmi — NMI dispatcher → nmi_vector
; =============================================================================

        .export hal_isr_nmi
        .proc   hal_isr_nmi

        REP     #$30
        .a16
        .i16
        PHA
        PHX

        LDA     nmi_vector
        ORA     nmi_vector+2
        BEQ     :+

	; 65816 has no indirect JSL, use macro to do the RTL trick
	JSL_INDIRECT nmi_vector

:       PLX
        PLA
        RTI

        .endproc

; =============================================================================
; hal_isr_brk — BRK dispatcher → brk_vector
;
; On entry the CPU has pushed PBR, PCH, PCL, P (native mode BRK frame).
; The BRK operand byte is at [stacked_PC - 1].
; If no brk_vector is installed, RTIs silently.
; =============================================================================

        .export hal_isr_brk
        .proc   hal_isr_brk

        REP     #$30
        .a16
        .i16
        PHA
        PHX

        LDA     brk_vector
        ORA     brk_vector+2
        BEQ     :+

	; 65816 has no indirect JSL, use macro to do the RTL trick
	JSL_INDIRECT brk_vector

:       PLX
        PLA
        RTI

        .endproc

; =============================================================================
; hal_isr_cop — COP dispatcher
;
; COP #n pushes PBR, PC, P (native mode). The operand byte n is at
; [stacked PC - 1] in the caller's bank.
;
; This stub RTIs immediately — full dispatch table to be implemented
; when the COP subsystem is built.
; =============================================================================

        .export hal_isr_cop
        .proc   hal_isr_cop

        ; TODO: read COP operand, index cop_fn_table, call handler, RTI
        RTI

        .endproc

; =============================================================================
; hal_version — return HAL version
;   Out: A (16-bit) = HAL_VERSION ($0100 = v1.0)
; =============================================================================

        .export hal_version
        .proc   hal_version

        REP     #$20
        .a16
        LDA     #HAL_VERSION
        RTL

        .endproc

; =============================================================================
; UART stubs — replace with real implementations in hal_uart.asm
; =============================================================================

        .export hal_baud_set_timer
        .proc   hal_baud_set_timer
        RTL
        .endproc

        .export hal_uart_set_timer
        .proc   hal_uart_set_timer
        RTL
        .endproc

        .export hal_uart_init
        .proc   hal_uart_init
        RTL
        .endproc

        .export hal_uart_putc
        .proc   hal_uart_putc
        RTL
        .endproc

        .export hal_uart_getc
        .proc   hal_uart_getc
        RTL
        .endproc

        .export hal_uart_puts
        .proc   hal_uart_puts
        RTL
        .endproc

        .export hal_uart_status
        .proc   hal_uart_status
        RTL
        .endproc

        .export hal_uart_rx_ready
        .proc   hal_uart_rx_ready
        RTL
        .endproc

        .export hal_isr_uart0_rx
        .proc   hal_isr_uart0_rx
        RTI
        .endproc

        .export hal_isr_uart0_tx
        .proc   hal_isr_uart0_tx
        RTI
        .endproc

        .export hal_isr_uart1_rx
        .proc   hal_isr_uart1_rx
        RTI
        .endproc

        .export hal_isr_uart1_tx
        .proc   hal_isr_uart1_tx
        RTI
        .endproc

; =============================================================================
; VIA stubs — replace with real implementations in hal_via.asm
; =============================================================================

        .export hal_via_init
        .proc   hal_via_init
        RTS                         ; called via JSR from hal_reset
        .endproc

        .export hal_via_set_dir
        .proc   hal_via_set_dir
        RTL
        .endproc

        .export hal_via_write
        .proc   hal_via_write
        RTL
        .endproc

        .export hal_via_read
        .proc   hal_via_read
        RTL
        .endproc

; =============================================================================
; Interrupt callback API stubs
; =============================================================================

        .export hal_set_brk
        .proc   hal_set_brk
        RTL
        .endproc

        .export hal_set_isr
        .proc   hal_set_isr
        RTL
        .endproc

        .export hal_set_nmi
        .proc   hal_set_nmi
        RTL
        .endproc
