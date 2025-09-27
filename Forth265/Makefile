include ../common.mk

SOURCES =  \
	forth265.asm

PY65MON_SOURCES = \
	$(SOURCES) \
	Py65Main.asm

test.rom : test.o
	$(LD65) -C test.cfg -o test.rom test.o

test.srec : test.rom
	$(SREC_CAT) test.rom -binary -offset 0x8000 -O -Motorola -DISable Header -DISable Footer > test.srec

py65mon.rom: clean $(SOURCES)
	$(OPHIS) --65c02 -l py65mon.lst -m py65mon.map Py65Main.oph

debug: py65mon.rom
	$(PY65MON) -m 65C02 -r py65mon.rom

clean:
	-$(RM) *.bin
	-$(RM) *.lst
	-$(RM) *.map
	-$(RM) *.o
	-$(RM) *.rom
	-$(RM) *.srec
	-$(RM) *.tmp
