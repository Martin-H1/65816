; =============================================================================
; hal_init.asm -- Boot sequence and ISR dispatchers
;
; This file provides:
;   - hal_reset        -- HAL entry point (entered via JMP $8004 from masked ROM)
;   - hal_reset_emul   -- safety fallback if CPU enters emulation mode
;   - hal_isr_unused   -- safe default for unimplemented interrupt vectors
;   - hal_isr_irq      -- IRQ dispatcher -> irq_vector callback
;   - hal_isr_nmi      -- NMI dispatcher -> nmi_vector callback
;   - hal_isr_brk      -- BRK dispatcher -> brk_vector callback
;   - hal_version      -- returns HAL_VERSION constant from EEPROM
;   - hal_set_brk      -- install BRK callback
;   - hal_set_isr      -- install IRQ callback
;   - hal_set_nmi      -- install NMI callback
;   - hal_echo         -- UART0 echo loop (default if no Forth found)
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

        ; Imports from other HAL modules
        .import hal_via_init
        .import hal_uart_init
        .import hal_uart_set_timer
        .import hal_baud_set_timer
        .import hal_isr_cop
        .import hal_uart_putc
        .import hal_uart_getc

        .segment "HAL_CODE"

; =============================================================================
; IRQ_TRAMPOLINE -- dispatch an interrupt to a 24-bit user callback
;
; Saves full 16-bit A/X/Y. Zero-check uses 8-bit reads to avoid overlap
; into adjacent vectors. ON16MEM before BEQ preserves Z flag (REP does
; not affect flags) so PLY/PLX/PLA restore correct 16-bit values on both
; the taken and not-taken paths.
; =============================================================================

.macro IRQ_TRAMPOLINE vector_addr
        PHA
        PHX
        PHY

        OFF16MEM                    ; 8-bit reads for exact 3-byte check
        LDA     vector_addr
        ORA     vector_addr+1
        ORA     vector_addr+2
        ON16MEM                     ; restore 16-bit A (Z flag unchanged by REP)
        BEQ     @return             ; zero = no handler installed

        .local @trampoline
        JSL     @trampoline

        .local @return
@return:
        PLY
        PLX
        PLA
        RTI

@trampoline:
        JML     [vector_addr]       ; handler RTLs back here
.endmacro

; =============================================================================
; SET_VECTOR -- store a 24-bit callback address into a page-two vector
;
;   In:  X (16-bit) = handler address low word
;        Y (8-bit)  = handler bank byte
;
; PHP/PLP preserves caller's register width across the operation.
; =============================================================================

.macro SET_VECTOR vector_addr
        PHP
        ON16X
        STX     vector_addr
        OFF16X
        STY     vector_addr+2
        PLP
        RTL
.endmacro

; =============================================================================
; hal_reset -- HAL entry point
;
; Entered via JMP $8004 from the W65C265S masked ROM after "WDC" signature
; is found at $8000. Register state on entry:
;   native mode, A=8-bit (M=1), X/Y=16-bit (X=0), I=1, D=0, SP=$01FF
; =============================================================================

PUBLIC  hal_reset

        ; ── 1. Set CPU to a known state ───────────────────────────────────────
        SEI                         ; interrupts off
        CLD                         ; decimal off
        ; Entry: A=8-bit, X/Y=16-bit. Widen A only.
        .a8
        .i16
        ON16MEM                     ; A -> 16-bit

        ; Set direct page to $0000
        LDA     #$0000
        TCD

        ; Set data bank register to $00
        PEA     $0000
        PLB                         ; discard high byte
        PLB                         ; DBR = $00

        ; ── 2. Init BCR ───────────────────────────────────────────────────────
        OFF16MEM                    ; 8-bit A
        LDA     #BCR_NMIB_EN
        TSB     BCR                 ; set NMI enable bit, preserve others

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

        ; ── 5. Init VIA ───────────────────────────────────────────────────────
        JSL     hal_via_init

        ; ── 6. Configure baud timer and init UART0 ───────────────────────────
        ON16X                       ; 16-bit X for baud divisor
        OFF16MEM                    ; 8-bit A for channel/timer args
        LDA     #HAL_TIMER3
        LDX     #BAUD_19200
        JSL     hal_baud_set_timer

        OFF16X                      ; 8-bit X
        LDA     #HAL_UART0
        LDX     #HAL_TIMER3
        JSL     hal_uart_set_timer

        LDA     #HAL_UART0
        JSL     hal_uart_init

        ; ── 7. Enable interrupts ──────────────────────────────────────────────
        CLI

        ; ── 8. Probe for Forth kernel ─────────────────────────────────────────
        JSR     hal_probe_forth     ; returns here if no Forth found

        ; ── 9. No Forth found -- run echo loop as fallback test ───────────────
        JSR     hal_echo

        ; Should not return, but idle if it does
