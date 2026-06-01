.main test-memory

: test-memory
    ." memory test: " cr
    create my-buffer 20 allot

    S" Hello from TYPE!" 
    cr
    ." done"
    cr
;
