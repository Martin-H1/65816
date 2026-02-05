# Common set of macros to enable Linux versus Windows portability.
ifeq ($(OS),Windows_NT)
    / = $(strip \)
    CA65 = "%HOMEPATH%\cc65-snapshot-win32\bin\ca65.exe"
    LD65 = "%HOMEPATH%\cc65-snapshot-win32\bin\ld65.exe"
    PY65MON = "%HOMEPATH%\AppData\Local\Programs\Python\Python311\Scripts\py65mon"
    PYTHON = python
    SREC_CAT = "C:\Program Files\srecord\bin\srec_cat.exe"
    RM = del /f /q
    RMDIR = rmdir /s /q
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

%.o : %.asm
	$(CA65) --cpu 65816 -I include $< -l $*.lst -o $@
