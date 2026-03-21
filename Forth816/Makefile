include ../common.mk

all: release

release: bin bin/forth816.rom

bin/forth816.rom: obj/forth.o obj/hal.o obj/primitives.o
	$(LD65) -C forth.cfg -o bin/forth816.rom -m bin/forth816.map $^

tests: tests/bin/compareTest.srec tests/bin/ioTest.srec tests/bin/mathTest.srec \
	tests/bin/memoryTest.srec tests/bin/stackTest.srec

tests/bin/compareTest.bin: tests/obj/hal_test.o tests/obj/compareTest.o obj/primitives.o obj/print.o
	$(LD65) -C tests/test.cfg -o tests/bin/compareTest.bin -m tests/bin/compareTest.map $^

tests/bin/ioTest.bin: tests/obj/hal_test.o tests/obj/ioTest.o obj/primitives.o obj/print.o
	$(LD65) -C tests/test.cfg -o tests/bin/ioTest.bin -m tests/bin/ioTest.map $^

tests/bin/mathTest.bin: tests/obj/hal_test.o tests/obj/mathTest.o obj/primitives.o obj/print.o
	$(LD65) -C tests/test.cfg -o tests/bin/mathTest.bin -m tests/bin/mathTest.map $^

tests/bin/memoryTest.bin: tests/obj/hal_test.o tests/obj/memoryTest.o obj/primitives.o obj/print.o
	$(LD65) -C tests/test.cfg -o tests/bin/memoryTest.bin -m tests/bin/memoryTest.map $^

tests/bin/stackTest.bin: tests/obj/hal_test.o tests/obj/stackTest.o obj/primitives.o obj/print.o
	$(LD65) -C tests/test.cfg -o tests/bin/stackTest.bin -m tests/bin/stackTest.map $^

%.srec : %.bin
	$(SREC_CAT) -address-length=3 -execution_start_address 0x000600 $< -binary -offset 0x0600 -O -Motorola -DISable Header > $@




clean:
	-$(RM) bin$(SEP)*.map
	-$(RM) bin$(SEP)*.rom
	-$(RM) obj$(SEP)*.lst
	-$(RM) obj$(SEP)*.o
	-$(RMDIR) bin
	-$(RMDIR) obj
	-$(RM) tests$(SEP)bin$(SEP)*.bin
	-$(RM) tests$(SEP)bin$(SEP)*.map
	-$(RM) tests$(SEP)bin$(SEP)*.rom
	-$(RM) tests$(SEP)bin$(SEP)*.srec
	-$(RM) tests$(SEP)obj$(SEP)*.lst
	-$(RM) tests$(SEP)obj$(SEP)*.o
	-$(RMDIR) tests$(SEP)bin
	-$(RMDIR) tests$(SEP)obj
