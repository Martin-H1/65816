# Common set of macros to enable Linux versus Windows portability.
ifeq ($(OS),Windows_NT)
    / = $(strip \)
    CA65 = "%HOMEPATH%\cc65-snapshot-win32\bin\ca65.exe"
    LD65 = "%HOMEPATH%\cc65-snapshot-win32\bin\ld65.exe"
    PY65MON = "%HOMEPATH%\AppData\Local\Programs\Python\Python311\Scripts\py65mon"
    PYTHON = "C:\Users\mheer\AppData\Local\Programs\Python\Python311\python.exe"
    65816S = "%HOMEPATH%\Documents\git\65816\tools\65816S.exe"
    SREC_CAT = "C:\Program Files\srecord\bin\srec_cat.exe"
    RM = del /f /q
    RMDIR = rmdir /s /q
    SEP =\\
    SHELL_EXT = bat
    TOUCH = type nul >
else
    / = /
    OPHIS = ~/Ophis-2.1/ophis
    PY65MON = ~/.local/bin/py65mon
    PYTHON = python3
    RM = rm -f
    RMDIR = rm -rf
    SHELL_EXT = sh
    TOUCH = touch
endif

# Global implicit rules

bin:
	mkdir bin

bin/debug:
	mkdir bin$(SEP)debug

bin/release:
	mkdir bin$(SEP)release

obj:
	mkdir obj

obj/debug:
	mkdir obj$(SEP)debug

obj/release:
	mkdir obj$(SEP)release

tests/obj:
	mkdir tests$(SEP)obj

tests/bin:
	mkdir tests$(SEP)bin

%.o : %.asm
	$(CA65) --cpu 65816 -I include $< -l $*.lst -o $@

obj/debug/%.o : %.s obj obj/debug
	$(CA65) --cpu 65816 $(CA65FLAGS) $< -l obj/debug/$*.lst -o $@

obj/release/%.o : %.s obj obj/release
	$(CA65) --cpu 65816 $(CA65FLAGS) $< -l obj/release/$*.lst -o $@

tests/obj/%.o : tests/%.s tests/obj tests/bin
	$(CA65) --cpu 65816 $(CA65FLAGS) $< -l tests/obj/$*.lst -o $@
