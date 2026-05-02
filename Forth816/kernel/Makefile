include ../../common.mk

CA65FLAGS = -D UNROLL -I include

all: release debug

debug: CA65FLAGS += -D DEBUG 
debug: bin bin/debug bin/debug/forth816.bin bin/debug/forth816.srec

release: bin bin/release bin/release/forth816.rom

# NOTE: hal_mench.o must be listed first due to a ca65 linker bug with
# dependency resolution. Do not reorder.
bin/debug/forth816.bin: obj/debug/hal_mench.o obj/debug/forth.o obj/debug/primitives.o
	$(LD65) -C debug.cfg -o bin/debug/forth816.bin -m bin/debug/forth816.map $^

bin/release/forth816.rom: obj/release/forth.o obj/release/hal_mench.o obj/release/primitives.o
	$(LD65) -C forth.cfg -o bin/release/forth816.rom -m bin/release/forth816.map $^

%.srec : %.bin
	$(SREC_CAT) -address-length=3 -execution_start_address 0x004000 $< -binary -offset 0x4000 -O -Motorola -DISable Header > $@

decode:
	$(PYTHON) trace_decode.py tests/bin/interpretTest.map < trace.txt

clean:
	-$(RM) bin$(SEP)debug$(SEP)*.map
	-$(RM) bin$(SEP)debug$(SEP)*.bin
	-$(RM) bin$(SEP)debug$(SEP)*.srec
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
