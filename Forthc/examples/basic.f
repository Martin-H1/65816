\ examples/basic.f — demonstrates the constructs from the design doc

\ Constant definition:  "15 constant foo" → "foo = 15"
15 constant foo

\ Word definition:  ": foo 2 3 * ;"
: multiply-demo
    2 3 *
;

\ A word that uses the constant
: show-foo
    foo .
    cr
;

\ If/then/else
: max   ( n1 n2 -- max )
    over over < if
        swap
    then
    drop
;

\ Begin/until loop — count down from n to 1
: countdown   ( n -- )
    begin
        dup .
        cr
        1 -
        dup 0 =
    until
    drop
;

\ Variable usage
variable counter

: increment-counter
    counter @
    1 +
    counter !
;

: reset-counter
    0 counter !
;

: get-counter  ( -- n )
    counter @
;

\ String output
: say-hello
    ." Hello, World!"
    cr
;
