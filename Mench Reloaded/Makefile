include ../common.mk

EXAMPLES = \
	bin/blink.srec \
	bin/button.srec \
	bin/echo.srec \
	bin/helloWorld.srec \
	bin/math.srec \
	bin/ping.srec \
	bin/qti.srec \
	bin/servo.srec

all: $(EXAMPLES)

%.srec : %.bin
	$(SREC_CAT) -address-length=3 -execution_start_address 0x000300 $< -binary -offset 0x0300 -O -Motorola -DISable Header > $@

bin/blink.bin: examples/blink.o src/pbasic.o src/via.o
	$(LD65) -C mench.cfg -o bin/blink.bin -m bin/blink.map $^

bin/button.bin: examples/button.o src/pbasic.o src/via.o
	$(LD65) -C mench.cfg -o bin/button.bin -m bin/button.map $^

bin/echo.bin: examples/echo.o
	$(LD65) -C mench.cfg -o bin/echo.bin -m bin/echo.map $^

bin/helloWorld.bin: examples/helloWorld.o
	$(LD65) -C mench.cfg -o bin/helloWorld.bin -m bin/helloWorld.map $^

bin/math.bin: examples/math.o src/math16.o src/print.o
	$(LD65) -C mench.cfg -o bin/math.bin -m bin/math.map $^

bin/ping.bin: examples/ping.o src/pbasic.o src/via.o src/math16.o src/print.o
	$(LD65) -C mench.cfg -o bin/ping.bin -m bin/ping.map $^

bin/qti.bin: examples/qti.o src/pbasic.o src/print.o src/via.o
	$(LD65) -C mench.cfg -o bin/qti.bin -m bin/qti.map $^

bin/servo.bin: examples/servo.o src/pbasic.o src/via.o
	$(LD65) -C mench.cfg -o bin/servo.bin -m bin/servo.map $^

clean:
	-$(RM) bin\*.bin
	-$(RM) bin\*.map
	-$(RM) bin\*.rom
	-$(RM) bin\*.srec
	-$(RM) examples\*.lst
	-$(RM) examples\*.o
	-$(RM) src\*.lst
	-$(RM) src\*.o
