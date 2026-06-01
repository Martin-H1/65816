"""
Code generator.

Walks the AST and emits virtual-machine assembly text.
The output is architecture-independent; it uses the VM instruction set
(LIT, CALL, EXIT, ZBRANCH, etc.) which are later resolved to native
instructions by the target-specific macro file (vmachine.inc).

The generator also tracks:
  - a symbol table of constants and word names
  - a label counter for synthetic branch targets
  - a string literal pool (emitted at end of each word)

Name mangling
-------------
Forth allows characters in word names (-, ?, !, @, etc.) that are illegal
in most assembler label identifiers.  _mangle() translates them to safe
ASCII equivalents before any name is emitted as a label or symbol.

  -   →  _          (most common: hyphenated-words)
  ?   →  _q
  !   →  _st         (store)
  @   →  _ft         (fetch)
  >   →  _to
  <   →  _lt
  =   →  _eq
  +   →  _pl
  *   →  _st2        (star — already used _st for !, so use _mul)
  /   →  _sl
  .   →  _dot
  #   →  _hash
  '   →  _tick

Any other non-alphanumeric/underscore character becomes _xNN (hex code).
"""

from __future__ import annotations
from dataclasses import dataclass, field
from typing import TextIO
import io
import re

from .ast_nodes import (
    Program, ConstantDef, VariableDef, WordDef,
    OriginDirective, SegmentDirective, MainDirective,
    NumberLit, StringLit, PrintString, WordCall,
    IfThen, BeginUntil, BeginWhileRepeat, DoLoop,
    ASTNode,
)


# ---------------------------------------------------------------------------
# Name mangling
# ---------------------------------------------------------------------------

_MANGLE_MAP = {
    '-': '_',
    '?': '_q',
    '!': '_store',
    '@': '_fetch',
    '>': '_to',
    '<': '_from',
    '=': '_eq',
    '+': '_pl',
    '*': '_mul',
    '/': '_sl',
    '.': '_dot',
    '#': '_hash',
    "'": '_tick',
}

def _mangle(name: str) -> str:
    """Translate a Forth word name to a valid assembler identifier."""
    out = []
    for ch in name:
        if ch.isalnum() or ch == '_':
            out.append(ch)
        elif ch in _MANGLE_MAP:
            out.append(_MANGLE_MAP[ch])
        else:
            out.append(f'_x{ord(ch):02x}')
    result = ''.join(out)
    # Identifiers must not start with a digit
    if result and result[0].isdigit():
        result = '_' + result
    return result


# ---------------------------------------------------------------------------
# Built-in word → VM instruction mapping
# ---------------------------------------------------------------------------
# Words that compile directly to a single VM instruction (no CALL needed).

INLINE_OPS: dict[str, str] = {
    '@':      'FETCH',
    '!':      'STORE',
    'c@':     'BFETCH',
    'c!':     'BSTORE',
    '>r':     'TOR',
    'r>':     'RFROM',
    'dup':    'DUP',
    'drop':   'DROP',
    'nip':    'NIP',
    '+':      'ADD',
    '-':      'SUB',
    '*':      'STAR',
    '=':      'EQ',
    'emit':   'EMIT',
    'key':    'KEY',
    'type':   'TYPE',
    'cputs':  'CPUTS',
    'clear':  'CLEAR',
}

# Words that require a call to a runtime routine.
RUNTIME_CALLS: dict[str, str] = {
    '/':      'vm_slash',
    'mod':    'vm_mod',
    '/mod':   'vm_slashmod',
    'and':    'vm_and',
    'or':     'vm_or',
    'xor':    'vm_xor',
    'not':    'vm_not',
    'lshift': 'vm_lshift',
    'rshift': 'vm_rshift',
    '<':      'vm_lt',
    '>':      'vm_gt',
    '0=':     'vm_zeq',
    '0<':     'vm_zlt',
    'over':   'vm_over',
    'swap':   'vm_swap',
    'rot':    'vm_rot',
    '2dup':   'vm_2dup',
    '2drop':  'vm_2drop',
    'i':      'vm_i',
    'j':      'vm_j',
    'cr':     'vm_cr',
    'space':  'vm_space',
    'spaces': 'vm_spaces',
    '.':      'vm_dot',
    'u.':     'vm_udot',
    'allot':  'vm_allot',
    'cells':  'vm_cells',
    'cell+':  'vm_cellplus',
    'here':   'vm_here',
    'count':  'vm_count',
    'move':   'vm_move',
    'fill':   'vm_fill',
}


class CodeGenError(Exception):
    def __init__(self, msg, node: ASTNode | None = None):
        if node:
            super().__init__(f"Line {node.line}, col {node.col}: {msg}")
        else:
            super().__init__(msg)
        self.node = node


