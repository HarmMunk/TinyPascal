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
|2|Increase stackpointer by a small constant n (-4<n<3)<br>(See Note 1)|```INT n```|```LXI H,2n```<br>```CALL INT```|```INX D``` (repeated 2n times if n>0)<br>```CALL STACK$CHK```<br>or<br>```DCX D``` (repeated 2n times if n<0)|>)
|2|Load 0 on top of the stack<br>(See Note 1)|```LIT 0```|```LXI B,0```<br>```CALL INT```|```XRA A```<br>```STAX D```<br>```INX D```<br>```STAX D```<br>```INX D```<br>```CALL STACK$CHK```|
|2|Negate 0|```LIT 0```<br>```OPR 0,1```|```<code for LIT 0>```<br>```CALL OPR00$01```|No code|
|2|Negate constant|```LIT n```<br>```OPR 0,1```|```LXI B,n```<br>```CALL LIT```<br>```CALL OPR00$01```|```LXI B,-n```<br>```CALL LIT```|
|2|Replace adding or subtracting small constants smaller than 3 by repeated calls to ```INC``` or ```DEC```. If n=0 then the ```LIT 0``` and the ```OPR 0,m``` (m=2 or 3) is quashed|```LIT 2```<br>```OPR 0,2```<br><br>```LIT 1```<br>```OPR 0,3```|```LXI B,2```<br>```CALL OPR00$02```<br><br>```LXI B,1```<br>```CALL OPR00$03```|```CALL OPR00$13```<br>repeated n times<br><br>```CALL OPR00$14```<br>repeated n times|
|3|Store followed by a load of the same variable. Such a sequence can be quashed, but only if the load is _not_ the target of a jump or call instruction<br>(See Note 2.)|```STO v,d```<br>```LOD v,d```|```LXI B,2d```<br>```MVI A,v```<br>```CALL STO```<br>```LXI B,2d```<br>```MVI A,v```<br>```CALL LOD```|```LXI B,2d```<br>```MVI A,v```<br>```CALL STO```<br>```INX D```<br>```INX D```<br>|


**_Note_ 1.** In the original Chen and Huang translator there was no call to the ```CHECK$STC``` routine which in rare and unexpected cases could cause the stack to overflow in unwanted areas, e.g., the BDOS in CP/M.

**_Note_ 2.** This optimisation requires a pre-analysis of the whole P-code file to register all ```LOD``` instructions that are the target of a ```JMP```, ```JPC``` or ```CALL```. Because this can be a time consuming analysis, this analysis is only executed if the optimisation level is 3.

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
The array ```NOPT``` keeps track of the **N**umber of **OPT**imisations at each of the levels 1, 2 and 3. The elements of an array are initialised to 0 in MBASIC.
```
240 DIM TLOD[50]:TLDI=0
```
The array ```TLOD``` keeps track of the total number of **T**argeted ```LOD``` P-code instructions, e.i., ```LOD``` instructions that are the target of a ```JMP```, a ```JPC``` or a ```CAL``` instruction. ```TLDI``` is the **I**ndex of the first free element in array ```TLOD```.

```
1000 PRINT SGNON$:DBG=2:OPL=3
```
Print the sign-on message. Set the optimisation level (0..3).
```
1010 PRINT USING"Optimisation level = #. ";OPL;:INPUT"P-code file name (.PCD is assumed)";SFBN$
```
Print the optimisation level and ask for the name of the P-code file. The extension ```.PCD``` is assumed, meaning that the translator adds it.
```
1020 INPUT"Want P-codes listed";PLF$
```
Aks if the P-codes must be listed. Depending on the size of the P-code program, this can take quite some processing. But is does relate the P-code addresses to the 8080 assembly code addresses, so it can be usefull in debugging, especially debugging the *RTS*.

Next, the names and file numbers of a the files needed and produced by the translator are defined. All these defintions follow the same pattern:

