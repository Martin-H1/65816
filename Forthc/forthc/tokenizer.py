r"""
Forth tokenizer.

Forth is unusual: whitespace-delimited tokens, with a few words
(like ':' and 'constant') that change how subsequent tokens are read.
Comments are ( ... ) and \ to end-of-line.
Strings are introduced by ." and S" and end at the closing ".
r"""

from dataclasses import dataclass
from enum import Enum, auto
from typing import Iterator


class TType(Enum):
    WORD        = auto()   # any bare token
    NUMBER      = auto()   # integer literal (dec, hex 0x/$, binary 0b...)
    STRING      = auto()   # ." or S" payload
    COLON       = auto()   # :
    SEMICOLON   = auto()   # ;
    CONSTANT    = auto()   # constant
    VARIABLE    = auto()   # variable
    IF          = auto()   # if
    ELSE        = auto()   # else
    THEN        = auto()   # then
    BEGIN       = auto()   # begin
    UNTIL       = auto()   # until
    WHILE       = auto()   # while
    REPEAT      = auto()   # repeat
    DO          = auto()   # do
    LOOP        = auto()   # loop
    DOTQUOTE    = auto()   # ."  (print string literal)
    SQUOTE      = auto()   # S"  (string literal onto stack)
    ORIGIN      = auto()   # .origin  (extension: set origin address)
    SEGMENT     = auto()   # .segment (extension: set segment name)
    MAIN        = auto()   # .main    (extension: designate entry-point word)
    EOF         = auto()


KEYWORD_MAP = {
    ':':        TType.COLON,
    ';':        TType.SEMICOLON,
    'constant': TType.CONSTANT,
    'variable': TType.VARIABLE,
    'if':       TType.IF,
    'else':     TType.ELSE,
    'then':     TType.THEN,
    'begin':    TType.BEGIN,
    'until':    TType.UNTIL,
    'while':    TType.WHILE,
    'repeat':   TType.REPEAT,
    'do':       TType.DO,
    'loop':     TType.LOOP,
    '.origin':  TType.ORIGIN,
    '.segment': TType.SEGMENT,
    '.main':    TType.MAIN,
}


@dataclass
class Token:
    type:   TType
    value:  object          # str | int
    line:   int
    col:    int

    def __repr__(self):
        return f"Token({self.type.name}, {self.value!r}, {self.line}:{self.col})"


class TokenizeError(Exception):
    def __init__(self, msg, line, col):
        super().__init__(f"Line {line}, col {col}: {msg}")
        self.line = line
        self.col  = col


def _parse_number(s: str) -> 'int | None':
    """Try to parse s as an integer.
    Supports: decimal, 0x/$ hex, 0b binary, and negative variants.
    """
    try:
        if s.startswith('0x') or s.startswith('0X'):
            return int(s[2:], 16)
        if s.startswith('0b') or s.startswith('0B'):
            return int(s[2:], 2)
        if s.startswith('$'):       # assembler-style hex: $8000
            return int(s[1:], 16)
        if s.startswith('#$'):      # 65xxx immediate hex: #$FF
            return int(s[2:], 16)
        return int(s)
    except ValueError:
        if s.startswith('-'):
            inner = _parse_number(s[1:])
            return -inner if inner is not None else None
        return None


def tokenize(source: str) -> list:
    tokens = []
    pos    = 0
    line   = 1
    col    = 1
    n      = len(source)

    def advance(count=1):
        nonlocal pos, line, col
        for _ in range(count):
            if pos < n:
                if source[pos] == '\n':
                    line += 1
                    col   = 1
                else:
                    col += 1
                pos += 1

    def skip_line_comment():
        while pos < n and source[pos] != '\n':
            advance()

    def skip_paren_comment():
        depth = 1
        start_line, start_col = line, col
        advance()  # skip opening (
        while pos < n:
            ch = source[pos]
            if ch == '(':
                depth += 1
                advance()
            elif ch == ')':
                depth -= 1
                advance()
                if depth == 0:
                    return
            else:
                advance()
        raise TokenizeError("Unterminated ( comment", start_line, start_col)

    def read_string(intro: str) -> str:
        start_line, start_col = line, col
        buf = []
        while pos < n:
            ch = source[pos]
            if ch == '"':
                advance()
                return ''.join(buf)
            buf.append(ch)
            advance()
        raise TokenizeError(f'Unterminated {intro}" string', start_line, start_col)

    while pos < n:
        # Skip whitespace
        if source[pos] in ' \t\r\n':
            advance()
            continue

        # Line comment
        if source[pos] == '\\':
            skip_line_comment()
            continue

        # Paren comment  ( ... )
        if source[pos] == '(':
            if pos + 1 < n and source[pos + 1] in ' \t\r\n)':
                skip_paren_comment()
                continue

        tok_line, tok_col = line, col

        # String literals: ." or S"
        if source[pos:pos+2] in ('."', 'S"', 's"'):
            intro = source[pos:pos+2].upper()
            advance(2)
            # consume exactly one space separator
            if pos < n and source[pos] == ' ':
                advance()
            payload = read_string(intro)
            ttype = TType.DOTQUOTE if intro == '."' else TType.SQUOTE
            tokens.append(Token(ttype, payload, tok_line, tok_col))
            continue

        # Read a bare whitespace-delimited word
        buf = []
        while pos < n and source[pos] not in ' \t\r\n':
            buf.append(source[pos])
            advance()
        word = ''.join(buf)
        if not word:
            continue

        word_lower = word.lower()

        # Check keywords (case-insensitive)
        if word_lower in KEYWORD_MAP:
            tokens.append(Token(KEYWORD_MAP[word_lower], word_lower, tok_line, tok_col))
            continue

        # Try number
        num = _parse_number(word)
        if num is not None:
            tokens.append(Token(TType.NUMBER, num, tok_line, tok_col))
            continue

        # Otherwise a plain word
        tokens.append(Token(TType.WORD, word_lower, tok_line, tok_col))

    tokens.append(Token(TType.EOF, None, line, col))
    return tokens
