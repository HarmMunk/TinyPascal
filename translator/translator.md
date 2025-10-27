# The P-code to 8080-translator
## Introduction
The function of the Translator is to translate(sic) the psuedo code, or P-code into 8080 or Z80 machine code. As this version is based on the original translator by [Chu] it produces code restricted to Intel 8080 code.

The Translator uses two objects: the P-code file and the Tiny Pascal run-time system. That system is contained in a file called `PRUN.LIB`. The P-code is produced by the Tiny Pascal P-code compiler, or *TPC* for short. a P-code file consists of binary data. Each P-code instruction is two 16-bit words long. The first word contains the 8-bit instruction and its first 8-bit argument. The second word contains the second 16 bit argument of the instruction. 

As an example the instruction to load the literal value 123 on top of the stack:
```
LIT 0,64
```
is encoded as the two words `0000 0040`.

The Tiny Pascal run-time system, or *RTS* for short, is produced from an assembly language file, usually named `PRUNxyz.ASM`. In fact, `PRUN.LIB` is the renamed version of the file `PRUNxyz.COM`, and the latter file is a CP/M executable file. When executed, it prints
```
Tiny Pascal Run Time System: no translated P-code!
```
and then returns to the CP/M CCP. The file `PRUN.LIB` 

![alt text](TP_RTS_Layout.png)

For a complete overview of the P-code instructions see [Pco].
## The Structure of the Translator
The translator consists of the following phases:
A - initialisation
B - collect P-code adresses
C - the translation proper
D - fix references: replace P-code address with 8080-code addresses
E - Produce listing with original Pascal program, P-code instructions 
and 8080-addresses.

The translator uses a number of files:
SFBN$ is the basename for all files.
PFN$ is the name of the P-code file produced by the compiler: extension 
is .PCD. That file is opened in random access mode.
PLN$ is the name of the file containing the generated 8008-code. It 
starts life with the extension .$$$ but is renamed to extension .COM 
after the translation is succesfull. This file is also open in random 
access mode.
The third file the translator uses, with the extension .PAX, is a 
temporary file that relates the P-code address to the corresponding 
8080-assembly address. This file is also opened in random access mode.

The file PRUN.LIB is expected to exist. It contains the Tiny Pascal run 
time support routines.

A file is opened and closed by the subroutine that requires it, unless 
closing a file would mean that the current position is lost.

Lines 10- Initialisation

Lines 10-99: Definitions
All variables are integers unless otherwise specified. For convenience, 
FALSE and TRUE are defined.
CLS$ is the "Clear Screen" character sequence for the VT-100 terminal.
SGNON$ is the translator's sign-on message.

Lines 100-199: Definition of auxilliary functions
FNHEXN$(NUM,LEN): print NUM in hexadecimal form, with LEN digits, 
padding the string with zero's on the left.

FNMEMW(I!): Convert the real number I! between 0 and 65535 into an 
integer between -32768 and +32767. In MSBASIC 5 an int is always 
between -32768 and 32767, but arithmatic on addresses can yield results 
larger than 32767. This function is the opposite of FNABSW!().

FNABSW!(I.): Convert the integer I. between -32768 and +32767 into a 
real number between 0 and 65535. This function is the opposite of 
FNMEMW().

FNHIGH.BYTE(I): Return the high byte of I.
FNLOW.BYTE(I): Return the low byte of I.

FNEO.PCFILE(CO1, CO2): Return the end of file status of the P-code 
file, which is signified by two words with the value FFFF hexadecimal.

FNREFINST(Q1, Q2): Return true if the P-code instruction (Q1, Q2) is a 
JMP, JPC or a CSR.

Lines 200-299 Ask for name of the P-code file and construct other 
filenames.

Print the sign-on message.
Set the debug level:
0 - No debug
1 - Only messages announcing the phases of the translation
2 - Messages detailing progress and intermediate results

Construct the names of the P-code file and the 8080-Assembly file. The 
P-code file is opened and closed for input, because during translation 
the file kept open in random mode ("R"). Opening a file in random mode 
always succeeds, so it is not possible to tell if the P-code file 
exists if the file is opened in random mode.

Lines ?-? Prepare the run time support
Open the file  constaining the runtime support (RTS) routines. It is 
opened as a random access file with a field length of 128 bytes to 
speed up access.
The first three bytes in this file contain a jump to the INIT routine 
of the RTS. The next word contains the location in the file where a 
table is stored containing the addresses of the of the RTS functions.