- definition of the name of the file, which is the base name (*SFBN$*) concatenated with an extension;
- definition of the file number;
- if required, an existing version of the file is deleted. This is done by opening the file, which, if it exsists, will delete the existing file of the same name, and, if it does not exist, will simply create an empty file. Next the file is closed and "KILL"-ed, effectively deleting it. Note that simply killing the file will result in an error if the file does not exist.
```
1030 TAF$=SFBN$+".$$$":TAF=2:OPEN"O",TAF,TAF$:CLOSE TAF:KILL TAF$:EXF$=SFBN$+".COM":EXF=1:OPEN"O",EXF,EXF$:CLOSE EXF:KILL EXF$
```
```TAF``` is the temporary 8080 assembly code files. It is later renamed to the final name, ```EXF```, which is defined next.
```
1040 PXN$=SFBN$+".PAX":PXN=1:OPEN"O",PXN,PXN$:CLOSE PXN:KILL PXN$:PAL$=SFBN$+".LSA":PAL=2:OPEN"O",PAL,PAL$:CLOSE PAL:KILL PAL$:PCF$=SFBN$+".PCD":PCF=3:OPEN"I",PCF,PCF$:CLOSE PCF
```
The ```PXN``` file contains the cross references between the P-code addresses and the 8080 assembly code addresses. This file simply consists of 16 bit addresses of 8080 assembly code address. The cross reference with the P-code address is simply the location of the address in the file.

The ```PAL``` contains the P-code listing with 8080 assembly code address added.

The ```PCF``` file contains the P-code program in binary form. Next, an attempt is made to open this file (it is, obviously, not deleted!), and if that fails, the user typed the wrong name, of the file is not present.

### THe High Level Translation Process
```
1050 GOSUB 21000
```
This subroutines fills array ```OPCODE$``` with string naming the P-code instructions.
```
1060 RTS$="PRUN.LIB":RTS=3:RLN=128:GOSUB 22000
```
One more file is defined: the file containing the *RTS*. The record length, ```RLN```, for this file is set to 128 bytes. Next, tables with information of the *RTS* are read.
```
1070 IF OPL>2 THEN GOSUB 20000
```
If the optimisation level is 3, then the addresses of all ```JMP```, ```JPC``` and ```CAL``` instructions ```LOD``` instructions are required. The subroutine at line 20000 collects these address. If the P-code program is large, this process can take quite some time. Therefore it is skipped if the optimisation level excludes this optimisation.
```
1080 GOSUB 23000:GOSUB 26000
```
Next, the P-code file is translated into 8080 assembly code (the subroutine at line 23000), and the INIT routine is moved into place at the end of the generated 8080 assembly code (subroutine at line 26000).
```
1090 IF LEFT$(PLF$,1)="Y"OR LEFT$(PLF$,1)="y"THEN GOSUB 27000
```
If the user requested a P-code luisting with 8080 assembly code address (answer was stored in ```PLF```), then this file is generated by the subroutine at line 27000.
```
1100 IF DBG>0 THEN PRINT"Stack starts at ";FNHEXN$(SBM,4)
```
If the debug level is at least one the start address of the P-stack is printed.
```
1110 NAME PLN$ AS EXF$
```
The temporarily named 8080 assembly code file is renamed to a file with a name with extension ```.COM```.
```
1120 IF DBG=0 THEN KILL PXN$
```
If debuggubg is not active, then kill the P-code addresses to 8080 assembly code adresses cross reference file.

```
1130 GOSUB 28000
1140 END
```
Next, a short summary of the translation process is printed, and the program finishes.

