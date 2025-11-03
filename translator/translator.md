# The P-code to 8080-translator
## Introduction
The function of the Translator is to translate (sic) the psuedo code, or P-code, into 8080 or Z80 machine code. As this version is based on the original translator by [Chu] it produces code restricted to Intel 8080.


The Translator uses, or reads from two files: the P-code file and the Tiny Pascal run-time system. The P-code is produced by the Tiny Pascal P-code compiler, or *TPC* for short. A P-code file consists of binary data. Each P-code instruction is two 16-bit words long. The first word contains the 8-bit instruction and its first 8-bit argument. The second word contains the second 16 bit argument of the instruction. 

As an example the instruction to load the literal value 123 on top of the stack: ```LIT 0,123```
is encoded as the two words `0000 007B`.

The other file is the the Tiny Pascal run-time system, or *RTS* for short, is contained in a file with the name `PRUN.LIB`. It is produced from an assembly language file, usually named `PRUNxyz.ASM`, where the ```xyz``` are three digits indicating the semantic version: major version, minor version, bug fix release numer. In fact, `PRUN.LIB` is the renamed version of the file `PRUNxyz.COM`, and that latter file is a CP/M executable file. When executed, it prints
```
Tiny Pascal Run Time System: no translated P-code!
```
and then returns to the CP/M CCP.

More information can be found in the documentation of the *RTS*.

![alt text](image.png)

For a complete overview of the P-code instructions see [Pco].
## The Structure of the Translator
The translator consists of the following phases:

1. Initialisation
2. collect P-code adresses
3. the translation proper
4. fix references: replace P-code address with 8080-code addresses
5. Produce listing with original Pascal program, P-code instructions 
and 8080-addresses.

The translator uses a number of files. SFBN$ is the basename for all files.
- PFN$ is the name of the P-code file produced by the compiler: extension 
is .PCD. That file is opened in random access mode.
- PLN$ is the name of the file containing the generated 8080-code. It 
starts life with the extension .$$$ but is renamed to extension .COM 
after the translation is succesfull. This file is also open in random 
access mode.
- The third file the translator uses, with the extension .PAX, is a 
temporary file that relates the P-code address to the corresponding 
8080-assembly address. This file is also opened in random access mode.

The file PRUN.LIB is expected to exist. It contains the Tiny Pascal run 
time support routines.

A file is opened and closed by the subroutine that requires it, unless 
closing a file would mean that the current position is lost.

## Annotated Listing
### Initialisation
#### Definitions
```
10 DEFINT A-Z:FALSE=0:TRUE=NOT FALSE
```
All variables are integers unless otherwise specified. For convenience, 
FALSE and TRUE are defined.
```
100 DEF FNHEXN$(A,N)=STRING$(N-LEN(HEX$(A)),"0")+HEX$(A)
```
The function ```FNHEXN$(A,N)``` print the number ```A``` in hexadecimal form with length ```N```, adding zeroes to the front if necessary.
```
110 DEF FNMEMW(I!)=I!+(I!>32767)*65536!:DEF FNABSW!(I.)=I.-(I.<0)*65536!
```
```FNMEMW(I!)``` transforms the unsigned integer I! (represented as a floating point value) into a signed integer with the same bit pattern. The function ```FNABSW!(I.)``` does the opposite. Note how these functions work: in Microsoft BASIC (or MBASIC) the outcome of a logical expression is either a 16 bit integer with all 0 bits, representing *false*, or a 16 bit integer with all bits 1, representing *true*. That last value is also -1 in 2's complement. So, in ```FNMEMW```, if I. is larger than 32767 then 65536 is subtracted from its value. And in ```FNABSW!```, if I. is less than 0, then 65536 is added.
```
120 DEF FNHIBT(I)=INT(FNABSW!(I)/256):DEF FNLOBT(I)=FNABSW!(I)-FNHIBT(I)*256
```
```FNHIBT(I)``` (**HI**gh **B**y**T**e) returns the upper 8 bits of I, ```FNLOBT(I)``` (**LO** **B**y**T**e) returns the lower bits of I. Note that the use of ```FNABSW``` is the function definition is necessay because ```I``` can be less than zero.
```
130 DEF FNEOPF(CO1, CO2)= CO1=&HFFFF AND CO2=&HFFFF
```
The function ```FNEOPF(CO1, CO2)``` (**E**nd **O**f **P**-code **F**ile) returns true if the last instruction of a P-code file has been reached.
```
140 DEF FNBTV(REC$,OFS)=ASC(MID$(REC$,OFS+1,1)):DEF FNWDV(REC$,OFS)=CVI(MID$(REC$,OFS+1,2))
```
Function ```FNBTV(REC$,OFS)``` (**B**y**T**e **V**alue) returns the value of the byte in the record string ```REC$``` at offset ```OFS```. Function ```FNWDV(REC$,OFS)``` (**W**or**D** **V**alue) returns the word at ```OFS``` in the record string ```REC$```. Note that offsets in strings start at 1, not at 0!
```
150 DEF FNRCN(L,R)=INT(FNABSW!(L)/R):DEF FNOFS(L,R)=FNABSW!(L) MOD R
```

