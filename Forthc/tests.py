"""
Tests for the forthc compiler pipeline.
Run with:  python -m pytest tests.py -v
       or:  python tests.py
"""

import sys, os
sys.path.insert(0, os.path.dirname(__file__))

from forthc import tokenize, parse, generate, compile_source, TType
from forthc.tokenizer import TokenizeError
from forthc.parser    import ParseError


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def tok_types(src):
    return [t.type for t in tokenize(src) if t.type != TType.EOF]

def tok_values(src):
    return [(t.type, t.value) for t in tokenize(src) if t.type != TType.EOF]

def asm(src):
    return compile_source(src)

def lines(src):
    return [l.strip() for l in asm(src).splitlines() if l.strip() and not l.startswith(';')]


# ===========================================================================
# TOKENIZER
# ===========================================================================

def test_decimal_number():
    toks = tok_values('42')
    assert toks == [(TType.NUMBER, 42)]

def test_negative_number():
    toks = tok_values('-7')
    assert toks == [(TType.NUMBER, -7)]

def test_hex_0x():
    toks = tok_values('0xFF')
    assert toks == [(TType.NUMBER, 255)]

def test_hex_dollar():
    toks = tok_values('$FF00')
    assert toks == [(TType.NUMBER, 0xFF00)]

def test_binary():
    toks = tok_values('0b1010')
    assert toks == [(TType.NUMBER, 10)]

def test_keyword_colon():
    assert TType.COLON in tok_types(':')

def test_keyword_semicolon():
    assert TType.SEMICOLON in tok_types(';')

def test_keyword_constant():
    assert TType.CONSTANT in tok_types('constant')

def test_keyword_variable():
    assert TType.VARIABLE in tok_types('variable')

def test_keyword_if():
    assert TType.IF in tok_types('if')

def test_keyword_case_insensitive():
    assert TType.IF in tok_types('IF')
    assert TType.CONSTANT in tok_types('CONSTANT')

def test_line_comment_ignored():
    toks = tok_types('\\ this is a comment\n42')
    assert toks == [TType.NUMBER]

def test_paren_comment_ignored():
    toks = tok_values('( this is ignored ) 99')
    assert toks == [(TType.NUMBER, 99)]

def test_dotquote_string():
    toks = tok_values('." hello world"')
    assert toks == [(TType.DOTQUOTE, 'hello world')]

def test_squote_string():
    toks = tok_values('S" greetings"')
    assert toks == [(TType.SQUOTE, 'greetings')]

def test_word_token():
    toks = tok_values('dup')
    assert toks == [(TType.WORD, 'dup')]

def test_origin_keyword():
    assert TType.ORIGIN in tok_types('.origin')

def test_segment_keyword():
    assert TType.SEGMENT in tok_types('.segment')

def test_multiple_tokens():
    types = tok_types(': foo 1 2 + ;')
    assert types == [TType.COLON, TType.WORD, TType.NUMBER, TType.NUMBER,
                     TType.WORD, TType.SEMICOLON]


# ===========================================================================
# PARSER
# ===========================================================================

from forthc.ast_nodes import (
    ConstantDef, VariableDef, WordDef,
    NumberLit, WordCall, IfThen, BeginUntil, DoLoop,
    OriginDirective, SegmentDirective, PrintString, StringLit,
)

def test_parse_constant():
    prog = parse(tokenize('15 constant foo'))
    assert len(prog.definitions) == 1
    d = prog.definitions[0]
    assert isinstance(d, ConstantDef)
    assert d.name == 'foo'
    assert d.value == 15

def test_parse_variable():
    prog = parse(tokenize('variable bar'))
    d = prog.definitions[0]
    assert isinstance(d, VariableDef)
    assert d.name == 'bar'

def test_parse_word_empty_body():
    prog = parse(tokenize(': noop ;'))
    d = prog.definitions[0]
    assert isinstance(d, WordDef)
    assert d.name == 'noop'
    assert d.body == []

def test_parse_word_with_literals():
    prog = parse(tokenize(': two 2 ;'))
    d = prog.definitions[0]
    assert isinstance(d, WordDef)
    assert len(d.body) == 1
    assert isinstance(d.body[0], NumberLit)
    assert d.body[0].value == 2

