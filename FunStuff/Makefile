include ../common.mk

CA65FLAGS = -I include

all: debug

debug: bin bin/debug bin/debug/tarpit.bin bin/debug/tarpit.srec

bin/debug/tarpit.bin: obj/debug/vmachine.o obj/debug/tarpit.o
	$(LD65) -C debug.cfg -o bin/debug/tarpit.bin -m bin/debug/tarpit.map $^

%.srec : %.bin
	$(SREC_CAT) -address-length=3 -execution_start_address 0x004000 $< -binary -offset 0x4000 -O -Motorola -DISable Header > $@

clean:
	-$(RM) bin$(SEP)debug$(SEP)*.map
	-$(RM) bin$(SEP)debug$(SEP)*.bin
	-$(RM) bin$(SEP)debug$(SEP)*.srec
	-$(RM) obj$(SEP)debug$(SEP)*.lst
	-$(RM) obj$(SEP)debug$(SEP)*.o
	-$(RMDIR) bin$(SEP)debug
	-$(RMDIR) bin
	-$(RMDIR) obj$(SEP)debug
	-$(RMDIR) obj
