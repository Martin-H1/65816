\ error_test.fs - Error handling and recovery regression tests

\ Verify failed definition does not consume dictionary space
VARIABLE HERE-BEFORE
HERE HERE-BEFORE !

\ ============================================================
\ CASE structure errors
\ ============================================================

\ ENDOF without matching OF
: BAD-ENDOF CASE 1 ENDOF ENDCASE ;
T{ RECOVERED? -> -1 }T

\ ENDCASE without matching CASE
: BAD-ENDCASE 1 ENDCASE ;
T{ RECOVERED? -> -1 }T

\ OF without matching CASE
: BAD-OF 1 OF 1 ENDOF ;
T{ RECOVERED? -> -1 }T

\ Now verify that memory wasn't leaked.
T{ HERE HERE-BEFORE @ = -> -1 }T

\ ============================================================
\ IF structure errors
\ ============================================================

\ THEN without IF
: BAD-THEN 1 THEN ;
T{ RECOVERED? -> -1 }T

\ ELSE without IF
: BAD-ELSE 1 ELSE 2 THEN ;
T{ RECOVERED? -> -1 }T

\ ============================================================
\ LOOP structure errors
\ ============================================================

\ LOOP without DO
: BAD-LOOP 1 LOOP ;
T{ RECOVERED? -> -1 }T

\ +LOOP without DO
: BAD-PLUSLOOP 1 +LOOP ;
T{ RECOVERED? -> -1 }T

\ ============================================================
\ BEGIN structure errors
\ ============================================================

\ AGAIN without BEGIN
: BAD-AGAIN 1 AGAIN ;
T{ RECOVERED? -> -1 }T

\ UNTIL without BEGIN
: BAD-UNTIL 1 UNTIL ;
T{ RECOVERED? -> -1 }T

\ REPEAT without BEGIN/WHILE
: BAD-REPEAT 1 REPEAT ;
T{ RECOVERED? -> -1 }T

\ ============================================================
\ Dictionary rollback verification
\ ============================================================

\ Verify failed definition does not consume dictionary space

HERE HERE-BEFORE !

: BAD-WORD UNDEFINED-WORD-XYZ ;

\ Now verify that memory wasn't leaked.
T{ HERE HERE-BEFORE @ = -> -1 }T

\ Verify successful definition after failed one works
: GOOD-WORD 42 ;
T{ GOOD-WORD -> 42 }T

\ Verify LATEST points to GOOD-WORD (9 character name)
T{ LATEST @ HEADER>NAME NIP -> 9 }T

DONE
