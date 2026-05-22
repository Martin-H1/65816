# =============================================================================
# Makefile — W65C265S HAL build system
#
# Produces: bin/hal.bin — 32K flat binary for the EEPROM ($8000–$FFFF)
#
# Requirements: cc65 toolchain (ca65, ld65) in PATH
#   Install: https://cc65.github.io
#
# Compatible with GNU Make 3.78+ on Windows (cmd.exe or MinGW shell)
#
# Targets:
#   make          — build bin/hal.bin
#   make clean    — remove all build artifacts
#   make info     — show image summary (size, segment addresses)
#   make disasm   — disassemble the image with da65 (if available)
# =============================================================================

include ../common.mk

# ── Toolchain ─────────────────────────────────────────────────────────────────
DA65    = da65

# ── Directories ───────────────────────────────────────────────────────────────
SRCDIR  = src
OBJDIR  = obj
BINDIR  = bin

# ── Output ────────────────────────────────────────────────────────────────────
TARGET  = $(BINDIR)/hal.bin
MAPFILE = $(BINDIR)/hal.map
LBLFILE = $(BINDIR)/hal.lbl

# ── Linker config ─────────────────────────────────────────────────────────────
LDCFG   = hal.cfg

# ── ca65 flags ────────────────────────────────────────────────────────────────
# --cpu 65816   target CPU
# -g            include debug info in object files (for da65 / debugger)
# -I src        include path for .inc files

CA65FLAGS = --cpu 65816 -g -I $(SRCDIR)

# ── ld65 flags ────────────────────────────────────────────────────────────────
# -C hal.cfg    linker configuration
# -m hal.map    generate map file
# -Ln hal.lbl   generate label file (useful for emulator debuggers)

LD65FLAGS = -C $(LDCFG) -m $(MAPFILE) -Ln $(LBLFILE)

# ── Source files ──────────────────────────────────────────────────────────────
SOURCES = \
    $(SRCDIR)/hal_zp.asm        \
    $(SRCDIR)/hal_page2.asm     \
    $(SRCDIR)/hal_init.asm      \
    $(SRCDIR)/hal_jumptable.asm \
    $(SRCDIR)/hal_vectors.asm

# ── Derived object file list ──────────────────────────────────────────────────
OBJECTS = $(patsubst $(SRCDIR)/%.asm,$(OBJDIR)/%.o,$(SOURCES))

# =============================================================================
# Targets
# =============================================================================

.PHONY: all clean info disasm dirs

all: dirs $(TARGET)

# ── Create output directories before anything else ───────────────────────────
# Done unconditionally as a separate target so Make 3.78 doesn't need
# order-only prerequisites (the | syntax, unsupported before 3.80).
dirs:
	-mkdir $(OBJDIR)
	-mkdir $(BINDIR)

# ── Link ──────────────────────────────────────────────────────────────────────
$(TARGET): $(OBJECTS) $(LDCFG)
	$(LD65) $(LD65FLAGS) -o $@ $(OBJECTS)
	@echo.
	@echo Built: $@
	@echo Map:   $(MAPFILE)

# ── Assemble — pattern rule for all .asm -> .o ───────────────────────────────
$(OBJDIR)/%.o: $(SRCDIR)/%.asm
	$(CA65) $(CA65FLAGS) -o $@ $<

# ── Clean ─────────────────────────────────────────────────────────────────────
# Uses Windows del/rmdir compatible with cmd.exe.
# The leading - tells Make to ignore errors (e.g. files already absent).
clean:
	-del /Q $(OBJDIR)\*.o 2>nul
	-del /Q $(BINDIR)\*.bin $(BINDIR)\*.map $(BINDIR)\*.lbl 2>nul
	-rmdir $(OBJDIR) 2>nul
	-rmdir $(BINDIR) 2>nul

# ── Info — print segment layout from map file ─────────────────────────────────
info: $(TARGET)
	@echo === Segment layout ===
	@findstr /N "" $(MAPFILE)

# ── Disassemble ───────────────────────────────────────────────────────────────
disasm: $(TARGET)
	$(DA65) --cpu 65816 --start-addr 0x8000 $(TARGET)
