include ../common.mk

SOURCE = compare.s \
	forth.s \
	hal_mench.s \
	interpreter.s \
	io.s \
	math.s \
	memory.s \
	primitives.s \
	print.s \
	stack.s \
	stubs.s \
	system.s

all: bin bin/forth816.rom

bin/forth816.rom: obj/compare.o obj/forth.o obj/hal_mench.o \
	obj/interpreter.o obj/io.o obj/math.o obj/memory.o \
	obj/primitives.o obj/print.o obj/stack.o obj/stubs.o \
	obj/system.o
	$(LD65) -C forth.cfg -o bin/forth816.rom -m bin/forth816.map $^

test:
	$(65816S) v 8000 bin\forth816.rom

tests/obj/hal_test.o : tests/hal_test.s tests/obj
	$(CA65) --cpu 65816 -I . $< -l $*.lst -o $@

tests/obj/compareTest.o : tests/compareTest.s tests/obj tests/bin
	$(CA65) --cpu 65816 -I . $< -l $*.lst -o $@

tests/bin/compareTest.bin: tests/obj/compareTest.o tests/obj/hal_test.o \
	obj/compare.o obj/print.o obj/stack.o
	$(LD65) -C tests/test.cfg -o tests/bin/compareTest.bin -m tests/bin/compareTest.map $^

%.srec : %.bin
	$(SREC_CAT) -address-length=3 -execution_start_address 0x000600 $< -binary -offset 0x0600 -O -Motorola -DISable Header > $@

clean:
	-$(RM) bin$(SEP)*.rom
	-$(RM) bin$(SEP)*.map
	-$(RM) obj$(SEP)*.lst
	-$(RM) obj$(SEP)*.o
	-$(RMDIR) bin
	-$(RMDIR) obj
	-$(RM) tests$(SEP)bin$(SEP)*.bin
	-$(RM) tests$(SEP)bin$(SEP)*.rom
	-$(RM) tests$(SEP)bin$(SEP)*.map
	-$(RM) tests$(SEP)obj$(SEP)*.lst
	-$(RM) tests$(SEP)obj$(SEP)*.o
	-$(RMDIR) tests$(SEP)bin
	-$(RMDIR) tests$(SEP)obj
