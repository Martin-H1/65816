"""
Abstract Syntax Tree node definitions for the Forth compiler.
"""

from dataclasses import dataclass, field
from typing import Any


# ---------------------------------------------------------------------------
# Base
# ---------------------------------------------------------------------------

@dataclass
class ASTNode:
    line: int = field(default=0, repr=False, compare=False)
    col:  int = field(default=0, repr=False, compare=False)


# ---------------------------------------------------------------------------
# Top-level definitions
# ---------------------------------------------------------------------------

@dataclass
class ConstantDef(ASTNode):
    """15 constant foo  →  foo = 15"""
    name:  str = ''
    value: int = 0


@dataclass
class VariableDef(ASTNode):
    """variable bar  →  allocate one cell named bar"""
    name: str = ''


@dataclass
class WordDef(ASTNode):
    """: foo <body> ;"""
    name: str        = ''
    body: list       = field(default_factory=list)


@dataclass
class OriginDirective(ASTNode):
    """.origin $8000  →  set the origin address"""
    address: int = 0


@dataclass
class SegmentDirective(ASTNode):
    """.segment "CODE"  →  switch segment"""
    name: str = ''


@dataclass
class MainDirective(ASTNode):
    """.main foo  →  designate 'foo' as the program entry point."""
    word: str = ''


# ---------------------------------------------------------------------------
# Expressions / statements inside a word definition
# ---------------------------------------------------------------------------

@dataclass
class NumberLit(ASTNode):
    """A numeric literal pushes its value onto the stack."""
    value: int = 0


@dataclass
class StringLit(ASTNode):
    """S" hello"  →  push (addr, len) of string onto stack."""
    text: str = ''


@dataclass
class PrintString(ASTNode):
    '." hello"  →  print string literal.'
    text: str = ''


@dataclass
class WordCall(ASTNode):
    """Reference to any Forth word (built-in or user-defined)."""
    name: str = ''


@dataclass
class IfThen(ASTNode):
    """if <consequent> [ else <alternate> ] then"""
    consequent: list = field(default_factory=list)
    alternate:  list = field(default_factory=list)


@dataclass
class BeginUntil(ASTNode):
    """begin <body> until  — loop until TOS is true"""
    body: list = field(default_factory=list)


@dataclass
class BeginWhileRepeat(ASTNode):
    """begin <test> while <body> repeat"""
    test: list = field(default_factory=list)
    body: list = field(default_factory=list)


@dataclass
class DoLoop(ASTNode):
    """do <body> loop"""
    body: list = field(default_factory=list)


# ---------------------------------------------------------------------------
# Top-level program
# ---------------------------------------------------------------------------

@dataclass
class Program(ASTNode):
    definitions: list = field(default_factory=list)
