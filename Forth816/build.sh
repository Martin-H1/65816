#!/bin/bash
#==============================================================================
# build.sh - Build script for 65816 ANS Forth kernel
#
# Requirements:
#   ca65  (assembler)  - part of cc65 suite
#   ld65  (linker)     - part of cc65 suite
#
# Install cc65 on Debian/Ubuntu:
#   sudo apt install cc65
#
# Install cc65 on macOS:
#   brew install cc65
#==============================================================================

set -e

echo "=== 65816 Forth Kernel Build ==="

# Output directory
OUTDIR=build
mkdir -p $OUTDIR

# Assemble each source file
echo "[1/3] Assembling forth.s ..."
ca65 --cpu 65816 -o $OUTDIR/forth.o forth.s

echo "[2/3] Assembling primitives.s ..."
ca65 --cpu 65816 -o $OUTDIR/primitives.o primitives.s

# Link
echo "[3/3] Linking ..."
ld65 -C forth.cfg \
     -o $OUTDIR/forth.bin \
     --mapfile $OUTDIR/forth.map \
     --dbgfile $OUTDIR/forth.dbg \
     $OUTDIR/forth.o \
     $OUTDIR/primitives.o

echo ""
echo "=== Build complete ==="
echo "  Binary:  $OUTDIR/forth.bin"
echo "  Map:     $OUTDIR/forth.map"
echo "  Size:    $(wc -c < $OUTDIR/forth.bin) bytes"
echo ""

# Optionally generate a hex file for flashing
if command -v objcopy &>/dev/null; then
    objcopy -I binary -O ihex $OUTDIR/forth.bin $OUTDIR/forth.hex
    echo "  Hex:     $OUTDIR/forth.hex"
fi

# Optionally disassemble for inspection
if command -v da65 &>/dev/null; then
    echo ""
    echo "=== Disassembly ==="
    da65 --cpu 65816 --start-addr 0x8000 $OUTDIR/forth.bin > $OUTDIR/forth.dis
    echo "  Disasm:  $OUTDIR/forth.dis"
fi
