; =============================================================================
; hal_uart.asm — W65C265S UART driver
;
; Provides buffered, interrupt-driven I/O for UART0 and UART1.
;
; Public API (via jump table):
;   hal_baud_set_timer  — configure T3 or T4 baud rate timer
;   hal_uart_set_timer  — bind a UART channel to T3 or T4
;   hal_uart_init       — enable a UART channel (8N1, RX interrupt on)
;   hal_uart_putc       — enqueue a byte to TX ring (non-blocking)
;   hal_uart_getc       — dequeue a byte from RX ring (blocking)
;   hal_uart_puts       — send a null-terminated string
;   hal_uart_status     — return raw ACSRx value
;   hal_uart_rx_ready   — test if RX ring has data (Z clear = available)
;
; Interrupt handlers (called from vector table):
;   hal_isr_uart0_rx    — UART0 RX: enqueue ARTD0 -> u0_rx_buf
;   hal_isr_uart0_tx    — UART0 TX: dequeue u0_tx_buf -> ARTD0
;   hal_isr_uart1_rx    — UART1 RX: enqueue ARTD1 -> u1_rx_buf
;   hal_isr_uart1_tx    — UART1 TX: dequeue u1_tx_buf -> ARTD1
;
; Ring buffer design:
;   RX: 64 bytes, power-of-2, head/tail wrap with AND #$3F
;   TX: 32 bytes, power-of-2, head/tail wrap with AND #$1F
;   head = next write index (ISR for RX, putc for TX)
;   tail = next read index  (getc for RX, ISR for TX)
;   Buffer empty: head == tail
;   Buffer full:  (head + 1) & mask == tail
;
; Calling convention:
;   A (8-bit)   first argument / return value
;   X (8 or 16-bit, as noted) second argument
;   A, X, Y     caller-saved
;   D, B        HAL saves and restores
; =============================================================================

        .p816
        .smart  off

        .include "macros.inc"
        .include "hal_sfr.inc"

        ; Page-two ring buffer variables (defined in hal_page2.asm)
        .global u0_rx_buf, u0_rx_head, u0_rx_tail
        .global u0_tx_buf, u0_tx_head, u0_tx_tail
        .global u1_rx_buf, u1_rx_head, u1_rx_tail
        .global u1_tx_buf, u1_tx_head, u1_tx_tail

        .global hal_uart_putc   ; forward ref for hal_uart_puts

        .segment "HAL_CODE"

; =============================================================================
; hal_baud_set_timer -- configure T3 or T4 for a baud rate
;
;   In:  A (8-bit)  = timer select: HAL_TIMER3 (0) or HAL_TIMER4 (1)
;        X (16-bit) = baud divisor (BAUD_19200 etc. from hal_sfr.inc)
;
; Writes the 16-bit divisor to TnLL/TnLH and enables the timer in TER.
; NOTE: affects ALL UARTs currently bound to this timer.
; =============================================================================

PUBLIC  hal_baud_set_timer

        OFF16MEM                ; 8-bit A
        ON16X                   ; 16-bit X (baud divisor)

        CMP     #HAL_TIMER4
        BEQ     @timer4

@timer3:
        STX     T3LL            ; 16-bit STX: low byte -> T3LL, high byte -> T3LH
        OFF16X
        .i8
        LDA     TER
        ORA     #T3FLG
        STA     TER             ; enable T3
        RTL

@timer4:
        STX     T4LL
        OFF16X
        .i8
        LDA     TER
        ORA     #T4FLG
        STA     TER             ; enable T4
        RTL

ENDPUBLIC

; =============================================================================
; hal_uart_set_timer -- bind a UART channel to T3 or T4
;
;   In:  A (8-bit) = UART channel (HAL_UART0-HAL_UART3)
;        X (8-bit) = timer select: HAL_TIMER3 (0) or HAL_TIMER4 (1)
;
; Read-modify-writes TCR. Setting the channel's bit selects T4;
; clearing it selects T3.
; =============================================================================

PUBLIC  hal_uart_set_timer

        OFF16                   ; 8-bit A and X

        TAY                     ; Y = channel index
        LDA     tcr_mask_table,Y ; A = TCR bit mask for this channel

        CPX     #HAL_TIMER4
        BEQ     @select_t4