hal_idle:
        WAI
        BRA     hal_idle

ENDPUBLIC

; =============================================================================
; hal_probe_forth -- check for Forth signature, JSL if found
;
; Checks FORTH_PROBE_ADDR for "FTH\0". If found, JSLs to FORTH_ENTRY_ADDR.
; Forth returns via RTL if it exits. If no Forth found, returns via RTS.
; =============================================================================

        .proc   hal_probe_forth

        OFF16MEM
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

        JSL     FORTH_ENTRY_ADDR

@no_forth:
        RTS

        .endproc

; =============================================================================
; hal_echo -- UART0 echo loop (fallback when no Forth is found)
;
; Receives bytes on UART0 and echoes them back. Translates CR -> CR+LF.
; This exercises buffered RX/TX, ring buffers, and ISRs.
; Never returns.
; =============================================================================

        .proc   hal_echo

@loop:
        OFF16MEM                    ; 8-bit A for channel arg
        LDA     #HAL_UART0
        JSL     hal_uart_getc       ; blocking -- A = received byte on return

        CMP     #$0D                ; CR?
        BNE     @send

        ; Send CR + LF
        LDX     #$0D
        LDA     #HAL_UART0
        JSL     hal_uart_putc
        LDX     #$0A
        LDA     #HAL_UART0
        JSL     hal_uart_putc
        BRA     @loop

@send:
        TAX                         ; X = byte to echo
        LDA     #HAL_UART0
        JSL     hal_uart_putc
        BRA     @loop

        .endproc

; =============================================================================
; hal_reset_emul -- safety fallback if CPU enters emulation mode
; =============================================================================

PUBLIC  hal_reset_emul
        CLC
        XCE                         ; switch to native mode
        JMP     hal_reset
ENDPUBLIC

; =============================================================================
; hal_isr_unused -- safe default for unimplemented interrupt vectors
; =============================================================================

PUBLIC  hal_isr_unused
        RTI
ENDPUBLIC

; =============================================================================
; hal_isr_irq -- level IRQ dispatcher -> irq_vector
; =============================================================================

PUBLIC  hal_isr_irq
        ON16
        IRQ_TRAMPOLINE irq_vector
ENDPUBLIC

; =============================================================================
; hal_isr_nmi -- NMI dispatcher -> nmi_vector
; =============================================================================

PUBLIC  hal_isr_nmi
        ON16
        IRQ_TRAMPOLINE nmi_vector
ENDPUBLIC

; =============================================================================
; hal_isr_brk -- BRK dispatcher -> brk_vector
; =============================================================================

PUBLIC  hal_isr_brk
        ON16
        IRQ_TRAMPOLINE brk_vector
ENDPUBLIC

; =============================================================================
; hal_version -- return HAL version from EEPROM constant
;   Out: A (16-bit) = HAL_VERSION ($0100 = v1.0)
; =============================================================================

PUBLIC  hal_version
        ON16MEM
        LDA     #HAL_VERSION
        RTL
ENDPUBLIC

; =============================================================================
; hal_set_brk / hal_set_isr / hal_set_nmi
;
;   In:  X (16-bit) = handler address low word
;        Y (8-bit)  = handler bank byte
;
; PHP/PLP in SET_VECTOR preserves caller's register width.
; Pass X=0, Y=0 to clear (disable) a handler.
; =============================================================================

PUBLIC  hal_set_brk
        SET_VECTOR brk_vector
ENDPUBLIC

PUBLIC  hal_set_isr
        SET_VECTOR irq_vector
ENDPUBLIC

PUBLIC  hal_set_nmi
        SET_VECTOR nmi_vector
ENDPUBLIC
