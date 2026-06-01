# forthc — Forth-like to VM-assembly compiler

A compiler for a Forth-like language that targets a portable virtual-machine
instruction set.  The VM instructions are then lowered to native code by a
set of assembler macros (`vmachine.inc`) and a small runtime library
(`vmachine.s`), both of which are target-specific and fully replaceable.

## Architecture

```
source.f
   │
   ▼  tokenizer.py   (forthc/tokenizer.py)
list[Token]
   │
   ▼  parser.py      (forthc/parser.py)
Program AST           (forthc/ast_nodes.py)
   │
   ▼  codegen.py     (forthc/codegen.py)
source.s  ← VM-instruction assembly text
   │
   ▼  ca65 / target assembler
   │    .include "vmachine.inc"   ← target macro definitions
   │    .include "vmachine.s"     ← runtime routines
   ▼
binary
```

The output of `forthc` is **subroutine-threaded code** with short primitives
inlined directly (no interpreter overhead for `DUP`, `+`, `@`, etc.).

---

## Compilation pipeline

| Stage | File | Input → Output |
|---|---|---|
| Tokenizer | `forthc/tokenizer.py` | source text → `list[Token]` |
| Parser | `forthc/parser.py` | tokens → `Program` AST |
| Code generator | `forthc/codegen.py` | AST → VM assembly text |

---

## Usage

### 1. Compile Forth source to VM assembly

```bash
python __main__.py examples/basic.f          # writes basic.s
python __main__.py examples/basic.f -o out/basic.s

# Debug: dump token stream or AST
python __main__.py examples/basic.f --dump-tokens
python __main__.py examples/basic.f --dump-ast
```

### 2. Assemble (65816 target, using ca65)

```bash
# Assemble the compiled Forth module
ca65 --cpu 65816 -I targets/65816 basic.s -o obj/basic.o

# Assemble the VM runtime
ca65 --cpu 65816 -I targets/65816 targets/65816/vmachine.s -o obj/vmachine.o
```

### 3. Link (using ld65)

```bash
ld65 -C targets/65816/debug.cfg obj/vmachine.o obj/basic.o -o basic.bin
```

`debug.cfg` places the `CODE` segment at `$4000` (aligned to `$100`) and
zero page variables in `$00B4–$00FE`.  `MAIN` — the generated entry point —
will be the first code in the `CODE` segment, so the ROM monitor should be
configured to JSL to `$4000`.

A typical `Makefile` rule:

```makefile
TARGET  = 65816
INCDIR  = targets/$(TARGET)
CFGDIR  = targets/$(TARGET)
OBJDIR  = obj/release

$(OBJDIR)/%.o: %.s
	ca65 --cpu $(TARGET) -I $(INCDIR) $< -o $@

$(OBJDIR)/vmachine.o: $(INCDIR)/vmachine.s
	ca65 --cpu $(TARGET) -I $(INCDIR) $< -o $@

%.bin: $(OBJDIR)/%.o $(OBJDIR)/vmachine.o
	ld65 -C $(CFGDIR)/debug.cfg $(OBJDIR)/vmachine.o $< -o $@
```

From Python:

```python
from forthc import compile_source

asm = compile_source("""
    42 constant answer
    : print-answer  answer . cr ;
""")
print(asm)
```

---

## Language reference

### Top-level forms

| Syntax | Meaning |
|---|---|
| `n constant name` | Define compile-time constant |
| `variable name` | Allocate one cell of storage |
| `: name … ;` | Define a word (subroutine) |
| `.origin addr` | Set origin address (e.g. `.origin $8000`) |
| `.segment NAME` | Switch assembler segment |

### Inside a word definition

| Syntax | Meaning |
|---|---|
| `n` | Push literal integer (decimal, `$hex`, `0xhex`, `0bbinary`) |
| `name` | Call a word or push a constant |
| `." text"` | Print string literal |
| `S" text"` | Push (addr, len) of string |
| `if … then` | Conditional |
| `if … else … then` | Conditional with alternate |
| `begin … until` | Loop until TOS is true |
| `begin … while … repeat` | Loop while TOS is true |
| `do … loop` | Counted loop (limit index do … loop) |

### Comments

```forth
\ line comment
( paren comment )
```

---

## VM instruction set

| Instruction | Stack effect | Notes |
|---|---|---|
| `LIT n` | `-- n` | Push literal |
| `EXIT` | | Subroutine return |
| `CALL addr` | | Subroutine call |
| `ZBRANCH addr` | `flag --` | Branch if zero |
| `FETCH` | `addr -- n` | `@` |
| `STORE` | `n addr --` | `!` |
| `BFETCH` | `addr -- b` | `c@` |
| `BSTORE` | `b addr --` | `c!` |
| `TOR` | `n --` | `>r` |
| `RFROM` | `-- n` | `r>` |
| `DUP` | `n -- n n` | |
| `DROP` | `n --` | |
| `NIP` | `n1 n2 -- n2` | |
| `ADD` | `n1 n2 -- n3` | `+` |
| `SUB` | `n1 n2 -- n3` | `-` |
| `STAR` | `n1 n2 -- n3` | `*` |
| `EQ` | `n1 n2 -- flag` | `=` |
| `EMIT` | `c --` | Output character |
| `KEY` | `-- c` | Read character |
| `TYPE` | `addr u --` | Output u chars |
| `CPUTS` | `addr --` | Output C string |
| `CLEAR` | `… --` | Reset stack |

Complex operations (`/`, `mod`, `swap`, `over`, `rot`, `and`, `or`, …) emit
`CALL vm_xxx` and are implemented in `vmachine.s`.

---

## Targets

### 65816 (`targets/65816/`)

| File | Contents |
|---|---|
| `vmachine.inc` | Macro definitions for all VM instructions |
| `vmachine.s` | Runtime routines: multiply, divide, bitwise ops, I/O, … |

**Stack model:** parameter stack in zero page, indexed by X (grows down,
16-bit cells).  Return stack is the hardware stack (`JSR`/`RTS`).

To add a new target, create `targets/<arch>/vmachine.inc` and
`targets/<arch>/vmachine.s` following the same conventions.

---

## Extending the language

* **New primitives:** add to `INLINE_OPS` or `RUNTIME_CALLS` in `codegen.py`.
* **New syntax:** add a `TType` in `tokenizer.py`, a keyword mapping in
  `KEYWORD_MAP`, an AST node in `ast_nodes.py`, a parse rule in `parser.py`,
  and a `_gen_xxx` method in `codegen.py`.
* **New targets:** provide `vmachine.inc` + `vmachine.s` only — no compiler
  changes needed.

---

## Running the tests

```bash
python tests.py
# or
python -m pytest tests.py -v
```

54 tests covering the tokenizer, parser, code generator, and an
end-to-end integration test.

---

## Project layout

```
forthc/
├── __main__.py          command-line driver
├── tests.py             test suite (54 tests)
├── forthc/
│   ├── __init__.py      public API + compile_source()
│   ├── tokenizer.py     lexical analysis
│   ├── ast_nodes.py     AST node dataclasses
│   ├── parser.py        recursive-descent parser
│   └── codegen.py       VM assembly code generator
├── targets/
│   └── 65816/
│       ├── vmachine.inc  65816 macro definitions
│       ├── vmachine.s    65816 runtime routines
│       └── debug.cfg     ld65 linker config ($4000 CODE, $00B4 ZP)
└── examples/
    ├── basic.f           constants, variables, if/then, loops
    └── fibonacci.f       fibonacci sequence
```
