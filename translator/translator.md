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
22010 OPEN"R",#RTS,RTS$,RLN:FIELD#RTS,RLN AS RCRD$:GET#RTS,1:TBAD=FNWDV(RCRD$,3)-&H100:TBRN=FNRCN(TBAD,RLN):TBOF=FNOFS(TBAD,RLN):IF TBOF<>0 THEN PRINT"RTS info should start at offset 0, but offset is"TBOF:STOP
```
The first record is read from the RTS-file into string ```RCRD$```. It contains at byte offset 3 the address where the table with runtime routines is stored in the file. This address is stored in ```TBAD```. Note that this table is part of file processed by the 8080 assembler and the loader of CP/M (```ASM``` and ```LOAD```), so it is supposed to be loaded at address 0100 hex. To find out in which record of the RTS-file this table is stored, the 0100 hex offset is first subtracted and then the record number and the offset within that record are computed and stored in ```TBRN``` and ```TBOF```, respectively. The offset within the record is supposed to be 0, and so if it is not this is assumed to be an error, and the Translator will stop in that case. This has been added as a sanity check.
```
22020 IF DBG>1 THEN PRINT"RTS info on page "FNHEXN$(TBRN,2)
22030 GET#RTS,TBRN+1:VN.MJ=FNBTV(RCRD$,0):VN.MN=FNBTV(RCRD$,1):VN.BF=FNBTV(RCRD$,2):PROGB=FNWDV(RCRD$,4):TBL.LNADR=FNWDV(RCRD$,6)-&H100:INILA=FNWDV(RCRD$,8)-&H100:STCK=FNWDV(RCRD$,10)
22040 IF VN.MJ<>MJR OR VN.MN<MNR THEN PRINT"Incompatible RTS version!":STOP
```
Next, the record containing the *RTS* information is read from disk. (Note that, in CP/M records are numbered starting at 1.) The first three bytes contain the major, minor and bug fix version numbers. The major and minor version numbers are compared to the expected major and minor version numbers and if they don't match the translation is aborted.
In addition the following information is read from this table:

- ```PROGB``` location *in memory* where the translated P-code program starts;
- ```TBL.LNADR```: location *in the RTS* file of the table containing the *RTS* routines;
- ```INILA```: location *in the RTS* file of the initialisation routine;
- ```STCK```: location *in memory* of the routine that checks the stack end address.
```

