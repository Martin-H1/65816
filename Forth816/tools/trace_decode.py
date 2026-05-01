#!/usr/bin/env python3
"""
trace_decode.py - Decode Forth816 trace output using CA65 map file.

Usage:
    forth816.exe | python trace_decode.py forth816.map
    python trace_decode.py forth816.map < trace.txt
"""

import sys
import re

# Known offsets from INTERPRET_CFA to named labels.
# Key is byte offset from INTERPRET_CFA.
INTERPRET_LABELS = {
    0:  "INTERPRET_CFA",
    2:  "INTERPRET_LOOP",
    22: "INTERPRET_NOTEMPTY",
    32: "INTERPRET_NOT_FOUND",
    40: "INTERPRET_NUMBER_OK",
    50: "INTERPRET_INTERPRETING_NUM",
    56: "INTERPRET_COMPILE_LIT",
    70: "INTERPRET_NOTANUMBER",
    76: "INTERPRET_FOUND",
    84: "INTERPRET_COMPILE_WORD",
    92: "INTERPRET_EXECUTE_IMM",
    98: "INTERPRET_COMPILE_NORMAL",
}

# Known offsets from INTERPRET_CFA to cell contents (for reference).
INTERPRET_CELLS = {
    0:  "DOCOL",
    2:  "LIT_CFA",
    4:  "' ' (space)",
    6:  "WORD_CFA",
    8:  "DUP_CFA",
    10: "CFETCH_CFA",
    12: "ZEROEQ_CFA",
    14: "ZBRANCH_CFA",
    16: "-> INTERPRET_NOTEMPTY",
    18: "DROP_CFA",
    20: "EXIT_CFA",
    22: "FIND_CFA",
    24: "DUP_CFA",
    26: "ZEROEQ_CFA",
    28: "ZBRANCH_CFA",
    30: "-> INTERPRET_FOUND",
    32: "DROP_CFA",
    34: "NUMBER_CFA",
    36: "ZBRANCH_CFA",
    38: "-> INTERPRET_NOTANUMBER",
    40: "STATE_CFA",
    42: "FETCH_CFA",
    44: "ZEROEQ_CFA",
    46: "ZBRANCH_CFA",
    48: "-> INTERPRET_COMPILE_LIT",
    50: "BRANCH_CFA",
    52: "-> INTERPRET_LOOP",
    54: "LIT_CFA",
    56: "LIT_CFA (value)",
    58: "COMPILECOMMA_CFA",
    60: "COMPILECOMMA_CFA",
    62: "BRANCH_CFA",
    64: "-> INTERPRET_LOOP",
    66: "DROP_CFA",
    68: "UNDEFINED_WORD_CFA",
    70: "BRANCH_CFA",
    72: "-> INTERPRET_LOOP",
    74: "STATE_CFA",
    76: "FETCH_CFA",
    78: "ZEROEQ_CFA",
    80: "ZBRANCH_CFA",
    82: "-> INTERPRET_COMPILE_WORD",
    84: "DROP_CFA",
    86: "EXECUTE_CFA",
    88: "BRANCH_CFA",
    90: "-> INTERPRET_LOOP",
    92: "LIT_CFA",
    94: "$FFFF (immediate flag)",
    96: "EQUAL_CFA",
    98: "ZBRANCH_CFA",
    100: "-> INTERPRET_COMPILE_NORMAL",
    102: "EXECUTE_CFA",
    104: "BRANCH_CFA",
    106: "-> INTERPRET_LOOP",
    108: "COMPILECOMMA_CFA",
    110: "BRANCH_CFA",
    112: "-> INTERPRET_LOOP",
}

def load_map(map_file):
    """Parse CA65 map file and return dict of address -> symbol name."""
    symbols = {}
    in_exports = False

    with open(map_file, 'r') as f:
        for line in f:
            if 'Exports list by name:' in line:
                in_exports = True
                continue
            if 'Exports list by value:' in line:
                break

            if in_exports:
                matches = re.findall(r'(\S+)\s+([0-9A-Fa-f]{6})\s+\w+', line)
                for name, addr_str in matches:
                    addr = int(addr_str, 16) & 0xFFFF
                    symbols[addr] = name

    return symbols

def find_nearest(symbols, addr):
    """Find the nearest symbol at or below addr."""
    candidates = [(a, n) for a, n in symbols.items() if a <= addr]
    if not candidates:
        return None, 0
    closest_addr, name = max(candidates, key=lambda x: x[0])
    offset = addr - closest_addr
    return name, offset

def decode_addr(symbols, addr):
    """Return a human readable string for an address."""
    name, offset = find_nearest(symbols, addr)
    if not name:
        return f"{addr:04X}"

    # Check if this is an offset from INTERPRET_CFA and add label
    if name == 'INTERPRET_CFA':
        label = INTERPRET_LABELS.get(offset)
        cell  = INTERPRET_CELLS.get(offset)
        if label and label != 'INTERPRET_CFA':
            name_str = f"{label}"
        elif cell:
            name_str = f"INTERPRET_CFA+{offset} [{cell}]"
        else:
            name_str = f"INTERPRET_CFA+{offset}"
    else:
        name_str = name if offset == 0 else f"{name}+{offset}"

    return f"{addr:04X}({name_str})"

def decode_trace(map_file):
    symbols = load_map(map_file)
    if not symbols:
        print("Warning: no symbols loaded from map file", file=sys.stderr)
        return
    print(f"Loaded {len(symbols)} symbols from {map_file}", file=sys.stderr)

    hex_pattern = re.compile(r'\b([0-9A-Fa-f]{4})\b')

    for line in sys.stdin:
        line = line.rstrip()
        # Split on whitespace — each token is one trace entry
        tokens = line.split()
        for token in tokens:
            m = re.fullmatch(r'[0-9A-Fa-f]{4}', token)
            if m:
                addr = int(token, 16)
                print(decode_addr(symbols, addr))
            else:
                print(token)

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <mapfile>", file=sys.stderr)
        sys.exit(1)

    decode_trace(sys.argv[1])
