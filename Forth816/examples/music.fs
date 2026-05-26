\ -----------------------------------------------------------------------------
\ Uses PBFREQOUT to generate sine waves and play music.
\ The circuit:
\ - piezo buzzer anode is attached to TG0 and TG1.
\ - piezo buzzer cathode is attached to ground header pin.
\
\ Martin Heermance <mheermance@gmail.com>
\ -----------------------------------------------------------------------------

\ Tone generator register value
\ N = (FCLK / (16 x F)) - 1
\ F = desired frequency
\ FCLK = FCLK input clock
\ Hz values for musical notes scaled for CPU cycles.

3686400. 2constant FCLK

FCLK 1000 FM/MOD constant ONE_MS     \ cycles per ms
drop

ONE_MS 1000 / constant ONE_US	     \ cycles per us

\ calc_freq( hz - cycles )
\ Note constant = (fclk / (16 * Hz)) - 1
: calc_freq
  FCLK d2/ d2/ d2/ d2/
  rot ud/mod
  drop swap drop
  1 - ;

31 calc_freq constant N_B0
33 calc_freq constant N_C1
35 calc_freq constant N_CS1
37 calc_freq constant N_D1
39 calc_freq constant N_DS1
41 calc_freq constant N_E1
44 calc_freq constant N_F1
46 calc_freq constant N_FS1
49 calc_freq constant N_G1
52 calc_freq constant N_GS1
55 calc_freq constant N_A1
58 calc_freq constant N_AS1
62 calc_freq constant N_B1
65 calc_freq constant N_C2
69 calc_freq constant N_CS2
73 calc_freq constant N_D2
78 calc_freq constant N_DS2
82 calc_freq constant N_E2
87 calc_freq constant N_F2
93 calc_freq constant N_FS2
98 calc_freq constant N_G2
104 calc_freq constant N_GS2
110 calc_freq constant N_A2
117 calc_freq constant N_AS2
123 calc_freq constant N_B2
131 calc_freq constant N_C3
139 calc_freq constant N_CS3
147 calc_freq constant N_D3
156 calc_freq constant N_DS3
165 calc_freq constant N_E3
175 calc_freq constant N_F3
185 calc_freq constant N_FS3
196 calc_freq constant N_G3
208 calc_freq constant N_GS3
220 calc_freq constant N_A3
233 calc_freq constant N_AS3
247 calc_freq constant N_B3
262 calc_freq constant N_C4
277 calc_freq constant N_CS4
294 calc_freq constant N_D4
311 calc_freq constant N_DS4
330 calc_freq constant N_E4
349 calc_freq constant N_F4
370 calc_freq constant N_FS4
392 calc_freq constant N_G4
415 calc_freq constant N_GS4
440 calc_freq constant N_A4
466 calc_freq constant N_AS4
494 calc_freq constant N_B4
523 calc_freq constant N_C5
554 calc_freq constant N_CS5
587 calc_freq constant N_D5
622 calc_freq constant N_DS5
659 calc_freq constant N_E5
698 calc_freq constant N_F5
740 calc_freq constant N_FS5
784 calc_freq constant N_G5
831 calc_freq constant N_GS5
880 calc_freq constant N_A5
932 calc_freq constant N_AS5
988 calc_freq constant N_B5
1047 calc_freq constant N_C6
1109 calc_freq constant N_CS6
1175 calc_freq constant N_D6
1245 calc_freq constant N_DS6
1319 calc_freq constant N_E6
1397 calc_freq constant N_F6
1480 calc_freq constant N_FS6
1568 calc_freq constant N_G6
1661 calc_freq constant N_GS6
1760 calc_freq constant N_A6
1865 calc_freq constant N_AS6
1976 calc_freq constant N_B6
2093 calc_freq constant N_C7
2217 calc_freq constant N_CS7
2349 calc_freq constant N_D7
2489 calc_freq constant N_DS7
2637 calc_freq constant N_E7
2794 calc_freq constant N_F7
2960 calc_freq constant N_FS7
3136 calc_freq constant N_G7
3322 calc_freq constant N_GS7
3520 calc_freq constant N_A7
3729 calc_freq constant N_AS7
3951 calc_freq constant N_B7
4186 calc_freq constant N_C8
4435 calc_freq constant N_CS8
4699 calc_freq constant N_D8
4978 calc_freq constant N_DS8

$ffff constant REST

2000                   constant D_WHOLE
D_WHOLE             2/ constant D_HALF
D_HALF              2/ constant D_QUARTER
D_QUARTER           2/ constant D_EIGHTH
D_HALF D_QUARTER     + constant D_DHALF
D_QUARTER D_EIGHTH   + constant D_DQUARTER
D_EIGHTH 2/ D_EIGHTH + constant D_DEIGHTH

0 constant TG0 \ Tone generator 0
1 constant TG1 \ Tone generator 1

