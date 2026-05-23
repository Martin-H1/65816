        .p816
        .smart  off

	.include "macros.inc"

        .segment "HAL_CODE"

; =============================================================================
; UART stubs - replace with real implementations
; =============================================================================

PUBLIC	hal_baud_set_timer
        RTL
ENDPUBLIC

PUBLIC	hal_uart_set_timer
        RTL
ENDPUBLIC

PUBLIC	hal_uart_init
        RTL
ENDPUBLIC

PUBLIC	hal_uart_putc
        RTL
ENDPUBLIC

PUBLIC	hal_uart_getc
        RTL
ENDPUBLIC

PUBLIC	hal_uart_puts
        RTL
ENDPUBLIC

PUBLIC	hal_uart_status
        RTL
ENDPUBLIC

PUBLIC	hal_uart_rx_ready
        RTL
ENDPUBLIC

PUBLIC	hal_isr_uart0_rx
        RTI
ENDPUBLIC

PUBLIC	hal_isr_uart0_tx
        RTI
ENDPUBLIC

PUBLIC	hal_isr_uart1_rx
        RTI
ENDPUBLIC

PUBLIC	hal_isr_uart1_tx
        RTI
ENDPUBLIC
