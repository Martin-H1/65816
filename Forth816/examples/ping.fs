\ -----------------------------------------------------------------------------
\ Ping))) sensor sample for Forth
\ Read a PING))) ultrasonic rangefinder and return the distance to the closest
\ object in range. Do this by sending a pulse to the sensor to initiate a
\ reading, then listens for a pulse to return. The length of the returning
\ pulse is proportional to the distance of the object from the sensor.
\ The circuit:
\ - Ping))) control pin is attached to VIA port B pin 0.
\ - Ping))) power and ground are connected to respective VIA header pins.
\
\ Notes:
\ - Ping))) draws too much current for USB power. You must use battery power.
\
\ - For more information on Ping))) read:
\   https://www.parallax.com/package/ping-ultrasonic-distance-sensor-downloads/
\
\ Martin Heermance <mheermance@gmail.com>
\ -----------------------------------------------------------------------------

3686400. 2constant FCLK

FCLK 1000 FM/MOD constant ONE_MS     \ cycles per ms
drop

ONE_MS 1000 / constant ONE_US	     \ cycles per us

8 constant PING_PIN		\ Port B pin 0

ONE_US 5 * constant PULSE_WIDTH	\ Ping))) activated by a pulse of 2 or more uS

\ Parallax's Ping))) datasheet says there are 73.746 microseconds per inch
\ To get the distance divide the pulse width by 2 times a scaling factor.
\ It's two times because of pulse outbound and return time.
ONE_US 74 2 * * constant INCH_SCALE_FACTOR

; The speed of sound is 340 m/s or 29 microseconds per centimeter. The pulse
; travels out and back, so again we divide by two times a scaling factor.
ONE_US 29 2 * * constant CM_SCALE_FACTOR

PBINIT				\ one time library initialization

: main
  20000 0 do
    PING_PIN PBLOW		\ Set the pun low then send a puls out
    PING_PIN PULSE_WIDTH PBPULSOUT
    PING_PIN FALSE PBPULSIN	\ Wait for the echo
    dup ." Cycles=" U.
    dup INCH_SCALE_FACTOR /
    ." inches=" U.
    CM_SCALE_FACTOR /
    ." , cm=" U.    
  loop ;
