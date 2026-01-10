include ../common.mk

SOURCES =  \
	blink.asm \
	echo.asm \
	helloWorld.asm \
	via.asm

%.srec : %.bin
	$(SREC_CAT) -address-length=3 -execution_start_address 0x000300 $< -binary -offset 0x0300 -O -Motorola -DISable Header > $@

blink.bin: blink.o via.o
	$(LD65) -C mench.cfg -o blink.bin -m blink.map blink.o via.o

echo.bin: echo.o
	$(LD65) -C mench.cfg -o echo.bin -m echo.map echo.o

helloWorld.bin: helloWorld.o
	$(LD65) -C mench.cfg -o helloWorld.bin -m helloWorld.map helloWorld.o

clean:
	-$(RM) *.bin
	-$(RM) *.lst
	-$(RM) *.map
	-$(RM) *.o
	-$(RM) *.rom
	-$(RM) *.srec
