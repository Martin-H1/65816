# W65C265S HAL

A bare-metal Hardware Abstraction Layer for a custom single-board computer
based on the Western Design Centre W65C265S microcontroller.

## Hardware

| Component | Description |
|---|---|
| CPU | W65C265S (65816 core, on-chip SRAM, 4× UART, 8× timers) |
| EEPROM | 32K, mapped at `$00:8000`–`$00:FFFF` |
| SRAM | 128K static RAM, mapped at `$00:0000`–`$00:7FFF` (lower window) or `$01:0000`–`$02:FFFF` (upper window, hardware jumper selected) |
| VIA | W65C22 at `$00:DFE0` — Port A: general GPIO, Port B: SPI to SD card |
| Oscillator | 3.6864 MHz (UART-friendly, 0% baud rate error at all standard rates) |

## Memory Map

```
$00:0000–$00:000F   HAL zero page variables
$00:0010–$00:00FF   Program zero page (free)
$00:0100–$00:01FF   65816 hardware stack (CPU-defined)
$00:0200–$00:02FF   HAL private page (ring buffers, callback vectors)
$00:0300–$00:7FFF   Program RAM (external SRAM)
$00:8000–$00:BFFF   ITC Forth kernel slot (EEPROM)
$00:C000–$00:DEEF   HAL implementation code (EEPROM)
$00:DF00–$00:DFFF   W65C265S Special Function Registers
$00:E000–$00:FEFF   HAL implementation code continued (EEPROM)
$00:FF00–$00:FF5F   HAL jump table — fixed entry points
$00:FF60–$00:FF7F   Reserved (SD card API slots)
$00:FF80–$00:FFBF   Native mode interrupt vector table
$00:FFC0–$00:FFFF   Emulation mode interrupt vector table
```

## HAL Entry Points

Programs call the HAL by doing a `JSL` to the fixed jump table address.
Because `JSL` pushes a 24-bit return address, callers can be in any bank;
`RTL` at the end of each HAL function returns to the caller's bank correctly.

```asm
JSL $00:FF00    ; hal_baud_set_timer
JSL $00:FF03    ; hal_uart_set_timer
JSL $00:FF06    ; hal_uart_init
JSL $00:FF09    ; hal_uart_putc
JSL $00:FF0C    ; hal_uart_getc
JSL $00:FF0F    ; hal_uart_puts
JSL $00:FF12    ; hal_uart_status
JSL $00:FF15    ; hal_uart_rx_ready
JSL $00:FF18    ; hal_via_init
JSL $00:FF1B    ; hal_via_set_dir
JSL $00:FF1E    ; hal_via_write
JSL $00:FF21    ; hal_via_read
JSL $00:FF24    ; hal_set_brk
JSL $00:FF27    ; hal_set_isr
JSL $00:FF2A    ; hal_set_nmi
JSL $00:FF2D    ; hal_version
```

Slots `$FF30`–`$FF3B` are reserved for the SD card API (not yet implemented).

A COP dispatch interface is also planned, providing bank-transparent 2-byte
calls (`COP #n`) that map to the same functions. This is intended primarily
for use by the Forth kernel.

## Calling Convention

| Register | Role |
|---|---|
| `A` (8-bit) | First argument (channel, port) / return value |
| `X` (16-bit) | Second argument (data, low word of pointer) |
| `Y` (8-bit) | Third argument (bank byte of pointer) |
| `A`, `X`, `Y` | Caller-saved — HAL may clobber them |
| `D` (direct page) | HAL saves and restores |
| `B` (data bank) | HAL saves and restores |

The HAL runs with 16-bit registers (`REP #$30`) by default and switches
to 8-bit only where required. Each entry point sets its own register width
explicitly rather than assuming the caller's state.

## Interrupt Callbacks

Programs can install handlers for BRK, IRQ, and NMI:

```asm
; Install an IRQ handler — X = handler address, Y = handler bank
LDX  #<my_irq_handler
LDY  #^my_irq_handler
JSL  $00:FF27           ; hal_set_isr
```

Handlers are called via the RTL-stack trick (indirect 24-bit call).
They must end with `RTL`. Pass `X=0, Y=0` to clear a handler.

## UART Baud Rate

The two on-chip baud rate timers (T3 and T4) are shared across all four
UARTs. Changing a timer's rate affects every UART bound to it.
The recommended initialisation sequence is:

```asm
; Configure T3 for 19200 baud, bind UART0 to it
REP  #$30
LDA  #HAL_TIMER3
LDX  #BAUD_19200
JSL  $00:FF00           ; hal_baud_set_timer

SEP  #$20
LDA  #HAL_UART0
LDX  #HAL_TIMER3
JSL  $00:FF03           ; hal_uart_set_timer

LDA  #HAL_UART0
JSL  $00:FF06           ; hal_uart_init
```

UART I/O is interrupt-driven with ring buffers in the HAL private page:
- UART0 RX: 64 bytes at `$0209`
- UART0 TX: 32 bytes at `$024B`
- UART1 RX: 64 bytes at `$026D`
- UART1 TX: 32 bytes at `$02AF`

`hal_uart_putc` enqueues into the TX ring and enables the TX interrupt.
`hal_uart_getc` dequeues from the RX ring (blocks until a byte is available).

## Forth Kernel

On reset the HAL probes for a Forth kernel signature at `$00:8000`.
If the 4-byte signature `FTH\0` is found, the HAL does `JSL $00:8004`
to enter the Forth interpreter. If Forth returns (via `RTL`), or if no
valid image is found, the HAL falls through to its own idle loop.

The 4K Forth kernel slot (`$8000`–`$BFFF`) is filled with `$FF` in the
base HAL image and is programmed separately.

## Building

Requires the [cc65 toolchain](https://cc65.github.io) (`ca65`, `ld65`) in `PATH`.

```
make          # build bin/hal.bin (32K EEPROM image)
make clean    # remove obj/ and bin/
make info     # print segment layout from map file
make disasm   # disassemble with da65 (if available)
```

Tested with cc65 on Windows with GNU Make 3.78.1.

## Source Files

| File | Description |
|---|---|
| `hal.cfg` | ld65 linker script — memory regions and segment placement |
| `src/hal_sfr.inc` | W65C265S SFR addresses, bit masks, baud divisors, VIA layout |
| `src/hal_zp.asm` | Zero page variable declarations (`$00`–`$0F`) |
| `src/hal_page2.asm` | Page-two BSS layout — ring buffers, callback vectors, shadows |
| `src/hal_init.asm` | Boot sequence, ISR dispatchers, Forth probe, subsystem stubs |
| `src/hal_jumptable.asm` | Fixed jump table at `$FF00` |
| `src/hal_vectors.asm` | Native and emulation mode vector tables |

## Status

The project currently builds a complete EEPROM image with:
- Correct memory map and linker placement
- Fixed jump table at `$FF00` with stable entry point addresses
- Boot sequence: native mode switch, hardware init, Forth probe
- Interrupt vector tables (native and emulation mode)
- ISR dispatchers for IRQ, NMI, BRK, and COP
- Stub implementations for all HAL functions (RTL immediately)

Subsystems to be implemented:
- [ ] UART driver (`hal_uart.asm`) — buffered RX/TX with interrupts
- [ ] VIA / GPIO driver (`hal_via.asm`) — Port A GPIO, Port B SPI
- [ ] COP dispatch table (`hal_cop.asm`)
- [ ] SD card block storage (`hal_sd.asm`) — SPI via VIA Port B
- [ ] Forth kernel image
