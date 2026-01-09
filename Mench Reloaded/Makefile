include ../common.mk

SOURCES =  \
	echo.asm \
	helloWorld.asm

echo.rom: echo.o
	$(LD65) -C mench.cfg -o echo.rom -m echo.map echo.o

echo.srec : echo.rom
	$(SREC_CAT) -address-length=3 -execution_start_address 0x000300 echo.rom -binary -offset 0x0300 -O -Motorola -DISable Header > echo.srec

helloWorld.rom: helloWorld.o
	$(LD65) -C mench.cfg -o helloWorld.rom -m helloWorld.map helloWorld.o

helloWorld.srec : helloWorld.rom
	$(SREC_CAT) -address-length=3 -execution_start_address 0x000300 helloWorld.rom -binary -offset 0x0300 -O -Motorola -DISable Header -DISable Footer > helloWorld.srec

clean:
	-$(RM) *.bin
	-$(RM) *.lst
	-$(RM) *.map
	-$(RM) *.o
	-$(RM) *.rom
	-$(RM) *.srec
