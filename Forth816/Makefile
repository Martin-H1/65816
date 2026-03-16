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

clean:
	-$(RM) bin\*.rom
	-$(RM) bin\*.map
	-$(RM) obj\*.lst
	-$(RM) obj\*.o
	-$(RMDIR) bin
	-$(RMDIR) obj
