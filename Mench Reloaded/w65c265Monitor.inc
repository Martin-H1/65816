; -----------------------------------------------------------------------------
; Mench Monitor subroutine entry points.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

Alter_Memory		= $E000	; Support Subroutine For 'M Command.
BACKSPACE	  	= $E003	; Outputs a <BACKSPACE> ($08) Character.
CONTROL_TONES	  	= $E009	; Configures tone generators: TG0 & TG1.
DO_LOW_POWER_PGM  	= $E00C	; Vector to force LOW POWER MODE on system.
DUMPREGS	  	= $E00F	; Support Subroutine For 'R' Command.
Dump528		    	= $E012	; Support Subroutine For 'R' Command
Dump_1_line_to_Output	= $E015	; Requests/Accepts Starting Address & dumps 8 bytes.
Dump_1_line_to_Screen	= $E018	; Requests/Accepts Starting Address & dumps 8 bytes.
Dump_to_Output		= $E01B	; Dumps specified range of memory data to port #3.
Dump_to_Printer		= $E01E	; Dumps specified range of memory data to port #3.
Dump_to_Screen		= $E021	; Dumps specified range of memory data to port #3.
Dump_to_Screen_ASCII	= $E024	; Dumps memory block in ASCII format.
Dump_It			= $E027	; Custom dump support.
FILL_Memory		= $E02A	; Support Subroutine For 'F' Command.
GET_3BYTE_ADDR		= $E02D	; Accepts 3-byte address as six ASCII Hex digits.
GET_ALARM_STATUS	= $E030	; Retrieves & resets current system alarm status.
GET_BYTE_FROM_PC	= $E033	; Reads next available input from serial port #3.
GET_CHR			= $E036	; Accepts on character from serial port #3.
GET_HEX			= $E039	; Accepts two ASCII Hex digits via serial port #3.
GET_PUT_CHR		= $E03C	; Accepts & echoes one character via serial port #3.
GET_STR			= $E03F	; Uses GET_PUT_CHR to build string buffer.
Get_Address		= $E042	; Requests/Accepts 3-byte address as ASCII Hex digits.
Get_E_Address		= $E045	; Requests/Accepts HIGHEST ADDRESS via serial port #3.
Get_S_Address		= $E048	; Requests/Accepts LOWEST ADDRESS via serial port #3.
PUT_CHR			= $E04B	; Output one character to serial console port #3.
PUT_STR			= $E04E	; Output specified string of characters to serial port #3.
READ_ALARM		= $E051	; Reads current system Alarm setting.
READ_DATE		= $E054	; Reads current system Date setting.
READ_TIME		= $E057	; Reads current system Time setting.
RESET_ALARM		= $E05A	; Resets the system Alarm function.
SBREAK			= $E05D	; Invokes the software breakpoint logic.
SELECT_COMMON_BAUD_RATE	= $E060	; Configures baud rate generator for serial port #3.
SEND_BYTE_TO_PC		= $E063	; Outputs byte to serial port #3.
SEND_CR			= $E066	; Outputs ASCII ENTER ($0D) character.
SEND_SPACE		= $E069	; Outputs ASCII SPACE ($20) character.
SEND_HEX_OUT		= $E06C	; Outputs byte as two ASCII Hex characters.
SET_ALARM		= $E06F	; Set the System Alarm time from specified string.
SET_Breakpoint		= $E072	; Sets a breakpoint (BRK) instruction at address.
SET_DATE		= $E075	; Sets the System Time-Of-Day Clock: Date
SET_TIME		= $E078	; Sets the System Time-Of-Day Clock: Time
VERSION			= $E07B	; Gets firmware (W65C265 ROM) version info.
WR_3_ADDRESS		= $E07E	; Outputs a 3-byte address as ASCII Hex characters
XS28IN			= $E081	; Accepts & loads Motorola type "S28" records.
RESET			= $E084	; Invokes the Master Start-Up vector to Reset system.
ASCBIN			= $E087	; Converts two ASCII Hex characters to binary byte.
BIN2DEC			= $E08B	; Converts binary byte to packed BCD digits.
BINASC			= $E08F	; Converts binary byte to ASCII Hexadecimal characters.
HEXIN			= $E093	; Converts ASCII Hexadecimal character to  Binary byte.
IFASC			= $E097	; Checks for displayable ASCII character.
ISDECIMAL		= $E09B	; Checks character for ASCII Decimal Digit.
ISHEX			= $E09F	; Checks character for ASCII Hexadecimal Digit
UPPER_CASE		= $E0A3	; Converts lower-case ASCII alpha chars to upper-case.