@select_t3:
        EOR     #$FF            ; invert to get AND mask (clears the bit)
        AND     TCR
        STA     TCR
        RTL

@select_t4:
        ORA     TCR             ; set the bit -> selects T4
        STA     TCR
        RTL

ENDPUBLIC

; TCR T4-select bit masks per UART channel
tcr_mask_table:
        .byte   TCR_UART0_T4    ; channel 0 -> bit 4
        .byte   TCR_UART1_T4    ; channel 1 -> bit 5
        .byte   TCR_UART2_T4    ; channel 2 -> bit 6
        .byte   TCR_UART3_T4    ; channel 3 -> bit 7

; =============================================================================
; hal_uart_init -- initialise a UART channel for 8N1, enable RX interrupt
;
;   In:  A (8-bit) = UART channel (HAL_UART0-HAL_UART3)
;
; Writes ACSR_8N1 (SON | ACSR_8BIT | ACSR_RX_EN) to ACSRx.
; Enables the channel's RX interrupt bit in UIER.
; TX interrupt is NOT enabled here -- hal_uart_putc enables it on demand.
; =============================================================================

PUBLIC  hal_uart_init

        OFF16                   ; 8-bit A and X

        TAY                     ; Y = channel
        LDA     uier_rx_table,Y
        ORA     UIER
        STA     UIER            ; enable RX interrupt for this channel

        CPY     #0
        BEQ     @ch0
        CPY     #1
        BEQ     @ch1
        CPY     #2
        BEQ     @ch2
@ch3:   LDA     #ACSR_8N1
        STA     ACSR3
        RTL
@ch2:   LDA     #ACSR_8N1
        STA     ACSR2
        RTL
@ch1:   LDA     #ACSR_8N1
        STA     ACSR1
        RTL
@ch0:   LDA     #ACSR_8N1
        STA     ACSR0
        RTL

ENDPUBLIC

; UIER RX and TX enable bits per channel (same bit layout as UIFR)
uier_rx_table:
        .byte   UART0R
        .byte   UART1R
        .byte   UART2R
        .byte   UART3R

uier_tx_table:
        .byte   UART0T
        .byte   UART1T
        .byte   UART2T
        .byte   UART3T

; =============================================================================
; hal_uart_putc -- enqueue a byte to the TX ring buffer
;
;   In:  A (8-bit) = UART channel (0 or 1)
;        X (8-bit) = byte to transmit
;
; Enqueues the byte and enables the TX interrupt so the ISR drains it.
; Spins briefly if the TX ring is full (rare at normal baud rates).
; =============================================================================

PUBLIC  hal_uart_putc

        OFF16                   ; 8-bit A and X

        CMP     #1
        BEQ     @ch1

@ch0:
@ch0_full:
        LDA     u0_tx_head
        INC     A
        AND     #$1F
        CMP     u0_tx_tail
        BEQ     @ch0_full       ; spin until ISR drains a slot

        LDA     u0_tx_head      ; A = current head index
        TAY                     ; Y = head index
        TXA                     ; A = byte to send
        STA     u0_tx_buf,Y     ; store at head

        TYA                     ; A = old head
        INC     A
        AND     #$1F
        STA     u0_tx_head      ; advance head

        LDA     UIER
        ORA     #UART0T
        STA     UIER            ; enable UART0 TX interrupt
        RTL

@ch1:
@ch1_full:
        LDA     u1_tx_head
        INC     A
        AND     #$1F
        CMP     u1_tx_tail
        BEQ     @ch1_full

        LDA     u1_tx_head
        TAY
        TXA
        STA     u1_tx_buf,Y

        TYA
        INC     A
        AND     #$1F
        STA     u1_tx_head

        LDA     UIER
        ORA     #UART1T
        STA     UIER
        RTL

ENDPUBLIC

; =============================================================================
; hal_uart_getc -- dequeue a byte from the RX ring buffer (blocking)
;
;   In:  A (8-bit) = UART channel (0 or 1)
;   Out: A (8-bit) = received byte
;        Carry clear (future: carry set on timeout)
; =============================================================================

PUBLIC  hal_uart_getc

        OFF16                   ; 8-bit A and X

        CMP     #1
        BEQ     @ch1

