# 65816 ANS Forth Kernel

An ITC (Indirect Threaded Code) Forth kernel for the WDC 65816,
targeting a single-board computer with UART serial I/O.

## Architecture

| Property       | Value                          |
|----------------|--------------------------------|
| CPU            | WDC 65816                      |
| Standard       | ANS Forth (ANSI 1994)          |
| Threading      | Indirect Threaded Code (ITC)   |
| Cell size      | 16-bit                         |
| ROM            | Kernel ($8000-$FFFF)           |
| RAM            | Stacks, user area, dictionary  |
| I/O            | UART serial                    |

## File Structure

```
Makefile        Makefile build file (requires cc65 suite)
build.sh        Build script (requires cc65 suite)
constants.inc   Project wide constants to avoid magic numbers
dictionary.inc  Forward declarations for all CFA labels
forth.cfg       Linker memory map configuration
forth.s         Main kernel: init, inner interpreter, vectors
hal.inc         Hardware Abstraction Layer interface
hal_mench.s     HAL implementation for w65c265 Mench Reloaded SBC
macros.inc      ca65 macros (NEXT, PUSH, POP, HEADER, CODEPTR)
primitives.s    All assembly-coded primitive words
prompt.txt      The following three files are Claude prompts and coding styles.
sample_coding_style.s
summary.txt
```

## Memory Map

```
$0000-$007F     Zero Page / Direct Page
                  $02  W        Working register (current CFA)
                  $04  UP       User Pointer
                  $06  SCRATCH0 Scratch
                  $08  SCRATCH1 Scratch
                  $0A  TMPA     Temp (multiply/divide)
                  $0C  TMPB     Temp (multiply/divide)

$0100-$01FF     Hardware Stack (Return Stack, grows down from $01FF)
$0200-$03FF     Parameter Stack (grows down from $03FF)
$0400-$04FF     User Area
                  +$00  BASE         numeric base (default 10)
                  +$02  STATE        0=interpret, 1=compile
                  +$04  DP           dictionary pointer
                  +$06  LATEST       latest definition link
                  +$08  TIB          terminal input buffer address
                  +$0A  >IN          parse offset
                  +$0C  SOURCE-LEN   current source length
                  +$0E  HANDLER      exception handler
$0500-$05FF     Scratch PAD area
$0600-$06FF     Terminal Input Buffer (TIB)
$0700-$7EFF     RAM Dictionary (user definitions grow upward)
$7F00-$7FFF     I/O Space (UART)
$8000-$FFBF     ROM Kernel
$FFE0-$FFFF     Hardware Vectors
```

## Register Conventions

| Register | Width  | Purpose                         |
|----------|--------|---------------------------------|
| A        | 16-bit | Working register / scratch      |
| X        | 16-bit | Parameter Stack Pointer (PSP)   |
| Y        | 16-bit | Instruction Pointer (IP)        |
| S        | 16-bit | Return Stack Pointer (hardware) |
| D        | 16-bit | Direct Page base ($0000)        |
| DB       | 8-bit  | Data Bank ($00)                 |

## ITC Execution Model

Each dictionary entry's Code Field (CFA) contains the address
of a pointer to machine code:

```
CFA → [code_ptr_addr] → [machine_code]
```

NEXT fetches through this double indirection:

```asm
LDA  0,Y        ; W = *IP  (fetch CFA from body)
INY
INY             ; IP += 2
STA  W
LDA  (W)        ; fetch code pointer
STA  SCRATCH0
JMP  (SCRATCH0) ; jump to machine code
```

Code pointers for word types:

| Word type   | Code pointer |
|-------------|--------------|
| Colon `:`   | DOCOL        |
| VARIABLE    | DOVAR        |
| CONSTANT    | DOCON        |
| DOES>       | DODOES       |
| Primitive   | own code     |

## Dictionary Entry Layout

```
Offset  Size  Field
------  ----  -----
0       2     Link field (address of previous entry, 0 = end)
2       1     Flags + name length
                bit 7: F_IMMEDIATE ($80)
                bit 6: F_HIDDEN    ($40)
                bits 4-0: name length (F_LENMASK = $1F)
3       n     Name characters (ASCII)
3+n     0-1   Alignment padding (.align 2)
(aligned)  2  Code Field (CFA): address of code pointer
(CFA+2)    -  Body (for colon words: list of CFAs)
```

## Implemented Words

### Stack
`DUP DROP SWAP OVER ROT NIP TUCK`
`2DUP 2DROP 2SWAP 2OVER DEPTH PICK`

### Return Stack
`>R R> R@`

### Arithmetic
`+ - * UM* / MOD /MOD UM/MOD`
`NEGATE ABS MAX MIN 1+ 1- 2* 2/`

### Comparison (TRUE=$FFFF, FALSE=$0000)
`= <> < > U< U> 0= 0< 0>`

### Logic
`AND OR XOR INVERT LSHIFT RSHIFT`

### Memory
`@ ! C@ C! 2@ 2! MOVE FILL`

### I/O (UART)
`EMIT KEY KEY? TYPE CR SPACE SPACES`

### Inner Interpreter
`EXIT EXECUTE LIT BRANCH 0BRANCH`
`(DO) (LOOP) (+LOOP) UNLOOP I J`

### Dictionary
`HERE ALLOT , C, LATEST BASE STATE >IN SOURCE`

### System
`QUIT ABORT BYE TIB ACCEPT`

### Output
`. U. .HEX .S`

### Strings
`COUNT WORD HEX DECIMAL NUMBER`

### Defining
`: ; CONSTANT VARIABLE CREATE DOES>`

## UART Configuration

Edit `forth.s` to match your hardware:

```asm
UART_STATUS  = $7F00    ; Status register address
UART_DATA    = $7F01    ; Data register address
UART_TXRDY   = $02      ; TX ready bit mask
UART_RXRDY   = $01      ; RX ready bit mask
```

Common UART chips:
- **65C51 ACIA**: STATUS=$xx00, DATA=$xx01, TXRDY=bit1, RXRDY=bit3
- **16C550**: STATUS=$xx05 (LSR), DATA=$xx00, TXRDY=bit5, RXRDY=bit0

## Building

```bash
# Install cc65 (Debian/Ubuntu)
sudo apt install cc65

# Build
make all
make debug
make tests

# Output: bin/release/forth.bin (32KB ROM image)
```

## Implementation Notes

### What is complete
- Full inner interpreter (NEXT, DOCOL, DOVAR, DOCON, DODOES)
- All primitive words assembled and linked
- UART I/O with polling via HAL
- QUIT outer interpreter loop skeleton
- ACCEPT line editor with backspace support
- NUMBER conversion routine.
- WORD parser is complete.
- Dictionary search (FIND)
- System initialization and hardware vectors
- 16-bit math funnctions
- ":", ";", and basic conditional and flow control.
- Extensive unit tests for primitive verification

### What needs completion
The following words have stubs and need full implementation:

1. Refactoring WORD to use PARSE.

2. Conditional statements ?DUP, CASE, OF, ENDOF, and ENDCASE.

3. Flow control words like +LOOP, LEAVE, AGAIN, WHILE, REPEAT, and RECURSE.

4. Double precision mathematics.

### Extending for your SBC
- Change HAL code for your UART chip
- Adjust DICT_TOP if you have more/less RAM
- Add IRQ handler if you want interrupt-driven I/O
- Add NMI handler for a hardware reset button