@dataclass
class CodeGenerator:
    out:          TextIO = field(default_factory=io.StringIO)
    _label_count: int    = field(default=0, init=False)
    _constants:   dict   = field(default_factory=dict, init=False)
    _variables:   set    = field(default_factory=set, init=False)
    _words:       set    = field(default_factory=set, init=False)
    _str_count:   int    = field(default=0, init=False)
    _entry_word:  object = field(default=None, init=False)

    # ------------------------------------------------------------------
    # Public entry point
    # ------------------------------------------------------------------

    def generate(self, program: Program) -> str:
        # Pre-pass: find MainDirective to know which word to export.
        mains = [n for n in program.definitions if isinstance(n, MainDirective)]
        if len(mains) > 1:
            raise CodeGenError("Only one .main directive is allowed")
        self._entry_word = mains[0].word if mains else None

        self._emit_file_header()
        for node in program.definitions:
            self._top_def(node)
        self._emit_file_footer()
        if isinstance(self.out, io.StringIO):
            return self.out.getvalue()
        return ''

    # ------------------------------------------------------------------
    # Emit helpers
    # ------------------------------------------------------------------

    def _emit(self, line: str = ''):
        print(line, file=self.out)

    def _emit_instr(self, instr: str, comment: str = ''):
        if comment:
            self._emit(f'    {instr:<20} ; {comment}')
        else:
            self._emit(f'    {instr}')

    def _emit_label(self, label: str):
        self._emit(f'{label}:')

    def _fresh_label(self, prefix='L') -> str:
        self._label_count += 1
        return f'{prefix}_{self._label_count:04d}'

    # ------------------------------------------------------------------
    # File-level boilerplate
    # ------------------------------------------------------------------

    def _emit_file_header(self):
        self._emit('; Generated by forthc — do not edit by hand')
        self._emit()
        self._emit('; ca65 / 65816 mode — must appear before any .include')
        self._emit('        .p816')
        self._emit('        .smart  off')
        self._emit('        .A16')
        self._emit('        .I16')
        self._emit()
        self._emit('.include "vmachine.inc"')
        self._emit()

    def _emit_file_footer(self):
        self._emit()
        self._emit('; === end of generated code ===')

    # ------------------------------------------------------------------
    # Top-level definitions
    # ------------------------------------------------------------------

    def _top_def(self, node: ASTNode):
        if isinstance(node, ConstantDef):
            self._gen_constant(node)
        elif isinstance(node, VariableDef):
            self._gen_variable(node)
        elif isinstance(node, WordDef):
            self._gen_word(node)
        elif isinstance(node, OriginDirective):
            self._gen_origin(node)
        elif isinstance(node, SegmentDirective):
            self._gen_segment(node)
        elif isinstance(node, MainDirective):
            self._gen_main(node)
        else:
            raise CodeGenError(f"Unknown top-level node {type(node).__name__}", node)

    def _gen_constant(self, node: ConstantDef):
        sym = _mangle(node.name)
        self._emit(f'; constant {node.name}')
        self._emit(f'{sym} = {node.value}')
        self._emit()
        self._constants[node.name] = node.value

    def _gen_variable(self, node: VariableDef):
        sym = _mangle(node.name)
        self._emit(f'; variable {node.name}')
        self._emit_label(sym)
        self._emit_instr('.word 0', f'storage for variable {node.name}')
        self._emit()
        self._variables.add(node.name)

    def _gen_word(self, node: WordDef):
        self._words.add(node.name)
        sym = _mangle(node.name)
        self._emit(f'; word definition: {node.name}')
        if node.name == self._entry_word:
            self._emit(f'.export {sym}')
        self._emit_label(sym)
        str_pool: list[tuple[str, str]] = []
        self._gen_body(node.body, str_pool)
        self._emit_instr('EXIT', 'return from word')
        for lbl, text in str_pool:
            self._emit_label(lbl)
            escaped = text.replace('"', '\\"')
            self._emit(f'    .byte "{escaped}", 0')
        self._emit()

    def _gen_main(self, node: MainDirective):
        sym = _mangle(node.word)
        self._emit(f'; .main: export entry word for vmachine.s MAIN proc')
        self._emit(f'forth_main = {sym}')
        self._emit('.export forth_main')
        self._emit()

    def _gen_origin(self, node: OriginDirective):
        self._emit(f'; .origin ${node.address:X} — placement is controlled by the linker config')
        self._emit()

    def _gen_segment(self, node: SegmentDirective):
        self._emit(f'.segment "{node.name}"')
        self._emit()

    # ------------------------------------------------------------------
    # Body code generation
    # ------------------------------------------------------------------

    def _gen_body(self, stmts: list, str_pool: list):
        for stmt in stmts:
            self._gen_stmt(stmt, str_pool)

    def _gen_stmt(self, node: ASTNode, str_pool: list):
        if isinstance(node, NumberLit):
            self._emit_instr(f'LIT {node.value}', f'push {node.value}')

        elif isinstance(node, StringLit):
            lbl = self._fresh_str_label()
            str_pool.append((lbl, node.text))
            self._emit_instr(f'LIT {lbl}',            'push string address')
            self._emit_instr(f'LIT {len(node.text)}', 'push string length')

        elif isinstance(node, PrintString):
            lbl = self._fresh_str_label()
            str_pool.append((lbl, node.text))
            self._emit_instr(f'LIT {lbl}', f'print: "{node.text[:30]}"')
            self._emit_instr('CPUTS',      'print null-terminated string')

        elif isinstance(node, WordCall):
            self._gen_word_call(node)

        elif isinstance(node, IfThen):
            self._gen_if(node, str_pool)

        elif isinstance(node, BeginUntil):
            self._gen_begin_until(node, str_pool)

        elif isinstance(node, BeginWhileRepeat):
            self._gen_begin_while_repeat(node, str_pool)

        elif isinstance(node, DoLoop):
            self._gen_do_loop(node, str_pool)

        else:
            raise CodeGenError(f"Unknown statement node {type(node).__name__}", node)

    def _gen_word_call(self, node: WordCall):
        name = node.name

        # Inline VM primitive?
        if name in INLINE_OPS:
            instr = INLINE_OPS[name]
            self._emit_instr(instr, f'( {name} )')
            return

        # Runtime call?
        if name in RUNTIME_CALLS:
            target = RUNTIME_CALLS[name]
            self._emit_instr(f'CALL {target}', f'( {name} )')
            return

        # Known constant — compile-time fold to LIT
        if name in self._constants:
            val = self._constants[name]
            self._emit_instr(f'LIT {val}', f'constant {name} = {val}')
            return

        # Known user-defined word or variable — mangle the name
        sym = _mangle(name)
        self._emit_instr(f'CALL {sym}', f'call {name}')

    # ------------------------------------------------------------------
    # Control structures
    # ------------------------------------------------------------------

    def _gen_if(self, node: IfThen, str_pool: list):
        else_lbl = self._fresh_label('else')
        end_lbl  = self._fresh_label('endif')

        self._emit_instr(f'ZBRANCH {else_lbl}', 'if: branch if zero (false)')
        self._gen_body(node.consequent, str_pool)

        if node.alternate:
            self._emit_instr(f'CALL {end_lbl}', 'if: jump to endif')
            self._emit_label(else_lbl)
            self._gen_body(node.alternate, str_pool)
        else:
            self._emit_label(else_lbl)

        self._emit_label(end_lbl)

    def _gen_begin_until(self, node: BeginUntil, str_pool: list):
        top_lbl = self._fresh_label('begin')
        self._emit_label(top_lbl)
        self._gen_body(node.body, str_pool)
        self._emit_instr(f'ZBRANCH {top_lbl}',
                         'until: loop if top-of-stack is zero (false)')

    def _gen_begin_while_repeat(self, node: BeginWhileRepeat, str_pool: list):
        top_lbl = self._fresh_label('begin')
        end_lbl = self._fresh_label('repeat')
        self._emit_label(top_lbl)
        self._gen_body(node.test, str_pool)
        self._emit_instr(f'ZBRANCH {end_lbl}', 'while: exit if zero (false)')
        self._gen_body(node.body, str_pool)
        self._emit_instr(f'LIT 0',             'repeat: unconditional jump back')
        self._emit_instr(f'ZBRANCH {top_lbl}', 'repeat: loop back')
        self._emit_label(end_lbl)

    def _gen_do_loop(self, node: DoLoop, str_pool: list):
        top_lbl = self._fresh_label('do')
        end_lbl = self._fresh_label('loop')
        self._emit_instr('TOR',  'do: push index to R')
        self._emit_instr('TOR',  'do: push limit to R')
        self._emit_label(top_lbl)
        self._gen_body(node.body, str_pool)
        self._emit_instr('CALL vm_do_loop_step', 'loop: increment and test')
        self._emit_instr(f'ZBRANCH {top_lbl}',  'loop: branch if not done')
        self._emit_instr('RFROM', 'loop: discard limit from R')
        self._emit_instr('DROP',  'loop: drop limit')
        self._emit_label(end_lbl)

    # ------------------------------------------------------------------
    # String label helper
    # ------------------------------------------------------------------

    def _fresh_str_label(self) -> str:
        self._str_count += 1
        return f'_str_{self._str_count:04d}'


def generate(program: Program, out: TextIO | None = None) -> str:
    buf = io.StringIO()
    cg  = CodeGenerator(out=buf)
    text = cg.generate(program)
    if out is not None:
        out.write(text)
    return text