create pachelbel
 N_FS4 , D_HALF ,     N_E4 ,  D_HALF ,
 N_D4 ,  D_HALF ,     N_CS4 , D_HALF ,
 N_B3 ,  D_HALF ,     N_A3 ,  D_HALF ,
 N_B3 ,  D_HALF ,     N_CS4 , D_HALF ,
 N_FS4 , D_HALF ,     N_E4 ,  D_HALF ,
 N_D4 ,  D_HALF ,     N_CS4 , D_HALF ,
 N_B3 ,  D_HALF ,     N_A3 ,  D_HALF ,
 N_B3 ,  D_HALF ,     N_CS4 , D_HALF ,
 N_D4 ,  D_HALF ,     N_CS4 , D_HALF ,
 N_B3 ,  D_HALF ,     N_A3 ,  D_HALF ,
 N_G3 ,  D_HALF ,     N_FS3 , D_HALF ,
 N_G3 ,  D_HALF ,     N_A3 ,  D_HALF ,
 N_D4 ,  D_QUARTER ,  N_FS4 , D_EIGHTH ,  N_G4 , D_EIGHTH ,  N_A4 , D_QUARTER , N_FS4 , D_EIGHTH ,  N_G4 , D_EIGHTH ,
 N_A4 ,  D_QUARTER ,  N_B3 ,  D_EIGHTH ,  N_CS4 , D_EIGHTH ,  N_D4 , D_EIGHTH ,  N_E4 , D_EIGHTH ,  N_FS4 , D_EIGHTH ,  N_G4 , D_EIGHTH ,
 N_FS4 , D_QUARTER ,  N_D4 ,  D_EIGHTH ,  N_E4 , D_EIGHTH ,  N_FS4 , D_QUARTER ,  N_FS3 , D_EIGHTH ,  N_G3 ,  D_EIGHTH ,
 N_A3 ,  D_EIGHTH ,  N_G3 ,   D_EIGHTH ,  N_FS3 , D_EIGHTH ,  N_G3 , D_EIGHTH ,  N_A3 , D_HALF ,
 N_G3 ,  D_QUARTER ,  N_B3 ,  D_EIGHTH ,  N_A3 , D_EIGHTH ,  N_G3 , D_QUARTER ,  N_FS3 ,  D_EIGHTH ,  N_E3 , D_EIGHTH ,
 N_FS3 , D_QUARTER ,  N_D3 ,  D_EIGHTH ,  N_E3 , D_EIGHTH ,  N_FS3 , D_EIGHTH ,  N_G3 ,  D_EIGHTH ,   N_A3 ,  D_EIGHTH ,  N_B3 , D_EIGHTH ,
 N_G3 ,  D_QUARTER ,  N_B3 ,  D_EIGHTH ,  N_A3 , D_EIGHTH ,  N_B3 , D_QUARTER ,  N_CS4 ,  D_EIGHTH ,  N_D4 ,  D_EIGHTH ,
 N_A3 ,  D_EIGHTH ,  N_B3 ,   D_EIGHTH ,  N_CS4 , D_EIGHTH ,  N_D4 , D_EIGHTH ,  N_E4 , D_EIGHTH ,  N_FS4 , D_EIGHTH ,  N_G4 , D_EIGHTH ,  N_A4 , D_HALF ,
 N_A4 ,  D_QUARTER ,  N_FS4 , D_EIGHTH ,  N_G4 , D_EIGHTH ,  N_A4 , D_QUARTER ,
 N_FS4 , D_EIGHTH ,  N_G4 ,   D_EIGHTH ,  N_A4 , D_EIGHTH ,  N_A3 , D_EIGHTH ,  N_B3 , D_EIGHTH ,  N_CS4 , D_EIGHTH ,
 N_D4 ,  D_EIGHTH ,  N_E4 ,   D_EIGHTH ,  N_FS4 , D_EIGHTH ,  N_G4 , D_EIGHTH ,  N_FS4 , D_QUARTER ,  N_D4 , D_EIGHTH ,  N_E4 , D_EIGHTH ,
 N_FS4 , D_EIGHTH ,  N_CS4 ,  D_EIGHTH ,  N_A3 , D_EIGHTH ,  N_A3 , D_EIGHTH ,
 N_CS4 , D_QUARTER ,  N_B3 ,  D_QUARTER ,  N_D4 , D_EIGHTH ,  N_CS4 , D_EIGHTH ,  N_B3 , D_QUARTER ,
 N_A3 ,  D_EIGHTH ,  N_G3 ,   D_EIGHTH ,  N_A3 , D_QUARTER ,  N_D3 , D_EIGHTH ,  N_E3 , D_EIGHTH ,  N_FS3 , D_EIGHTH ,  N_G3 , D_EIGHTH ,
 N_A3 ,  D_EIGHTH ,  N_B3 ,   D_QUARTER ,  N_G3 , D_QUARTER ,  N_B3 , D_EIGHTH ,  N_A3 , D_EIGHTH ,  N_B3 , D_QUARTER ,
 N_CS4 , D_EIGHTH ,  N_D4 ,   D_EIGHTH ,  N_A3 , D_EIGHTH ,  N_B3 , D_EIGHTH ,  N_CS4 , D_EIGHTH ,  N_D4 , D_EIGHTH ,  N_E4 , D_EIGHTH ,
 N_FS4 , D_EIGHTH ,  N_G4 ,   D_EIGHTH ,  N_A4 , D_HALF ,
 0 , 0 ,

\ ( i -- n t )
: get_note_and_duration
  dup pachelbel + @
  swap cell+ pachelbel + @ ;

: play_song
  PBINIT
  0 begin
    dup get_note_and_duration
    ?dup 0<> if
      TG0 -rot PBFREQOUT
    else
      exit
    then
    cell+ cell+
  again
  drop ;

play_song