```
160 DEF FNMIN(A,B)=-(A>B)*B-(B>=A)*A:DEF FNMAX(A,B)=-(A<B)*B-(A>=B)*A
170 DEF FNRNG(A)=A>=ASC(" ")AND A<=ASC("~"):DEF FNCHAR$(A)=CHR$(A*(-FNRNG(A))-46*(NOT FNRNG(A)))
```

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

```
24240 GET#PLN,PCPI:PCO1=CVI(CO1$):PCO2=CVI(CO2$):PQ1=PCO1\256:IF PQ1<>0 THEN 24220 ELSE IF CO2=1 THEN 24250 ELSE IF CO2=2 OR CO2=3 THEN 24270 ELSE STOP'CO2 (=OPR)  SHOULD BE 1, 2 OR 3
```
PCO1, PCO2 and PQ1 are the CO1, CO2 and Q1 of the P-code instruction immediately preceding the current one. If that previous instruction is NOT a ```LIT``` instruction, then there is nothing to optimise.
If the current instruction is a negate ```OPR 0,1``` then continue at line 24250. If it is an add ```OPR 0,2``` or a subtract ```OPR 0,3``` then continue at line 24270. If it is none of these three operations, something is wrong.

```
24250 IF PCO2=0 THEN NOPT[2]=NOPT[2]+1:OPT$=", O2Q":RETURN
```
If the previous instruction is a ```LIT 0,0``` and the current instruction is a negate, then do not generate code (-0=0).

```
24260 ACPI=ACPI-5:OWD=-CO2:GOSUB 12700:ACPI=ACPI+3:NOPT[2]=NOPT[2]+1:OPT$=", O2":RETURN
```
Replace the constant n in the ```LIT 0,n``` instruction by -n.

```
24270 IF PCO2>3 THEN 24220
```
If the constant in the ```LIT 0,n``` instruction is larger than 3 then there is nothing to optimise.


```
24280 IF CO2=2 THEN OP=19 ELSE OP=20
```
If the current operation is add, then select increment as the new instruction, other otherwise it is subtract and in that case select decrement.

```
24290 NOPT[2]=NOPT[2]+1:OPT$=", O2":IF PCO2=0 THEN ACPI=ACPI-8:OPT$=", O2Q":RETURN
```
If the previous instruction is a ```LIT 0,0``` then quash it completely, because x+0 or x-0 equals x.
```
24300 ACPI=ACPI-6:FOR I=1 TO PCO2:OBT=&HCD:GOSUB 12600:OWD=PRTB[P2R[Q1]+OP]:GOSUB 12700:NEXT:RETURN
```
Replace the ```LIT 0,n``` followed by and add or subtract instruction by n repeated calls to increment or decrement.