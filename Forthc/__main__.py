#!/usr/bin/env python3
"""
forthc — Forth-to-VM-assembly compiler.

Usage:
    python -m forthc <source.f> [-o <output.s>] [--dump-tokens] [--dump-ast]

If -o is not given, output is written to <source>.s
"""

import argparse
import sys
import pathlib

from forthc.tokenizer import tokenize, TokenizeError
from forthc.parser    import parse, ParseError
from forthc.codegen   import generate, CodeGenError


def main():
    ap = argparse.ArgumentParser(
        prog='forthc',
        description='Compile Forth-like source to VM assembly.')
    ap.add_argument('source',
                    help='Input Forth source file')
    ap.add_argument('-o', '--output',
                    help='Output assembly file (default: <source>.s)')
    ap.add_argument('--dump-tokens', action='store_true',
                    help='Print token stream and exit')
    ap.add_argument('--dump-ast', action='store_true',
                    help='Print AST and exit')
    args = ap.parse_args()

    src_path = pathlib.Path(args.source)
    if not src_path.exists():
        print(f"forthc: error: file not found: {src_path}", file=sys.stderr)
        sys.exit(1)

    source = src_path.read_text(encoding='utf-8')

    # --- Tokenize ---
    try:
        tokens = tokenize(source)
    except TokenizeError as e:
        print(f"forthc: tokenize error: {e}", file=sys.stderr)
        sys.exit(1)

    if args.dump_tokens:
        for tok in tokens:
            print(tok)
        return

    # --- Parse ---
    try:
        program = parse(tokens)
    except ParseError as e:
        print(f"forthc: parse error: {e}", file=sys.stderr)
        sys.exit(1)

    if args.dump_ast:
        import pprint
        pprint.pprint(program)
        return

    # --- Code generation ---
    try:
        asm = generate(program)
    except CodeGenError as e:
        print(f"forthc: codegen error: {e}", file=sys.stderr)
        sys.exit(1)

    # --- Write output ---
    if args.output:
        out_path = pathlib.Path(args.output)
    else:
        out_path = src_path.with_suffix('.s')

    out_path.write_text(asm, encoding='utf-8')
    print(f"forthc: wrote {out_path}  ({len(asm)} bytes)")


if __name__ == '__main__':
    main()