22050 IF DBG>1 THEN PRINT"RTS version:"VN.MJ"."VN.MN"."VN.BF:PRINT"Translated P-code starts at "FNHEXN$(PROGB,4):PRINT"RTS table is at file address "FNHEXN$(TBL.LNADR,4):PRINT"INIT is at file address "FNHEXN$(INILA,4)
```
If debugging is on, the *RTS* information is printed.
```
22060 GET#RTS,FNRCN(TBL.LNADR,RLN)+1:TABLELEN=FNWDV(RCRD$,0)
```
Next, the first record that cwhereontains the start of the table with runtime routine addresses is loaded. This table starts with a word defining the tables total length. The name of the variable ```TBL.LNADR``` is derived from this: it is the address of the word containing the length of the table.
```
22070 DIM PRTB[63]:FOR I=O TO TABLELEN-1:PRTB[I]=FNWDV(RCRD$,2+2*I):NEXT:IF DBG>2 THEN PRINT"RTS addresses:":FOR I=0 TO TABLELEN-1:PRINT I,FNHEXN$(PRTB[I],4):NEXT:PRINT
```
The array ```PRTB``` contains the assembler addresses of the runtime routines. These addresses are read from the *RTS* file, and, if the debug level is higher than 2, these addresses are printed as well. Note that the array ```PRTB``` is DIMensioned with a fixed value. That is done to facilitate processing of this file by the Microsoft BASIC compiler, which does not allow variable array dimensions.
```
22080 DIM P2R[8]:J=2*TABLELEN:FOR I=0 TO 8:P2R[I]=FNWDV(RCRD$,2+J+2*I):NEXT
```
Next, the addresses of all standard procedures are read from the *RTS* file and stored in array ```P2R``` (standard **P**rocedure **2** (to) **R**outine)
```
22090 IF DBG>2 THEN FOR I=0 TO 8:PRINT OPCODE$[I],FNHEXN$(P2R[I],4):NEXT
```
If the debug level is 3 or higher, the addressess if the satndard routines are printed as well.
```
22100 IF DBG>0 THEN PRINT" Done reading RTS table"
```
That concludes reading the information from the RTS tables.
```
22110 IF DBG>0 THEN PRINT"Copying RTS"
```
Next, the *RTS* routines are copied to the executable file.
```
22120 OPEN"R",#TAF,TAF$,RLN:FIELD#TAF,RLN AS DST$
```
In addition to the *RTS* file, the executable file is openend for **R**andom access.
```
22130 NBTS=PROGB-&H100:NPGS=(NBTS+RLN-1)\RLN:IF DBG>1 THEN PRINT" Copying "NBTS"("HEX$(NBTS)") bytes = "NPGS" ("HEX$(NPGS)") pages"
```
```NBTS```, the number of bytes to transfer from the *RTS* file to the executable file is computed by subtracting the start address of the ```.COM```-file (0100 hex) from the memory location where the translated program begins, ```PROGB```. Next, the number of pages of length ```RLN``` to transfer from the *RTS* file to the executable file is computed.
```
22140 FOR I=1 TO NPGS:GET#RTS,I:LSET DST$=RCRD$:PUT#TAF,I:IF DBG>1 THEN PRINT I;
22150 NEXT:IF DBG>1 THEN PRINT
```
Next, ```NPGS``` pages are transferred to the executable file.
```
22160 IF DBG>0 THEN PRINT" Done copying RTS"
22170 CLOSE #RTS,#TAF
22180 RETURN
```
That concludes processing the *RTS* file.

### Scanning the P-Code File for Targeted LOD Instructions

```
20000 IF DBG>0 THEN PRINT"Scanning for JMP/JPC targeting LODs"
20010 OPEN"R",#PCF,PCF$,4:FIELD#PCF,2 AS CO1$,2 AS CO2$:PCPI=0
```
The file containing the P-code is opened.
```
20020 GOSUB 12300:PRINT PCPI;CHR$(13);:WHILE NOT FNEOPF(CO1,CO2):GOSUB 20100:PCPI=PCPI+1:GOSUB 12300:PRINT PCPI;CHR$(13);:WEND
```
The first instruction is fetched from the P-code file. The subroutine at line 12300 puts the two words fetched in CO1 and CO2, and decodes the first word into two bytes Q1 and Q2, with Q1 containing the most significant byte.

As long as these two words do not signify the end of the P-code file, each P-code instruction is processed by checking if it is a ```JMP``` or a ```JPC```, and, if it is, check wether the jump target is a ```LOD``` instruction. If so, the adres of this ```LOD``` instruction is saved.
```
20030 CLOSE#PCF
```
The P-code file no longer needs to be accessed, so it is closed.
```
20040 IF TLDI>0 THEN GOSUB 20300:IF DBG>0 THEN PRINT" "TLDI"targeted LODs found":IF DBG>1 THEN FOR I=0 TO TLDI-1:PRINT TLOD[I]:NEXT
```
Next, the addresses of the ```LOD``` instructions found are sorted.
```
20050 IF TLDI>0 THEN GOSUB 20400:IF DBG>0 THEN PRINT" "TLDI"unique targeted LODs":IF DBG>1 THEN FOR I=0 TO TLDI-1:PRINT TLOD[I]:NEXT
```
The last step is to remove duplicates from the list of addresses of targeted ```LOD``` instructions.
```
20060 IF DBG>0 THEN PRINT" Done scanning"
20070 RETURN
```
That concludes scanning for targeted ```LOD``` instructions.
#### Looking for a Targeted ```LOD``` Instruction
```
20100 IF Q1<>6 AND Q1<>7 THEN RETURN
```
Check if this instruction is ```JMP``` or a ```JPC```. If not, we're done.
```
20110 GET#PCF,CO2+1:TQ1=CVI(CO1$)\256:IF TQ1<>2 THEN RETURN
```
Next, check if the target of the ```JMP``` or ```JPC``` is a ```LOD``` instruction. If not, we're done.
```
20120 TLOD[TLDI]=CO2:TLDI=TLDI+1:PRINT:RETURN
```
Store the address of the ```LOD``` instruction (```CO2```) in the list ```TLOD```.

#### Sorting the List of Targeted ```LOD```s
```
20300 IF DBG>0 THEN PRINT" Sorting"
20310 FOR I=TLDI-1 TO 1 STEP -1:FOR J=0 TO I-1:IF TLOD[J]>TLOD[J+1]THEN SWAP TLOD[J],TLOD[J+1]
20320 NEXT J,I
20330 RETURN
```
Sorting is done through a simple bubble sort. The number of targeted ```LOD``` is usually small, so a fancier sorting method is overkill.

#### Removing Duplicate Addresses From the Sorted List of Targeted ```LOD```s
```
20400 IF DBG>0 THEN PRINT" Removing duplicates"
20410 J=0:FOR I=1 TO TLDI-1:IF TLOD[I]<>TLOD[J]THEN J=J+1:TLOD[J]=TLOD[I]
20420 NEXT:IF TLDI>0 THEN TLDI=J+1
20430 RETURN
```
This algorithm simply squeezes duplicates from the list. The invariant of this loop is: all adresses from 0 to ```J``` are unique. Only if the address at ```I``` is different from the address at ```J```, ```J``` is advanced, and the item at ```I``` is copied to position ```J```.

The last step is to correct the number of addresses of targeted ```LOD``` instructions, ```TLDI```, in the squeezed list. As the index of unique addresses in the list ranges from 0 to ```J```, this number is ```J```+1.

### Tranlating the P-code Instructions
```
23000 IF DBG>0 THEN PRINT"Translating"
23010 OPEN"R",#PXN,PXN$,2:FIELD#PXN,2 AS ACPI$
23020 OPEN"R",#TAF,TAF$,1:FIELD#TAF,1 AS OBT$:ACPI=PROGB
23030 OPEN"R",#PCF,PCF$,4:FIELD#PCF,2 AS CO1$,2 AS CO2$:PCPI=0
```
The tranlsation process is started by opening the file PXN that holds the cross link between P-code addresses and 8080-assembly language instructions. This file simply contains 8080 assembly language instruction addresses. Therefore, it is accessed a 16 bit word at a time.

The temporary 8080-assembly language file, TAF is then opened. This file accessed at a bye level. Note that the pointer into the file is initialised to```PROGB```, the address where the translated program will b stored.
And last but not least the file containing the P-code instructions is opened. This file is accessed two 16 bit words at a time. The P-code program index, ```PCPI```, is initialised to the first P-code instruction at P-code address 0.

All files are opened in random access mode.
```
23040 DIM REFS[1000,1]:NRFS=0:TRF=0:TLDX=0
```
If a P-code instruction references another P-code instruction with a larger address, called a forward reference, the location of that P-code instruction must be stored in order to enable the translator to fix that address later, once the 8080-assembly language instruction address is known. Variable ```NRFS``` keeps track of the total number of forward references.
```
23050 GOSUB 12300:WHILE NOT FNEOPF(CO1,CO2):GOSUB 12200:GOSUB 12400:GOSUB 24000:GOSUB 12500:PCPI=PCPI+1:GOSUB 12300:WEND:IF DBG=0 THEN PRINT
```
Translation begins by getting the first P-code instruction from file PCF, using the subroutine at line 12300.
Then, as long as the P-code instruction is not the end of file marker for the P-code file, each instruction is processed as follows:

- the 8080-assembly language addressed is stored in file PXN;
- if the debug level is at least 1, the P-code instruction together with its location in the P-code file and the location in the 8080-assembly language file where the translated code will be stored are printed;
- the P-code instruction is translated into 8080-assembly language;
- if the debug level is at least 1, some debugging information and optimisation iformation is printed;
- the next P-code instruction is fetched.
```
23060 SBM=ACPI:MXPI=PCPI
```
The address of the first byte after the last 8080-assembly language instruction is stored in ```SBM```, and the number of P-code instructions is stored in ```MXPI```.
```
23100 IF DBG>0 THEN PRINT"Fixing"NRFS"references"
23110 FOR RFIX=0 TO NRFS-1:PCAD=REFS[RFIX,0]:ACPI=REFS[RFIX,1]:GET#PXN,PCAD+1:OWD=CVI(ACPI$)
23120 IF DBG>0 THEN IF DBG>1 THEN PRINT"Forward reference: P-code address is "PCAD" = "FNHEXN$(OWD,4)" @ "FNHEXN$(ACPI,4) ELSE PRINT RFIX+1;CHR$(13);
23130 GOSUB 12700:NEXT
```
Next, the forward references are fixed, using array ```REFS[,]```. The first column of this array contains the P-code address of the referenced instruction. The equivalent 8080-assembly language instruction address can simply be looked up in the file ```PXN```. Because a P-code instruction is in general translated into multiple 8080-assembly code instructions, we also must know where the 8080-assembly code address of the P-code instruction must be stored. That 8080-assembly code address is stored in the second column of array ```REFS[,]```.

Then, this address is stored in the 8080-assembly code file ```TAF```. Note that the debug information must be printed before the address is stored because storing the address updates variable ```ACPI```.
```
23140 CLOSE#PXN,#TAF,#PCF
23150 IF DBG>0 THEN PRINT" Done translating and fixing references"
23160 RETURN
```
And that concludes processing the sequence of P-code instructions, so all files can be closed again.

### Translating one P-code Instruction

```
24000 ON (Q1 MOD 16)+1 GOTO 24100,24200,24400,24500,24600,24730,24810,24920,25010,25100,25100,25100,25100,25100,25100,25100
24010 REM: TRANSLATE:       LIT   OPR   LOD   STO   CAL   INT   JMP   JPC   CSP   ERR...
```
The opcode of the P-code instruction is stored in the first five bits of the first byte of the first word of a P-code instruction. Note that if the fifth bit is on, then this instruction uses indexed addressing.

#### Translating the *LIT* Instruction

```
24100 REM:LIT 0,N: LXI B,N:CALL LIT
24110 IF OPL>1 AND CO2=0 THEN 24140
24120 OBT=&H1:GOSUB 12600:OWD=CO2:GOSUB 12700
24130 OBT=&HCD:GOSUB 12600:OWD=PRTB[P2R[Q1]]:GOTO 12700
```
In general, a *LIT 0,N*-instructon is translated into:
```
     LXI  B,N
     CALL LIT