@ch0:
@ch0_wait:
        LDA     u0_rx_head
        CMP     u0_rx_tail
        BEQ     @ch0_wait       ; spin until data arrives

        LDX     u0_rx_tail      ; X = tail index
        LDA     u0_rx_buf,X     ; A = received byte

        TXA
        INC     A
        AND     #$3F
        STA     u0_rx_tail      ; advance tail

        CLC
        RTL

@ch1:
@ch1_wait:
        LDA     u1_rx_head
        CMP     u1_rx_tail
        BEQ     @ch1_wait

        LDX     u1_rx_tail
        LDA     u1_rx_buf,X

        TXA
        INC     A
        AND     #$3F
        STA     u1_rx_tail

        CLC
        RTL

ENDPUBLIC

; =============================================================================
; hal_uart_puts -- send a null-terminated string
;
;   In:  A (8-bit)  = UART channel
;        X (16-bit) = string address
;        Y (8-bit)  = string bank byte
;
; Translates LF ($0A) -> CR+LF ($0D $0A).
;
; Uses a PHD/TCD stack frame to hold locals, avoiding register juggling.
;
; Stack frame layout (S grows downward, frame built before TCD):
;   1,S  LOC_CHAN  channel (1 byte)
;   2,S  LOC_BANK  string bank (1 byte)
;   3,S  LOC_PTR   string pointer (2 bytes)
;   5,S  saved D   caller's direct page (2 bytes)  <- PHD
;   7,S  RTL addr  24-bit return address (3 bytes)  <- JSL
; =============================================================================

LOC_CHAN  = 1
LOC_BANK  = 2
LOC_PTR   = 3

PUBLIC  hal_uart_puts

        ; On entry: A=channel (8-bit), X=string addr (16-bit), Y=bank (8-bit)
        OFF16MEM                ; 8-bit A
        OFF16X                  ; 8-bit index for frame building
        .i8

        PHD                     ; save caller's direct page
        PHA                     ; push channel  -> LOC_CHAN
        TYA
        PHA                     ; push bank     -> LOC_BANK

        ON16X                   ; 16-bit X = string address
        .i16
        PHX                     ; push string ptr -> LOC_PTR (2 bytes)

        ; Point direct page at frame base.
        ; After TCD, locals are accessed as bare direct page addresses.
        ON16MEM
        .a16
        TSC
        TCD                     ; D = S -> LOC_CHAN/$01, LOC_BANK/$02, LOC_PTR/$03
        OFF16MEM
        .a8

        ; Set DBR to string's bank
        LDA     LOC_BANK        ; direct page
        PHA
        PLB                     ; DBR = string bank

@loop:
        ON16X
        .i16
        LDX     LOC_PTR         ; direct page -- X = current string pointer
        OFF16X
        .i8
        LDA     $0000,X         ; read byte at DBR:X
        BEQ     @done           ; null terminator

        CMP     #$0A            ; LF?
        BNE     @send_char

        ; Send CR ($0D) before LF
        PHA                     ; save LF
        LDA     LOC_CHAN        ; direct page -- A = channel
        LDX     #$0D            ; X = CR
        JSL     hal_uart_putc
        PLA                     ; restore LF

@send_char:
        TAX                     ; X = char
        LDA     LOC_CHAN        ; direct page -- A = channel
        JSL     hal_uart_putc

        ; Advance string pointer
        ON16MEM
        .a16
        INC     LOC_PTR         ; direct page -- 16-bit increment
        OFF16MEM
        .a8
        BRA     @loop

@done:
        ; Restore DBR to $00
        PEA     $0000
        PLB
        PLB                     ; two PLBs drain the PEA word -> DBR = $00

        ; Tear down frame locals
        ON16X
        .i16
        PLX                     ; discard LOC_PTR
        OFF16X
        .i8
        PLA                     ; discard LOC_BANK
        PLA                     ; discard LOC_CHAN

        PLD                     ; restore caller's direct page
        RTL

ENDPUBLIC

; =============================================================================
; hal_uart_status -- return raw ACSRx value
;
;   In:  A (8-bit) = UART channel
;   Out: A (8-bit) = ACSRx value
; =============================================================================

