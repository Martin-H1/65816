0 constant led_pin
1 constant button_pin

: button_demo PBINIT
  ." Button Demo Welcome!"
  max-int 0 do
    button_pin PBINX
    if
      led_pin PBHIGH
    else
      led_pin PBLOW
    then
  loop
  ." Button Demo Goodbye!" ;

button_demo