def test_parse_word_calls():
    prog = parse(tokenize(': demo dup drop ;'))
    body = prog.definitions[0].body
    assert isinstance(body[0], WordCall) and body[0].name == 'dup'
    assert isinstance(body[1], WordCall) and body[1].name == 'drop'

def test_parse_if_then():
    prog = parse(tokenize(': test 1 if drop then ;'))
    body = prog.definitions[0].body
    assert any(isinstance(n, IfThen) for n in body)

def test_parse_if_else_then():
    prog = parse(tokenize(': test 1 if 2 else 3 then ;'))
    body = prog.definitions[0].body
    ift = next(n for n in body if isinstance(n, IfThen))
    assert len(ift.consequent) == 1
    assert len(ift.alternate) == 1

def test_parse_begin_until():
    prog = parse(tokenize(': counter begin dup 0 = until ;'))
    body = prog.definitions[0].body
    assert any(isinstance(n, BeginUntil) for n in body)

def test_parse_do_loop():
    prog = parse(tokenize(': counting 10 0 do i loop ;'))
    body = prog.definitions[0].body
    assert any(isinstance(n, DoLoop) for n in body)

def test_parse_origin():
    prog = parse(tokenize('.origin $8000'))
    d = prog.definitions[0]
    assert isinstance(d, OriginDirective)
    assert d.address == 0x8000

def test_parse_segment():
    prog = parse(tokenize('.segment CODE'))
    d = prog.definitions[0]
    assert isinstance(d, SegmentDirective)
    assert d.name == 'code'

def test_parse_print_string():
    prog = parse(tokenize(': hi ." hello" ;'))
    body = prog.definitions[0].body
    assert isinstance(body[0], PrintString)
    assert body[0].text == 'hello'

def test_parse_string_literal():
    prog = parse(tokenize(': hi S" world" type ;'))
    body = prog.definitions[0].body
    assert isinstance(body[0], StringLit)
    assert body[0].text == 'world'

def test_parse_error_bare_number():
    try:
        parse(tokenize('42'))
        assert False, "Should have raised ParseError"
    except ParseError:
        pass

def test_parse_multiple_words():
    prog = parse(tokenize(': a 1 ; : b 2 ;'))
    assert len(prog.definitions) == 2


# ===========================================================================
# CODE GENERATION
# ===========================================================================

def test_codegen_constant():
    out = asm('15 constant foo')
    assert 'foo = 15' in out

def test_codegen_constant_inline_fold():
    """Constants used inside words should be folded to LIT."""
    out = asm('7 constant width\n: test width ;')
    assert 'LIT 7' in out
    assert 'constant width = 7' in out

def test_codegen_variable():
    out = asm('variable x')
    assert 'x:' in out
    assert '.word 0' in out

def test_codegen_lit():
    out = asm(': test 42 ;')
    assert 'LIT 42' in out

def test_codegen_exit():
    out = asm(': test ;')
    assert 'EXIT' in out

def test_codegen_inline_ops():
    """Primitive words should expand inline, not via CALL."""
    cases = {
        'dup':  'DUP',
        'drop': 'DROP',
        'nip':  'NIP',
        '+':    'ADD',
        '-':    'SUB',
        '*':    'STAR',
        '=':    'EQ',
        '@':    'FETCH',
        '!':    'STORE',
        'c@':   'BFETCH',
        'c!':   'BSTORE',
        '>r':   'TOR',
        'r>':   'RFROM',
        'emit': 'EMIT',
        'key':  'KEY',
        'type': 'TYPE',
        'cputs':'CPUTS',
    }
    for word, instr in cases.items():
        out = asm(f': test {word} ;')
        assert instr in out, f"Expected {instr} for word '{word}'"

def test_codegen_runtime_call():
    """Complex words should generate CALL vm_xxx."""
    out = asm(': test swap ;')
    assert 'CALL vm_swap' in out

def test_codegen_word_def_label():
    out = asm(': my-word ;')
    assert 'my_word:' in out

def test_codegen_if_then():
    out = asm(': test if drop then ;')
    assert 'ZBRANCH' in out

