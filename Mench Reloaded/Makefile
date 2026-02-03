include ../common.mk

SOURCES =  \
	blink.asm \
	button.asm \
	echo.asm \
	helloWorld.asm \
	math16.asm \
	servo.asm \
	ping.asm \
	via.asm

%.srec : %.bin
	$(SREC_CAT) -address-length=3 -execution_start_address 0x000300 $< -binary -offset 0x0300 -O -Motorola -DISable Header > $@

blink.bin: blink.o pbasic.o via.o
	$(LD65) -C mench.cfg -o blink.bin -m blink.map blink.o pbasic.o via.o

button.bin: button.o pbasic.o via.o
	$(LD65) -C mench.cfg -o button.bin -m button.map button.o pbasic.o via.o

echo.bin: echo.o
	$(LD65) -C mench.cfg -o echo.bin -m echo.map echo.o

helloWorld.bin: helloWorld.o
	$(LD65) -C mench.cfg -o helloWorld.bin -m helloWorld.map helloWorld.o

servo.bin: servo.o pbasic.o via.o
	$(LD65) -C mench.cfg -o servo.bin -m servo.map servo.o pbasic.o via.o

ping.bin: ping.o pbasic.o via.o math16.o
	$(LD65) -C mench.cfg -o ping.bin -m ping.map ping.o pbasic.o via.o math16.o

clean:
	-$(RM) *.bin
	-$(RM) *.lst
	-$(RM) *.map
	-$(RM) *.o
	-$(RM) *.rom
	-$(RM) *.srec
