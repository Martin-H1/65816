.main output-test

: output-test
    hello
    test-type
;

: hello
    ." Hello world!"
    cr
;

: test-type
    ." cputs test: "
    S" Hello from TYPE!" type
    cr
    ." done"
    cr
;
