include ../../common.mk

CA65FLAGS = -I ../targets/65816

all: debug

debug: obj obj/debug bin bin/debug \
	bin/debug/basic.bin bin/debug/basic.srec \
	bin/debug/output.bin bin/debug/output.srec \
	bin/debug/memory.bin bin/debug/memory.srec

obj/debug/vmachine.o: ../targets/65816/vmachine.s
	$(CA65) --cpu 65816 $(CA65FLAGS) $< -l $*.lst -o $@

bin/debug/basic.bin: obj/debug/vmachine.o obj/debug/basic.o
	$(LD65) -C ../targets/65816/debug.cfg -o bin/debug/basic.bin -m bin/debug/basic.map $^

bin/debug/output.bin: obj/debug/vmachine.o obj/debug/output.o
	$(LD65) -C ../targets/65816/debug.cfg -o bin/debug/output.bin -m bin/debug/output.map $^

bin/debug/memory.bin: obj/debug/vmachine.o obj/debug/memory.o
	$(LD65) -C ../targets/65816/debug.cfg -o bin/debug/memory.bin -m bin/debug/memory.map $^

%.s : %.f
	$(PYTHON) "..\__main__.py" $<

%.srec : %.bin
	$(SREC_CAT) -address-length=3 -execution_start_address 0x004000 $< -binary -offset 0x4000 -O -Motorola -DISable Header > $@

clean:
	-$(RM) *.s
	-$(RM) bin$(SEP)debug$(SEP)*.map
	-$(RM) bin$(SEP)debug$(SEP)*.bin
	-$(RM) bin$(SEP)debug$(SEP)*.srec
	-$(RM) obj$(SEP)debug$(SEP)*.lst
	-$(RM) obj$(SEP)debug$(SEP)*.o
	-$(RMDIR) bin$(SEP)debug
	-$(RMDIR) bin
	-$(RMDIR) obj$(SEP)debug
	-$(RMDIR) obj