### Initialising the ```OPCODE$``` array
This is a very simple subroutine, reading the string representation of the P-code instruction at line 21010, and storing them at the appropriate location in the ```OPCODE$``` array. E.g., a ```LOD``` instruction is represented by the opcode with the value 2, so ```OPCODE[2]``` has the value ```LOD```, etc.
```
21000 DIM OPCODE$[8]:RESTORE 21000:FOR I=0 TO 8:READ OPCODE$[I]:NEXT:RETURN
21010 DATA LIT,OPR,LOD,STO,CAL,INT,JMP,JPC,CSP
```
### Reading Information from the *RTS* File
In the subroutine starting at line 22000 information on the *RTS* is read from the runtime library file.
```
22000 IF DBG>0 THEN PRINT"Reading RTS table"
22010 OPEN"R",#RTS,RTS$,RLN:FIELD#RTS,RLN AS RCRD$:GET#RTS,1:TBAD=FNWDV(RCRD$,4)-&H100:TBRN=FNRCN(TBAD,RLN):TBOF=FNOFS(TBAD,RLN):IF TBOF<>0 THEN PRINT"RTS info should start at offset 0, but offset is"TBOF:STOP
```
The first record is read from the RTS-file into string ```RCRD$```. It contains at byte offset 3 the address where the table with runtime routines is stored in the file. Note that characters in a string are addressed starting from 1, not from 0, so the word to be read using the ```FNWDV()``` function must addrss the word at index 4, not index 3 to get the at the right address. This could, and should have been hidden in the definition of the ```FNWDV()``` function, but I decided to leave the function definition as it is.(The same hold, btw, for the definition of the ```FNBTV()``` function.) This address is stored in ```TBAD```. Note that this table is part of file processed by the 8080 assembler and the loader of CP/M (```ASM``` and ```LOAD```), so it is supposed to be loaded at address 0100 hex. To find out in which record of the RTS-file this table is stored, the 0100 hex offset is first subtracted and then the record number and the offset within that record are computed and stored in ```TBRN``` and ```TBOF```, respectively. The offset within the record is supposed to be 0, and so if it is not this is assumed to be an error, and the Translator will stop in that case. This has been added as a sanity check.
```
22020 IF DBG>1 THEN PRINT"RTS info on page "FNHEXN$(TBRN,2)
22030 GET#RTS,TBRN+1:VN.MJ=FNBTV(RCRD$,1):VN.MN=FNBTV(RCRD$,2):VN.BF=FNBTV(RCRD$,3):PROGB=FNWDV(RCRD$,5):TBL.LNADR=FNWDV(RCRD$,7)-&H100:INILA=FNWDV(RCRD$,9)-&H100:STCK=FNWDV(RCRD$,11)
22040 IF VN.MJ<>MJR OR VN.MN<MNR THEN PRINT"Incompatible RTS version!":STOP
```
Next, the record containing the *RTS* information is read from disk. The first three bytes contain the major, minor and bug fix version numbers. The major and minor version numbers are compared to the expected major and minor version numbers and if they don't match the translation is aborted.
```

22050 IF DBG>1 THEN PRINT"RTS version:"VN.MJ"."VN.MN"."VN.BF:PRINT"Translated P-code starts at "FNHEXN$(PROGB,4):PRINT"RTS table is at file address "FNHEXN$(TBL.LNADR,4):PRINT"INIT is at file address "FNHEXN$(INILA,4)
22060 GET#RTS,FNRCN(TBL.LNADR,RLN)+1:TABLELEN=CVI(MID$(RCRD$,1,2))
22070 DIM PRTB[63]:FOR I=O TO TABLELEN-1:PRTB[I]=FNWDV(RCRD$,3+2*I):NEXT:IF DBG>2 THEN PRINT"RTS addresses:":FOR I=0 TO TABLELEN-1:PRINT I,FNHEXN$(PRTB[I],4):NEXT:PRINT
22080 DIM P2R[8]:J=2*TABLELEN:FOR I=0 TO 8:P2R[I]=FNWDV(RCRD$,3+J+2*I):NEXT
22090 IF DBG>2 THEN FOR I=0 TO 8:PRINT OPCODE$[I],FNHEXN$(P2R[I],4):NEXT
22100 IF DBG>0 THEN PRINT" Done reading RTS table"
22110 IF DBG>0 THEN PRINT"Copying RTS"
22120 OPEN"R",#PLN,PLN$,RLN:FIELD#PLN,RLN AS DST$
22130 N.BYTES=PROGB-&H100:N.PAGES=(N.BYTES+127)\128:IF DBG>1 THEN PRINT" Copying "N.BYTES"("HEX$(N.BYTES)") bytes = "N.PAGES" ("HEX$(N.PAGES)") pages"
22140 FOR I=1 TO N.PAGES:GET#RTS,I:LSET DST$=RCRD$:PUT#PLN,I:IF DBG>1 THEN PRINT I;
22150 NEXT:IF DBG>1 THEN PRINT
22160 IF DBG>0 THEN PRINT" Done copying RTS"
22170 CLOSE #RTS,#PLN
22180 RETURN
```
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