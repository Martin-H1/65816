include ../common.mk

EXAMPLES = \
	blink.srec \
	button.srec \
	echo.srec \
	helloWorld.srec \
	ping.srec \
	qti.srec \
	servo.srec

all: $(EXAMPLES)

%.srec : %.bin
	$(SREC_CAT) -address-length=3 -execution_start_address 0x000300 $< -binary -offset 0x0300 -O -Motorola -DISable Header > $@

blink.bin: examples/blink.o src/pbasic.o src/via.o
	$(LD65) -C mench.cfg -o blink.bin -m blink.map $^

button.bin: examples/button.o src/pbasic.o src/via.o
	$(LD65) -C mench.cfg -o button.bin -m button.map $^

echo.bin: examples/echo.o
	$(LD65) -C mench.cfg -o echo.bin -m echo.map $^

helloWorld.bin: examples/helloWorld.o
	$(LD65) -C mench.cfg -o helloWorld.bin -m helloWorld.map $^

qti.bin: examples/qti.o src/pbasic.o src/via.o
	$(LD65) -C mench.cfg -o qti.bin -m qti.map $^

servo.bin: examples/servo.o src/pbasic.o src/via.o
	$(LD65) -C mench.cfg -o servo.bin -m servo.map $^

ping.bin: examples/ping.o src/pbasic.o src/via.o src/math16.o
	$(LD65) -C mench.cfg -o ping.bin -m ping.map $^

clean:
	-$(RM) *.bin
	-$(RM) *.map
	-$(RM) *.rom
	-$(RM) *.srec
	-$(RM) examples\*.lst
	-$(RM) examples\*.o
	-$(RM) src\*.lst
	-$(RM) src\*.o
