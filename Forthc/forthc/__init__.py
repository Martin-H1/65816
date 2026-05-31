"""
forthc — a Forth-like language compiler targeting a virtual machine instruction set.

Pipeline:
    source text
        → tokenizer.tokenize()    → list[Token]
        → parser.parse()          → Program (AST)
        → codegen.generate()      → assembly text (vmachine instructions)

The assembly text is then processed by an assembler together with:
    vmachine.inc   — target-specific macro definitions for each VM instruction
    vmachine.s     — runtime routines for complex operations (vm_star, vm_slash …)
"""

from .tokenizer import tokenize, Token, TType, TokenizeError
from .parser    import parse, ParseError
from .codegen   import generate, CodeGenError
from .ast_nodes import Program

__all__ = [
    'tokenize', 'Token', 'TType', 'TokenizeError',
    'parse', 'ParseError',
    'generate', 'CodeGenError',
    'Program',
    'compile_source',
]

__version__ = '0.1.0'


def compile_source(source: str) -> str:
    """
    End-to-end compilation: Forth source text → VM assembly text.
    Raises TokenizeError, ParseError, or CodeGenError on failure.
    """
    tokens  = tokenize(source)
    program = parse(tokens)
    return generate(program)
