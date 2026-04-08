include ../common.mk

all: release debug

debug: bin bin/debug bin/debug/forth816.bin

release: bin bin/release bin/release/forth816.rom

bin/debug/forth816.bin: obj/debug/forth.o obj/debug/hal_mench.o obj/debug/primitives.o
	$(LD65) -C tests/test.cfg -o bin/debug/forth816.bin -m bin/debug/forth816.map $^

bin/release/forth816.rom: obj/release/forth.o obj/release/hal_mench.o obj/release/primitives.o
	$(LD65) -C forth.cfg -o bin/release/forth816.rom -m bin/release/forth816.map $^

tests: tests/bin/acceptTest.srec tests/bin/compareTest.srec \
	tests/bin/interpretTest.srec tests/bin/ioTest.srec \
	tests/bin/mathTest.srec tests/bin/memoryTest.srec \
	tests/bin/stackTest.srec

tests/bin/acceptTest.bin: tests/obj/hal_test.o tests/obj/acceptTest.o obj/debug/primitives.o
	$(LD65) -C tests/test.cfg -o tests/bin/acceptTest.bin -m tests/bin/acceptTest.map $^

tests/bin/compareTest.bin: tests/obj/hal_test.o tests/obj/compareTest.o obj/debug/primitives.o
	$(LD65) -C tests/test.cfg -o tests/bin/compareTest.bin -m tests/bin/compareTest.map $^

tests/bin/interpretTest.bin: tests/obj/hal_test.o tests/obj/interpretTest.o obj/debug/primitives.o
	$(LD65) -C tests/test.cfg -o tests/bin/interpretTest.bin -m tests/bin/interpretTest.map $^

tests/bin/ioTest.bin: tests/obj/hal_test.o tests/obj/ioTest.o obj/debug/primitives.o
	$(LD65) -C tests/test.cfg -o tests/bin/ioTest.bin -m tests/bin/ioTest.map $^

tests/bin/mathTest.bin: tests/obj/hal_test.o tests/obj/mathTest.o obj/debug/primitives.o
	$(LD65) -C tests/test.cfg -o tests/bin/mathTest.bin -m tests/bin/mathTest.map $^

tests/bin/memoryTest.bin: tests/obj/hal_test.o tests/obj/memoryTest.o obj/debug/primitives.o
	$(LD65) -C tests/test.cfg -o tests/bin/memoryTest.bin -m tests/bin/memoryTest.map $^

tests/bin/stackTest.bin: tests/obj/hal_test.o tests/obj/stackTest.o obj/debug/primitives.o
	$(LD65) -C tests/test.cfg -o tests/bin/stackTest.bin -m tests/bin/stackTest.map $^

%.srec : %.bin
	$(SREC_CAT) -address-length=3 -execution_start_address 0x004000 $< -binary -offset 0x4000 -O -Motorola -DISable Header > $@

clean:
	-$(RM) bin$(SEP)debug$(SEP)*.map
	-$(RM) bin$(SEP)debug$(SEP)*.bin
	-$(RM) bin$(SEP)release$(SEP)*.map
	-$(RM) bin$(SEP)release$(SEP)*.rom
	-$(RM) obj$(SEP)debug$(SEP)*.lst
	-$(RM) obj$(SEP)debug$(SEP)*.o
	-$(RM) obj$(SEP)release$(SEP)*.lst
	-$(RM) obj$(SEP)release$(SEP)*.o
	-$(RMDIR) bin$(SEP)debug
	-$(RMDIR) bin$(SEP)release
	-$(RMDIR) bin
	-$(RMDIR) obj$(SEP)debug
	-$(RMDIR) obj$(SEP)release
	-$(RMDIR) obj
	-$(RM) tests$(SEP)bin$(SEP)*.bin
	-$(RM) tests$(SEP)bin$(SEP)*.map
	-$(RM) tests$(SEP)bin$(SEP)*.rom
	-$(RM) tests$(SEP)bin$(SEP)*.srec
	-$(RM) tests$(SEP)obj$(SEP)*.lst
	-$(RM) tests$(SEP)obj$(SEP)*.o
	-$(RMDIR) tests$(SEP)bin
	-$(RMDIR) tests$(SEP)obj
