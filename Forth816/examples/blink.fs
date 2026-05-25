\ LED blink sample using PBasic words
0 constant led_pin
1000 constant one_second

: blink
  ." Blink test welcome!" cr
  pbinit
  100 0 DO
    led_pin pbtoggle
    one_second pbpause
  loop
  ." Blink test goodbye!" cr  ;

blink