```
If the optimisation level is 0, then this sequence of instructions is generated.
```
24140 OBT=&HAF:GOSUB 12600:FOR I=1 TO 2:OBT=&H13:GOSUB 12600:OBT=&H12:GOSUB 12600:NEXT:OBT=&HCD:GOSUB 12600:OWD=STCK:GOSUB 12700
24150 NOPT[2]=NOPT[2]+1:OPT$=", O2":RETURN
```
If the optimisation level is 2 or more, **and** N=0, then the next sequence of instructions is generated:
```
     XOR  A    ; Clear A
     STAX D    ; Store first byte on top of stack
     INX  D    ; Increment stack pointer
     STAX D    ; Store second byte on top of stack
     INX  D    ; Increment stack pointer
     CALL STCK ; Check for stack overflow
```
Note that in the original translator this last stack-checking step was omitted. This could lead to unexpected stack overflow in some cases. It happened, e.g., in the Ackermann-function example.
#### Translating the *OPR 0,N* Instruction
```
24200 REM OPR 0,N: CALL OPR00$NN, EXCEPT FOR OPR 0,0: JMP OPR00$00
24210 IF OPL>1 AND (CO2=1 OR CO2=2 OR CO2=3)THEN 24240
```
In principle, the translation of an ```OPRN 0,n``` P-code instruction is simply a matter of calling the assembly language subroutine that implements the instruction. In case optimisations are switched on, and the ```OPR``` is a negate, an add, or a subtract instruction, this process is less straight forward.
```
24220 IF CO2=0 THEN OBT=&HC3 ELSE OBT=&HCD
24230 GOSUB 12600:OWD=PRTB[P2R[Q1]+CO2]:GOTO 12700
```
There is one exception: of the operation to be called is OPR ```0,0```, a return from a function or a procedure, then the address of the next instruction to be executed is not the next instruction in the sequence, but is on the stack. ```OPR 0,0``` removes this address from the stack, and continues execution at this address: therefore, the assembly language subroutine implementing the ```OPR 0,0``` should not return. And because of that, the routines is not called, but jumped to. That distinction is made by either emitting a ```CALL adr``` or a ```JMP adr```.
The addresses of all **OP**e**R**ations are stored in array ```PRTB```, starting at index ```P2R[Q1]```, where Q1 is the P-code opcode of the ```OPR``` instruction.

Next, we get to the optimised ```OPR 0,N``` instructions:
```
24240 GET#PCF,PCPI:PCO1=CVI(CO1$):PCO2=CVI(CO2$):PQ1=PCO1\256:IF PQ1<>0 THEN 24220 ELSE IF CO2=1 THEN 24250 ELSE IF CO2=2 OR CO2=3 THEN 24270 ELSE STOP'CO2 (=OPR)  SHOULD BE 1, 2 OR 3
```
PCO1, PCO2 and PQ1 are the CO1, CO2 and Q1 of the P-code instruction immediately preceding the current one. If that previous instruction is *not* a ```LIT``` instruction, then there is nothing to optimise.
If the current instruction is a negate ```OPR 0,1``` then continue at line 24250. If it is an add ```OPR 0,2``` or a subtract ```OPR 0,3``` then continue at line 24270. If it is none of these three operations, something is wrong.
```
24250 IF PCO2=0 THEN NOPT[2]=NOPT[2]+1:OPT$=", O2Q":RETURN
```
If the previous instruction is a ```LIT 0,0``` and the current instruction is a negate, then do not generate code (-0=0). The array ```NOPT[]``` keeps track of all optimisations, and the ```OPT$``` is used to print some information about the optimisation.

```
24260 ACPI=ACPI-5:OWD=-CO2:GOSUB 12700:ACPI=ACPI+3:NOPT[2]=NOPT[2]+1:OPT$=", O2":RETURN
```
Replace the constant n in the ```LIT 0,n``` instruction by -n. That means going back 5 bytes in the assembly language program, followed by emitting the negative constant ```CO2```, being two bytes, and then forwarding 3 bytes again to get back to address where the next assemby language instruction is to be placed.

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
```
24400 IF OPL<2 THEN 24500
24410 GET#PCF,PCPI:PCO1=CVI(CO1$):PQ1=PCO1\256:PQ2=PCO1 MOD 256:PCO2=CVI(CO2$):IF PQ1=2 AND OPL>1 AND PQ2=Q2 AND PCO2=CO2 THEN NOPT[2]=NOPT[2]+1:OPT$=", O2":OBT=&HCD:GOSUB 12600:OWD=PRTB[P2R[1]+21]:GOSUB 12700:OBT=&HCD:GOSUB 12600:OWD=STCK:GOTO 12700
24420 IF PQ1<>3 OR OPL<3 OR PQ2<>Q2 OR PCO2<>CO2 THEN 24500 ELSE WHILE TLDX<TLDI AND TLOD[TLDX]<PCPI:TLDX=TLDX+1:WEND:IF TLOD[TLDX]=PCPI THEN OPT$=", X":GOTO 24500
24430 NOPT[3]=NOPT[3]+1:OPT$=", O3":OBT=&H13:GOSUB 12600:GOTO 12600
2
```