PUBLIC  hal_uart_status

        OFF16                   ; 8-bit A and X

        CMP     #0
        BEQ     @ch0
        CMP     #1
        BEQ     @ch1
        CMP     #2
        BEQ     @ch2
@ch3:   LDA     ACSR3
        RTL
@ch2:   LDA     ACSR2
        RTL
@ch1:   LDA     ACSR1
        RTL
@ch0:   LDA     ACSR0
        RTL

ENDPUBLIC

; =============================================================================
; hal_uart_rx_ready -- test if RX ring has data
;
;   In:  A (8-bit) = UART channel
;   Out: Z clear = data available; Z set = ring empty
; =============================================================================

PUBLIC  hal_uart_rx_ready

        OFF16                   ; 8-bit A and X

        CMP     #1
        BEQ     @ch1

@ch0:   LDA     u0_rx_head
        CMP     u0_rx_tail      ; Z set = empty, Z clear = data available
        RTL

@ch1:   LDA     u1_rx_head
        CMP     u1_rx_tail
        RTL

ENDPUBLIC

; =============================================================================
; hal_isr_uart0_rx -- UART0 RX interrupt handler
;
; Reads ARTD0, enqueues to u0_rx_buf.
; If ring full, drops oldest byte (advances tail).
; =============================================================================

PUBLIC  hal_isr_uart0_rx

        PHA
        PHX
        OFF16                   ; 8-bit A and X

        LDA     ARTD0           ; read data -- clears RX flag in UIFR

        LDX     u0_rx_head
        STA     u0_rx_buf,X     ; store at head

        TXA
        INC     A
        AND     #$3F
        STA     u0_rx_head      ; advance head

        ; If head caught tail -- ring was full, drop oldest byte
        CMP     u0_rx_tail
        BNE     @done
        LDA     u0_rx_tail
        INC     A
        AND     #$3F
        STA     u0_rx_tail

@done:
        PLX
        PLA
        RTI

ENDPUBLIC

; =============================================================================
; hal_isr_uart0_tx -- UART0 TX interrupt handler
;
; Dequeues from u0_tx_buf and writes to ARTD0.
; Disables UART0 TX interrupt when ring empties.
; =============================================================================

PUBLIC  hal_isr_uart0_tx

        PHA
        PHX
        OFF16                   ; 8-bit A and X

        LDA     u0_tx_head
        CMP     u0_tx_tail
        BNE     @send

        ; Ring empty -- disable UART0 TX interrupt
        LDA     UIER
        AND     #$FF ^ UART0T
        STA     UIER
        BRA     @done

@send:
        LDX     u0_tx_tail
        LDA     u0_tx_buf,X     ; dequeue byte
        STA     ARTD0           ; transmit -- clears TX flag in UIFR

        TXA
        INC     A
        AND     #$1F
        STA     u0_tx_tail      ; advance tail

@done:
        PLX
        PLA
        RTI

ENDPUBLIC

; =============================================================================
; hal_isr_uart1_rx -- UART1 RX interrupt handler
; =============================================================================

PUBLIC  hal_isr_uart1_rx

        PHA
        PHX
        OFF16

        LDA     ARTD1

        LDX     u1_rx_head
        STA     u1_rx_buf,X

        TXA
        INC     A
        AND     #$3F
        STA     u1_rx_head

        CMP     u1_rx_tail
        BNE     @done
        LDA     u1_rx_tail
        INC     A
        AND     #$3F
        STA     u1_rx_tail

@done:
        PLX
        PLA
        RTI

ENDPUBLIC

; =============================================================================
; hal_isr_uart1_tx -- UART1 TX interrupt handler
; =============================================================================

PUBLIC  hal_isr_uart1_tx

        PHA
        PHX
        OFF16

        LDA     u1_tx_head
        CMP     u1_tx_tail
        BNE     @send

        LDA     UIER
        AND     #$FF ^ UART1T
        STA     UIER
        BRA     @done

@send:
        LDX     u1_tx_tail
        LDA     u1_tx_buf,X
        STA     ARTD1

        TXA
        INC     A
        AND     #$1F
        STA     u1_tx_tail

@done:
        PLX
        PLA
        RTI

ENDPUBLIC
