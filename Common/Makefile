include ../common.mk

SOURCES =  \
	conio.asm \
	print.asm

TESTS = \
	conioTest \
	printTest

tests: $(TESTS)

conioTest: tests/conioTest.rom

tests/conioTest.rom: tests/conioTest.o conio.o vectors.o
	$(LD65) -C tests/test.cfg -o tests/conioTest.rom tests/conioTest.o conio.o vectors.o

test.srec : test.rom
	$(SREC_CAT) test.rom -binary -offset 0x8000 -O -Motorola -DISable Header -DISable Footer > test.srec

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
