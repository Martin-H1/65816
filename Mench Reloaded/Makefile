include ../common.mk

SOURCES =  \
	helloWorld.asm

helloWorld.rom: helloWorld.o
	$(LD65) -C mench.cfg -o helloWorld.rom -m helloWorld.map helloWorld.o

helloWorld.srec : helloWorld.rom
	$(SREC_CAT) -address-length=3 helloWorld.rom -binary -offset 0x0300 -O -Motorola -DISable Header -DISable Footer > helloWorld.srec

clean:
	-$(RM) *.bin
	-$(RM) *.lst
	-$(RM) *.map
	-$(RM) *.o
	-$(RM) *.rom
	-$(RM) tests$/*.lst
	-$(RM) tests$/*.map
	-$(RM) tests$/*.o
	-$(RM) tests$/*.rom
	-$(RM) tests$/*.srec
