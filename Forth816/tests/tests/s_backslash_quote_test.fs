\ s_backslash_quote_test.fs - S\" escape sequence regression tests

\ Character constants from constants.inc
$07 CONSTANT BELL
$08 CONSTANT BKSP
$09 CONSTANT HTAB
$0A CONSTANT L_FEED
$0D CONSTANT C_RETURN

\ Basic string with no escapes
: STR-PLAIN S\" hello" ;
T{ STR-PLAIN NIP -> 5 }T

\ Newline escape
: STR-NEWLINE S\" hi\nbye" ;
T{ STR-NEWLINE NIP -> 6 }T
T{ STR-NEWLINE DROP 2 + C@ -> L_FEED }T

\ Carriage return escape
: STR-CR S\" hi\rbye" ;
T{ STR-CR NIP -> 6 }T
T{ STR-CR DROP 2 + C@ -> C_RETURN }T

\ Tab escape
: STR-TAB S\" hi\tbye" ;
T{ STR-TAB NIP -> 6 }T
T{ STR-TAB DROP 2 + C@ -> HTAB }T

\ Backslash escape
: STR-BACKSLASH S\" hi\\bye" ;
T{ STR-BACKSLASH NIP -> 6 }T
T{ STR-BACKSLASH DROP 2 + C@ -> $5C }T

\ Quote escape
: STR-QUOTE S\" hi\"bye" ;
T{ STR-QUOTE NIP -> 6 }T
T{ STR-QUOTE DROP 2 + C@ -> $22 }T

\ Null escape
: STR-NULL S\" hi\0bye" ;
T{ STR-NULL NIP -> 6 }T
T{ STR-NULL DROP 2 + C@ -> 0 }T

\ Bell escape
: STR-BELL S\" hi\abye" ;
T{ STR-BELL NIP -> 6 }T
T{ STR-BELL DROP 2 + C@ -> BELL }T

\ Backspace escape
: STR-BKSP S\" hi\bbye" ;
T{ STR-BKSP NIP -> 6 }T
T{ STR-BKSP DROP 2 + C@ -> BKSP }T

\ Multiple escapes
: STR-MULTI S\" \r\n" ;
T{ STR-MULTI NIP -> 2 }T
T{ STR-MULTI DROP C@ -> C_RETURN }T
T{ STR-MULTI DROP 1+ C@ -> L_FEED }T

\ Empty string
: STR-EMPTY S\" " ;
T{ STR-EMPTY NIP -> 0 }T

\ Escape at end of string
: STR-END S\" hello\n" ;
T{ STR-END NIP -> 6 }T
T{ STR-END DROP 5 + C@ -> L_FEED }T

DONE