def test_codegen_if_else_then():
    out = asm(': test if 1 else 2 then ;')
    assert 'ZBRANCH' in out
    # Should have an else label and an endif label
    assert 'else_' in out
    assert 'endif_' in out

def test_codegen_begin_until():
    out = asm(': test begin dup until ;')
    assert 'begin_' in out
    assert 'ZBRANCH' in out

def test_codegen_print_string():
    out = asm(': test ." hi" ;')
    assert 'CPUTS' in out
    assert '.byte "hi", 0' in out

def test_codegen_string_literal():
    out = asm(': test S" abc" type ;')
    assert 'LIT _str_' in out
    assert '.byte "abc", 0' in out

def test_codegen_origin():
    out = asm('.origin $C000')
    assert '.origin $C000' in out  # becomes a comment, linker controls placement

def test_codegen_segment():
    out = asm('.segment CODE')
    assert '.segment "code"' in out

def test_codegen_variable_fetch():
    """Variable address pushed via CALL, then FETCHed."""
    out = asm('variable x\n: test x @ ;')
    assert 'CALL x' in out
    assert 'FETCH' in out

def test_codegen_forward_reference():
    """Words not yet defined generate a forward CALL."""
    out = asm(': a b ;')
    assert 'CALL b' in out

def test_codegen_include_header():
    out = asm(': x ;')
    assert '.include "vmachine.inc"' in out

def test_codegen_string_after_exit():
    """String pool should be emitted after EXIT, before next word."""
    out = asm(': a ." test" ;\n: b ;')
    a_exit   = out.index('EXIT',   out.index('a:'))
    str_byte = out.index('.byte',  out.index('a:'))
    b_label  = out.index('b:')
    assert a_exit < str_byte < b_label



def test_tokenize_main_keyword():
    assert TType.MAIN in tok_types('.main')

def test_parse_main_directive():
    from forthc.ast_nodes import MainDirective
    prog = parse(tokenize('.main foo'))
    d = prog.definitions[0]
    assert isinstance(d, MainDirective)
    assert d.word == 'foo'

def test_codegen_main_proc():
    out = asm('.origin $4000\n.main myprog\n: myprog ;')
    assert 'forth_main = myprog' in out
    assert '.export forth_main' in out
    assert '.export myprog' in out

def test_codegen_main_after_org():
    out = asm('.origin $4000\n.main foo\n: foo ;')
    # forth_main alias should appear before the word definition
    alias_pos = out.index('forth_main = foo')
    foo_pos   = out.index('foo:')
    assert alias_pos < foo_pos

def test_codegen_main_mangles_name():
    out = asm('.main my-entry\n: my-entry ;')
    assert 'forth_main = my_entry' in out
    assert '.export my_entry' in out

# ===========================================================================
# END-TO-END INTEGRATION
# ===========================================================================

SAMPLE_PROGRAM = """
.origin $8000

10 constant limit

variable acc

: reset   0 acc ! ;
: add-to-acc   ( n -- )  acc @ + acc ! ;
: sum-to-limit ( -- )
    reset
    1
    begin
        dup add-to-acc
        1 +
        dup limit >
    until
    drop
;
: main
    sum-to-limit
    acc @ .
    cr
;
"""

def test_integration_full_program():
    out = asm(SAMPLE_PROGRAM)
    assert 'limit = 10' in out
    assert 'acc:' in out
    assert 'reset:' in out
    assert 'add_to_acc:' in out
    assert 'sum_to_limit:' in out
    assert 'main:' in out
    assert '.origin $8000' in out  # becomes a comment


# ===========================================================================
# Runner
# ===========================================================================

if __name__ == '__main__':
    import traceback
    tests = {k: v for k, v in globals().items() if k.startswith('test_')}
    passed = failed = 0
    for name, fn in sorted(tests.items()):
        try:
            fn()
            print(f"  PASS  {name}")
            passed += 1
        except Exception as e:
            print(f"  FAIL  {name}")
            traceback.print_exc()
            failed += 1
    print(f"\n{passed} passed, {failed} failed out of {passed+failed} tests.")
    sys.exit(0 if failed == 0 else 1)
