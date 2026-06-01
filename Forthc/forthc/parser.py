"""
Recursive-descent parser for the Forth-like compiler.

Grammar (informal):

  program       ::= top_def* EOF
  top_def       ::= constant_def
                  | variable_def
                  | word_def
                  | origin_dir
                  | segment_dir
  constant_def  ::= NUMBER 'constant' NAME
  variable_def  ::= 'variable' NAME
  word_def      ::= ':' NAME body ';'
  origin_dir    ::= '.origin' NUMBER
  segment_dir   ::= '.segment' (STRING | WORD)
  body          ::= stmt*
  stmt          ::= NUMBER
                  | STRING_LIT
                  | PRINT_STRING
                  | if_stmt
                  | begin_stmt
                  | do_stmt
                  | WORD            ; any other word is a call
"""

from .tokenizer import Token, TType, TokenizeError
from .ast_nodes import (
    Program, ConstantDef, VariableDef, WordDef,
    OriginDirective, SegmentDirective, MainDirective,
    NumberLit, StringLit, PrintString, WordCall,
    IfThen, BeginUntil, BeginWhileRepeat, DoLoop,
)


class ParseError(Exception):
    def __init__(self, msg, token: Token):
        super().__init__(f"Line {token.line}, col {token.col}: {msg} (got {token.type.name} {token.value!r})")
        self.token = token


class Parser:
    def __init__(self, tokens: list[Token]):
        self._tokens = tokens
        self._pos    = 0

    # ------------------------------------------------------------------
    # Helpers
    # ------------------------------------------------------------------

    def _peek(self) -> Token:
        return self._tokens[self._pos]

    def _advance(self) -> Token:
        tok = self._tokens[self._pos]
        if tok.type != TType.EOF:
            self._pos += 1
        return tok

    def _expect(self, ttype: TType) -> Token:
        tok = self._peek()
        if tok.type != ttype:
            raise ParseError(f"Expected {ttype.name}", tok)
        return self._advance()

    def _match(self, *types: TType) -> bool:
        return self._peek().type in types

    # ------------------------------------------------------------------
    # Top level
    # ------------------------------------------------------------------

    def parse(self) -> Program:
        defs = []
        while not self._match(TType.EOF):
            node = self._top_def()
            if node is not None:
                defs.append(node)
        return Program(definitions=defs)

    def _top_def(self):
        tok = self._peek()

        if tok.type == TType.NUMBER:
            # Could be  <number> constant <name>
            num_tok = self._advance()
            if self._match(TType.CONSTANT):
                self._advance()  # consume 'constant'
                name_tok = self._expect(TType.WORD)
                return ConstantDef(name=name_tok.value, value=num_tok.value,
                                   line=num_tok.line, col=num_tok.col)
            else:
                raise ParseError(
                    "Bare number at top level must be followed by 'constant'",
                    num_tok)

        if tok.type == TType.VARIABLE:
            self._advance()
            name_tok = self._expect(TType.WORD)
            return VariableDef(name=name_tok.value, line=tok.line, col=tok.col)

        if tok.type == TType.COLON:
            return self._word_def()

        if tok.type == TType.ORIGIN:
            self._advance()
            addr_tok = self._expect(TType.NUMBER)
            return OriginDirective(address=addr_tok.value,
                                   line=tok.line, col=tok.col)

        if tok.type == TType.SEGMENT:
            self._advance()
            # segment name can be a quoted string or a bare word
            seg_tok = self._peek()
            if seg_tok.type in (TType.SQUOTE, TType.DOTQUOTE, TType.WORD):
                self._advance()
                return SegmentDirective(name=str(seg_tok.value),
                                        line=tok.line, col=tok.col)
            raise ParseError("Expected segment name", seg_tok)

        if tok.type == TType.MAIN:
            self._advance()
            word_tok = self._expect(TType.WORD)
            return MainDirective(word=word_tok.value,
                                 line=tok.line, col=tok.col)

        raise ParseError("Unexpected token at top level", tok)

    # ------------------------------------------------------------------
    # Word definition
    # ------------------------------------------------------------------

    def _word_def(self) -> WordDef:
        colon_tok = self._advance()            # consume ':'
        name_tok  = self._expect(TType.WORD)   # word name
        body      = self._body()
        self._expect(TType.SEMICOLON)
        return WordDef(name=name_tok.value, body=body,
                       line=colon_tok.line, col=colon_tok.col)

    # ------------------------------------------------------------------
    # Body (list of statements)
    # ------------------------------------------------------------------

    def _body(self) -> list:
        stmts = []
        while not self._match(TType.SEMICOLON, TType.ELSE,
                               TType.THEN, TType.UNTIL,
                               TType.WHILE, TType.REPEAT,
                               TType.LOOP, TType.EOF):
            stmts.append(self._stmt())
        return stmts

    def _stmt(self):
        tok = self._peek()

        if tok.type == TType.NUMBER:
            self._advance()
            return NumberLit(value=tok.value, line=tok.line, col=tok.col)

        if tok.type == TType.SQUOTE:
            self._advance()
            return StringLit(text=tok.value, line=tok.line, col=tok.col)

        if tok.type == TType.DOTQUOTE:
            self._advance()
            return PrintString(text=tok.value, line=tok.line, col=tok.col)

        if tok.type == TType.IF:
            return self._if_stmt()

        if tok.type == TType.BEGIN:
            return self._begin_stmt()

        if tok.type == TType.DO:
            return self._do_stmt()

        if tok.type == TType.WORD:
            self._advance()
            return WordCall(name=tok.value, line=tok.line, col=tok.col)

        # Bare number inside a body is valid
        if tok.type == TType.NUMBER:
            self._advance()
            return NumberLit(value=tok.value, line=tok.line, col=tok.col)

        raise ParseError("Unexpected token in word body", tok)

    # ------------------------------------------------------------------
    # Control structures
    # ------------------------------------------------------------------

    def _if_stmt(self) -> IfThen:
        if_tok = self._advance()              # consume 'if'
        consequent = self._body()
        alternate  = []
        if self._match(TType.ELSE):
            self._advance()                   # consume 'else'
            alternate = self._body()
        self._expect(TType.THEN)
        return IfThen(consequent=consequent, alternate=alternate,
                      line=if_tok.line, col=if_tok.col)

    def _begin_stmt(self):
        begin_tok = self._advance()           # consume 'begin'

        # Collect stmts until 'while' or 'until'
        first_body = self._body()

        if self._match(TType.UNTIL):
            self._advance()
            return BeginUntil(body=first_body,
                              line=begin_tok.line, col=begin_tok.col)

        if self._match(TType.WHILE):
            self._advance()
            loop_body = self._body()
            self._expect(TType.REPEAT)
            return BeginWhileRepeat(test=first_body, body=loop_body,
                                    line=begin_tok.line, col=begin_tok.col)

        raise ParseError("Expected 'until' or 'while' after 'begin' body",
                         self._peek())

    def _do_stmt(self) -> DoLoop:
        do_tok = self._advance()              # consume 'do'
        body   = self._body()
        self._expect(TType.LOOP)
        return DoLoop(body=body, line=do_tok.line, col=do_tok.col)


def parse(tokens: list[Token]) -> Program:
    return Parser(tokens).parse()
