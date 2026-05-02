\ harness_test.fs - validates the test harness itself

\ Should pass
T{ 1 2 SWAP -> 2 1 }T

\ Should fail with INCORRECT RESULT
T{ 1 2 SWAP -> 1 2 }T

\ Should fail with WRONG NUMBER OF RESULTS
T{ 1 2 SWAP -> 1 2 3 }T

DONE
