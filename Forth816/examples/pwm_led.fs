0 constant led_pin
50 constant duration

\ PBPWM ( p u1 u2 -- ) converts a digital value (0-255) to analog output via
\   p  - index (0-15) of the I/O pin to set.
\   u1 - the duty (0-255) of analog output as the number of 256ths of 5V.
\   u2 - the duration of the PWM output in mS.

: brighter
  ." get slowly brighter" CR
  255 0 do
    led_pin i duration pbpwm
  loop ;

: dimmer
  ." get slowly dimmer" CR
  255 0 do
    led_pin 255 i - duration pbpwm
  loop ;

: pwm_demo PBINIT
  ." PWM Demo Welcome!" CR
  pbinit
  brighter
  dimmer
  ." PWM Demo Goodbye!" CR ;

pwm_demo
