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

### Debug Levels
The translator has four debug levels. The debugging level is set through the variable ```DBG``` in line 1000:

0. No debugging information;
1. The start and end of the phases of the translator are printed. While translating, each P-code instruction is printed together with optimisation information, if applicable. Also, instruction that reference other instructions are marked;
2. In addition to level 1. some more details during each phase is printed, such as the number of pages of code making up the *RTS* that are moved from the ```PRUN.LIB``` to the executable ```.COM``` file;
3. In addition to level 2. detailed information during some of the phases of the translator are printed, such as the content of the table with addresses of the subroutines implementing the *RTS*.

### Optimisations
The translator has four optimisation levels. The optimisation level is determined by the variable ```OPT``` in line 1000. See the table below for a detailed list of all optimisations:

0. No optimisations;
1. Instructions that do not change the state of the P-code machine except for the program index are removed:

     ```
     n   JMP n+1
     n+1 ...
     ```
     can safely be removed.

2. In addition to the level 1. optimisations, some instructions with particular parameters are translated in more efficient machine code.
3. In addition to level 2. optimisations, optimisations that require some more code analysis are implemented. In the current version, that means that some ```STO```-```LOD``` sequences are optimised. However this requires a pre-scan of the P-code program to find out if ```LOD``` instructions are the target of a ```JMP```, ```JPC```, or ```CAL``` instruction.

The following table lists the implemented optimisations.


|Level|Optimisation|Example|Original assembly code|Optimised assembly code|
|---|---|---|---|---|
|1|Remove unnecesary jumps|```n JMP n+1```|```JMP m```|No code|
|1|Increase stack pointer by 0|```INT 0```|```LXI H,0```<br>```CALL INT```|No code|
|2|Load 0 on top of the stack (See Note 1)|```LIT 0```|```LXI B,0```<br>```CALL INT```|```XRA A```<br>```STAX D```<br>```INX D```<br>```STAX D```<br>```INX D```<br>```CALL STACK$CHK```|
|2|Negate 0|```LIT 0```<br>```OPR 0,1```|```<code for LIT 0>```<br>```CALL OPR00$01```|No code|
|2|Negate constant|```LIT n```<br>```OPR 0,1```|```LXI B,n```<br>```CALL LIT```<br>```CALL OPR00$01```|```LXI B,-n```<br>```CALL LIT```|
|2|Replace adding or subtracting small constants smaller than 3 by repeated calls to ```INC``` or ```DEC```. If n=0 then the ```LIT 0``` and the ```OPR 0,m``` (m=2 or 3) is quashed.|```LIT 2```<br>```OPR 0,2```<br><br>```LIT 1```<br>```OPR 0,3```|```LXI B,2```<br>```CALL OPR00$02```<br><br>```LXI B,1```<br>```CALL OPR00$03```|```CALL OPR00$13```<br>repeated n times<br><br>```CALL OPR00$14```<br>repeated n times|
|3|Store followed by a load of the same variable. Such a sequence can be quashed, but only if the ```LOD``` is _not_ the target of a jump or call instruction. See Note 2.||||


**_Note_ 1** In the original Chen and Huang translator there was no call to the ```CHECK$STC``` routine which is rare and unexpected cases could cause the stack to overflow in unwanted areas, e.g., the BDOS in CP/M.
**_Note_ 2** This optimisation requires a pre-analysis of the whole P-code file to register all ```LOD``` instructions that are the target of a ```JMP```, ```JPC``` or ```CALL```. Because this can be a time consuming analysis, it is only executed if the optimisation level is 3.

## Annotated Listing
### Initialisation
#### Definitions
```
10 DEFINT A-Z
```
All variables are integers unless otherwise specified.
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
```FNRCN(L,R)``` computes the **R**e**C**ord **N**umber given a particular offset ```L``` in bytes of a location based on a record length ```R```. ```FNOFS(L,R)``` computes the **OF**f**S**et in a record given a byte offet ```L```in the file and a record length ```R```. 
```
160 DEF FNMIN(A,B)=-(A>B)*B-(B>=A)*A
```
```FNMIN(A,B)``` return the **MIN**imum of ```A``` and ```B```.
```
170 DEF FNRNG(A)=A>=ASC(" ")AND A<=ASC("~"):DEF FNCHAR$(A)=CHR$(A*(-FNRNG(A))-46*(NOT FNRNG(A)))
```
```FNRNG(A)``` returns ```TRUE``` if ```A``` is in the **R**a**NG**e of ASCII values of printable characters. ```FNCHAR$(A)``` returns the character with ASCII value ```A``` if it is printable, otherwise it returns a '.' .

```
200 MJR=0:MNR=1
```
The expected major and minor version number of the *RTS*.
```
210 SGNON$="P-CODE TO 8080 TRANSLATOR"
```
SGNON$ is the translator's sign-on message.
```
220 TRF=0
```
```TRF``` (**T**otal number of **R**e**F**erences) is the total number of references, forward as well as backward.
```
230 DIM NOPT[3]
```
The array ```NOPT``` keeps track of the **N**umber of **OPT**imisations at each of the levels 1, 2 and 3. The elements of an array are initilased to 0 in MBASIC.
```
240 DIM TLOD[50]:TLDI=0
```
The array ```TLOD``` keeps track of the total number of **T**argeted ```LOD``` P-code instructions, e.i., ```LOD``` instructions that are the target of a ```JMP```, a ```JPC``` or a ```CAL``` instruction. ```TLDI``` is the **I**ndex of the first free element in array ```TLOD```.

```
1000 PRINT SGNON$:DBG=2:OPL=3
```
Print the sign-on message. Set the 
```
1010 PRINT USING"Optimisation level = #. ";OPL;:INPUT"P-code file name (.PCD is assumed)";SFBN$
1020 INPUT"Want P-codes listed";PLF$
1030 TAF$=SFBN$+".$$$":TAF=2:OPEN"O",TAF,TAF$:CLOSE TAF:KILL TAF$:EXF$=SFBN$+".COM":EXF=1:OPEN"O",EXF,EXF$:CLOSE EXF:KILL EXF$
1040 PXN$=SFBN$+".PAX":PXN=1:OPEN"O",PXN,PXN$:CLOSE PXN:KILL PXN$:PAL$=SFBN$+".LSA":PAL=2:OPEN"O",PAL,PAL$:CLOSE PAL:KILL PAL$:PCF$=SFBN$+".PCD":PCF=3:OPEN"I",PCF,PCF$:CLOSE PCF
```
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