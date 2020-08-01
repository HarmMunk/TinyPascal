10 DEFINT A-Z:FALSE=0:TRUE=NOT FALSE
20 CLS$=CHR$(27)+"[2J"+CHR$(27)+"[H":SGNON$=CLS$+"P-CODE TO 8080 TRANSLATOR"
30 IF TDRIVER=0 THEN PRINT SGNON$ ELSE PRINT"Translating...";:REM DO THIS INTERACTIVELY
40 IF TDRIVER=1 THEN DEBUG=0 ELSE DEBUG=1:REM WE ASSUME THAT RUNNING THE TRANSLATOR INTERACTIVELY IS FOR DEBUGGING
100 DEF FNHEXN$(A,N)=STRING$(N-LEN(HEX$(A)),"0")+HEX$(A):REM MAKE AN N-DIGIT HEX-REPRESENTATION OF A
101 DEF FNMEMW(I!)=I!+(I!>32767)*65536!:REM TURN REAL NUMBER POSSIBLY LARGER THAN 32676 INTO AN INT BETWEEN -32768 AND 32767
102 DEF FNABSW!(I.)=I.-(I.<0)*65536!:REM TURN INTEGER I BETWEEN -32768 AND 32767 INTO A REAL BETWEEN 0 AND 65535
103 DEF FNHIGH.BYTE(I)=INT(FNABSW!(I)/256):DEF FNLOW.BYTE(I)=FNABSW!(I)-FNHIGH.BYTE(I)*256:REM GET THE MSB, OR THE LSB OF A WORD
104 DEF FNEO.PCFILE(CO1, CO2)= CO1=&HFFFF AND CO2=&HFFFF:REM END OF PCODE FILE
120 IF TDRIVER=0 THEN INPUT"p-code file name (.PCD is assumed)";SFBN$
125 PFN$=SFBN$+".PCD":PLN$=SFBN$+".$$$":REM PLN IS A TEMPORARY RANDOM ACCESS FILE CONTAINING P-CODE LABELS
130 OPEN"I",#3,PFN$:CLOSE#3:REM THIS OPEN AND CLOSE VERIFIES THAT THE P-CODE FILE EXISTS BEFORE IT IS OPENED AS A RANDOM ACCESS FILE, BECAUSE THAT OPERATION ALWAYS SUCCEEDS
140 OPEN"R",#2,PLN$,1:FIELD#2,1 AS OUT.BYTE$:AC.PI=&H100:REM AC.PI IS THE 8080-CODE PROGRAM INDEX. TRANSLATED CODE STARTS AT 0100H IN CP/M
150 OPEN"R",#3,PFN$,4:FIELD#3,2 AS CO1$,2 AS CO2$
170 PRUN.FN$="PRUN.HEX":OPEN"I",#1,PRUN.FN$:GOSUB 10000:REM OPEN THE FILE CONTAINING THE PCODE RUN TIME ROUTINES
180 GOSUB 8000
190 GOSUB 7000:REM COPY THE 8080 P-CODE ROUTINES TO THE TRANSLATED CODE FILE
200 CLOSE#1:REM PRUN.HEX NOT NEEDED ANYMORE
210 GOSUB 9060
220 GOSUB 9000
230 GOSUB 9200
240 OPEN"R",#1,SFBN$+".PAX",2:FIELD#1,2 AS AC.PI$:GOSUB 6000:CLOSE#1,3:REM OPEN THE ? FILE, TRANSLATE, CLOSE THE ? FILES
250 STACK.BOTTOM=AC.PI:GOSUB 11100:GOSUB 2000
260 IF N.LAB<>LAB.INDX THEN PRINT"Missed a label."
270 IF N.REF>REF.INDX THEN PRINT "Missed a reference."
280 IF DEBUG>0 THEN PRINT"Stack starts at ";FNHEXN$(STACK.BOTTOM,4)
290 KILL SFBN$+".$$$":KILL SFBN$+".PAX"
300 CLOSE#1,#2,#3:IF TDRIVER=1 THEN PRINT
310 IF TDRIVER=1 THEN SYSTEM ELSE END
999 STOP
2000 IF DEBUG>O THEN PRINT"Listing P-codes and addresses"
2010 ON ERROR GOTO 2900:OPEN"I",#1,SFBN$+".LST":ON ERROR GOTO 0:GOSUB 2100:CLOSE #1
2020 GOSUB 2200
2030 ON ERROR GOTO 0:IF DEBUG>0 THEN PRINT" Done listing p-codes and addresses"
2040 CLOSE#1:RETURN
2090 IF DEBUG>O THEN PRINT" Done listing P-codes and addresses"
2095 CLOSE#1:RETURN
2100 OPEN"O",#2,SFBN$+".LSA"
2110 WHILE NOT EOF(1):LINE INPUT#1,L$:PRINT#2,L$:WEND
2120 RETURN
2200 OPEN"R",#3,PFN$,4:FIELD#3,2 AS CO1$,2 AS CO2$
2210 OPEN"R",#1,SFBN$+".PAX",2:FIELD#1,2 AS AC.PI$
2220 R=3:L=MAX.PC.PI:N=L\R-((L MOD R)<>0)
2230 FOR I=0 TO N-1:FOR J=0 TO R-1:PC.PI=I+J*N
2240 IF PC.PI>=L THEN 2270
2250 GOSUB 9050:GET#1,PC.PI+1:AC.PI=CVI(AC.PI$):IF Q1>15 THEN IDX$="X" ELSE IDX$=" "
2260 PRINT#2,USING"#####=\  \:\ \! ###_,######";PC.PI;FNHEXN$(AC.PI,4);OPCODE$[Q1 MOD 16];IDX$;Q2;CO2;
2270 NEXT J:PRINT#2,:NEXT I
2280 PRINT#2,"Stack starts at ";FNHEXN$(STACK.BOTTOM,4)
2290 CLOSE#1,#2,#3
2300 RETURN
2900 IF ERR=53 AND ERL=2010 THEN RESUME 2040 ELSE ON ERROR GOTO O
4999 REM STORE ADDRESS WHERE REFERENCE IS TO BE PATCHED IN
5000 REFS[REF.INDX,1]=AC.PI:REF.INDX=REF.INDX+1
5010 IF DEBUG>1 THEN PRINT "REFS[";REF.INDX-1;",1]=";FNHEXN$(AC.PI,4)
5020 RETURN 
6000 IF DEBUG>0 THEN PRINT"Translating"
6005 LAB.INDX=0:REF.INDX=0:PC.PI=0:REM RESET ,, AND CODE INDEX
6010 GOSUB 9050:WHILE NOT FNEO.PCFILE(CO1,CO2):GOSUB 6100:GOSUB 6200:PC.PI=PC.PI+1:GOSUB 9050:WEND
6020 IF DEBUG>0 THEN PRINT" Done translating"
6030 RETURN
6100 IF LABEL[LAB.INDX,0]=PC.PI THEN LABEL[LAB.INDX,1]=AC.PI:LAB.INDX=LAB.INDX+1:IF DEBUG>1 THEN PRINT" HIT,";:REM STORE THE 808-ADDRESS OF THE LABEL
6110 IF DEBUG>1 THEN PRINT USING"####:&";PC.PI;FNHEXN$(AC.PI,4)
6120 LSET AC.PI$=MKI$(AC.PI):PUT#1,PC.PI+1
6130 RETURN
6199 REM: TRANSLATE:       LIT  OPR  LOD  STO  CAL  INT  JMP  JPC  CSP  ERR...
6200 ON (Q1 MOD 16)+1 GOTO 6250,6300,6350,6400,6500,6600,6650,6700,6750,6990,6990,6990,6990,6990,6990,6990
6250 REM:LIT 0,N: LXI B,N:CALL LIT
6260 OUT.BYTE=&H1:GOSUB 11050:OUT.WORD=CO2:GOSUB 11060
6270 OUT.BYTE=&HCD:GOSUB 11050:OUT.WORD=PRTABLE[LIT.X]:GOTO 11060
6300 REM OPR 0,N: CALL OPR00$NN, EXCEPT FOR OPR 0,0: JMP OPR00$00
6301 IF CO2=0 THEN OUT.BYTE=&HC3 ELSE OUT.BYTE=&HCD:REM OPR 0 IS PROCEDURE/FUNCTION RETURN: NO NEED TO RETURN
6310 GOSUB 11050:OUT.WORD=PRTABLE[OPR.X+CO2]:GOTO 11060
6350 REM: LOD(X) LVL, ADR
6351 PR.INDEX=LOD.X
6359 REM                                         CALL LODA
6360 STAT.LVL=Q2:IF STAT.LVL=255 THEN OUT.BYTE=&HCD:GOSUB 11050:OUT.WORD=PRTABLE[PR.INDEX-1]:GOTO 11060: LOD 255,ADDR
6361 REM      MVI A, STAT.LVL                                LXI BC, ADDR
6370 OUT.BYTE=&H3E:GOSUB 11050:OUT.BYTE=STAT.LVL:GOSUB 11050:OUT.BYTE=&H1:GOSUB 11050:OUT.WORD=2*CO2:GOSUB 11060
6371 REM      CALL LOD, OR  CALL LODX
6380 OUT.BYTE=&HCD:GOSUB 11050:INDEXED=-(Q1>15):OUT.WORD=PRTABLE[PR.INDEX+2*INDEXED+1]:GOTO 11060
6400 PR.INDEX=STO.X:GOTO 6360:REM POINT TO STO IN PR TABLE, REST IS SAME AS LOD
6500 REM:CAL LVL, ADDR
6510 STAT.LVL=Q2:IF STAT.LVL=255 THEN OUT.BYTE=&HCD:GOSUB 11050:OUT.WORD=PRTABLE[CAL.X-1]:GOTO 11060:REM CAL 255, ADDR
6519 REM: MVI A, LVL; CALL CAL:REMARK: THE CAL ROUTINE ONLY SETS UP THE PR STACK
6520 OUT.BYTE=&H3E:GOSUB 11050:OUT.BYTE=STAT.LVL:GOSUB 11050:OUT.BYTE=&HCD:GOSUB 11050:OUT.WORD=PRTABLE[CAL.X+1]:GOSUB 11060
6521 REM       JMP ADDR
6530 OUT.BYTE=&HC3:GOSUB 11050:GOSUB 5000:OUT.WORD=0:GOTO 11060
6598 REM INT 0, N
6599 REM        LXI H, 2*N                                          CALL INT
6600 OUT.BYTE=&H21:GOSUB 11050:OUT.WORD=CO2*2:GOSUB 11060:OUT.BYTE=&HCD:GOSUB 11050:OUT.WORD=PRTABLE[INT.X]:GOTO 11060
6649 REM        JMP ADDR
6650 OUT.BYTE=&HC3:GOSUB 11050:GOSUB 5000:OUT.WORD=0:GOTO 11060
6698 REM JPC 0,ADDR OR JPC 1,0
6699 REM      LDAX D          ;         DCX D           ;           DCX D         ;         RAR             ;             JNC           OR            JNC
6700 OUT.BYTE=&H1A:GOSUB 11050:OUT.BYTE=&H1B:GOSUB 11050:OUT.BYTE=&H1B:GOSUB 11050:OUT.BYTE=&H1F:GOSUB 11050:IF Q2=0 THEN OUT.BYTE=&HD2 ELSE OUT.BYTE=&HDA
6710 GOSUB 11050:GOSUB 5000:OUT.WORD=0:GOTO 11060
6749 REM CSP
6750 IF CO2<6 THEN OUT.BYTE=&HCD:GOSUB 11050:OUT.WORD=PRTABLE[SP.X+CO2]:GOTO 11060:REM CAL CSP
6760 IF CO2<>8 THEN PRINT"Error: unknown SP:";CO2:STOP
6768 REM: OUTPUT STRING
6769 REM:                                                                                        MVI B, STR.LEN
6770 OLD.PC.PI=PC.PI:PC.PI=OLD.PC.PI-1:GOSUB 9050:STR.LEN=CO2:AC.PI=AC.PI-6*(STR.LEN+1):OUT.BYTE=&H6:GOSUB 11050:OUT.BYTE=FNLOW.BYTE(STR.LEN):GOSUB 11050
6779 REM:       CALL SP8;                                                                                                     DB STRING[0], STRING[1], ...
6780 OUT.BYTE=&HCD:GOSUB 11050:OUT.WORD=PRTABLE[SP.X+6]:GOSUB 11060:FOR I=1 TO STR.LEN:PC.PI=OLD.PC.PI-STR.LEN-2+I:GOSUB 9050:OUT.BYTE=FNLOW.BYTE(CO2):GOSUB 11050:NEXT:PC.PI=OLD.PC.PI:RETURN
6900 PRINT"Error: illegal subroutine call":STOP
6990 PRINT"Illegal P-code":STOP
7000 IF DEBUG>0 THEN PRINT"Copying RTS"
7005 GOSUB 10150:WHILE NOT PREOF:IF DEBUG>2 THEN PRINT FNHEXN$(PRVALUEADDR,4),FNHEXN$(AC.PI,4),FNHEXN$(PRVALUEB,2)
7010 OUT.BYTE=PRVALUEB:OUT.BYTE.ADDR=PRVALUEADDR:GOSUB 11000:GOSUB 10150:WEND
7020 IF PROR<>AC.PI THEN PRINT"Sync error: Assembly code does not start at ";FNHEXN$(PROR,4);" but at ";FNHEXN$(AC.PI,4):STOP
7030 IF DEBUG>0 THEN PRINT" Done copying RTS"
7040 RETURN
8000 IF DEBUG>0 THEN PRINT"Reading RTS table"
8005 PRID$="":FOR I=1 TO 4:GOSUB 10150:PRID$=PRID$+CHR$(PRVALUEB):NEXT:IF PRID$<>"PR01"THEN PRINT"ERROR: FILE ID '";PRID$;"' => 'PRO1'":STOP 
8010 GOSUB 10170:TABLELEN=PRVALUEW:IF DEBUG>1 THEN PRINT"RTS tablelength:";TABLELEN
8020 DIM PRTABLE[TABLELEN-1]:FOR I=O TO TABLELEN-1:GOSUB 10170:PRTABLE[I]=PRVALUEW:NEXT
8030 GOSUB 10170:PROR=PRVALUEW:REM FOR I=O TO TABLELEN-1:PRINT I,FNHEXN$ PRTABLE[I], 4):NEXT:
8035 IF DEBUG>0 THEN PRINT"PROGRAM STARTS AT ";FNHEXN$(PROR,4)
8040 INIT.X=0:LIT.X=1:INT.X=2:OPR.X=16:LOD.X=4:STO.X=9:SP.X=40:CAL.X=14
8050 IF DEBUG>0 THEN PRINT" Done reading RTS table"
8060 RETURN
9000 IF DEBUG>0 THEN PRINT"Collecting addresses"
9005 PC.PI=0:N.REF=0:GOSUB 9050
9010 WHILE NOT FNEO.PCFILE(CO1,CO2):GOSUB 9100:PC.PI=PC.PI+1:GOSUB 9050:WEND:MAX.PC.PI=PC.PI:REM COUNT HOW MANY PCODE INSTRUCTIONS REFER TO A PCODE ADDRESS
9020 N.LAB=N.REF:PC.PI=0:GOSUB 9050:DIM REFS[N.REF-1,1],LABELS[N.REF-1]:REF.INDX=0:LAB.INDX=0:IF DEBUG>1 THEN PRINT N.REF;" references"
9030 WHILE NOT FNEO.PCFILE(CO1,CO2):GOSUB 9150:PC.PI=PC.PI+1:GOSUB 9050:WEND:IF N.REF<>REF.INDX THEN PRINT"Error: missed a reference!":STOP
9040 IF DEBUG>0 THEN PRINT" Done collecting addresses"
9045 RETURN:REM REFS[I,0] CONTAINS THE PCODE ADDRESSES CALLED/JUMPED TO, LABELS[] CONTAINS PCODE TARGET ADDRESSSES
9050 GET#3,PC.PI+1:CO1=CVI(CO1$):CO2=CVI(CO2$):Q1=CO1\256:Q2=CO1 MOD 256:RETURN:REM GET NEXT P-CODE FROM P-CODE FILE                    
9060 DIM OPCODE$[8],OPC.MAP[8]:RESTORE 9060:FOR I=0 TO 8:READ OPCODE$[I],OPC.MAP[I]:NEXT:RETURN
9070 DATA LIT,1,OPR,16,LOD,4,STO,9,CAL,14,INT,2,JMP,0,JPC,0,CSP,38
9100 IF DEBUG>1 THEN PRINT USING"&: && &,&";FNHEXN$(PC.PI,4);OPCODE$[Q1 MOD 16];MID$("X ",2+(Q1\16<>0),1);FNHEXN$(Q2,2);FNHEXN$(CO2,4);
9110 IF (Q1<>4 AND Q1<>6 AND Q1<>7) OR Q2=255 THEN IF DEBUG>1 THEN PRINT:GOTO 9130 ELSE GOTO 9130:REM IF IT IS NOT A CALL, JMP OR JPC, WE'RE DONE
9120 N.REF=N.REF+1:IF DEBUG>1 THEN IF CO2>PC.PI THEN PRINT" F" ELSE PRINT" B":REM UPDATE REFERENCE COUNTER
9130 RETURN
9150 IF (Q1<>4 AND Q1<>6 AND Q1<>7) OR Q2=255 GOTO 9170:REM IF IT IS NOT A CALL, JMP OR JPC, WE'RE DONE
9160 REFS[REF.INDX,0]=CO2:REF.INDX=REF.INDX+1:LABELS[LAB.INDX]=CO2:LAB.INDX=LAB.INDX+1:IF DEBUG>1 THEN PRINT USING" &: && &,& (&)";FNHEXN$(PC.PI,4);OPCODE$[Q1 MOD 16];MID$("X ",2+(Q1\16<>0),1);FNHEXN$(Q2,2);FNHEXN$(CO2,4);FNHEXN$(LABELS[LAB.INDX-1],4)
9165 IF DEBUG>1 THEN PRINT REF.INDX-1":"FNHEXN$(REFS[REF.INDX-1,0],4)
9170 RETURN
9200 IF DEBUG>O THEN PRINT" Sorting addresses":REM DO AN OPTIMISED BUBBLE SORT ON THE LABELS
9205 FOR I=N.LAB-2 TO O STEP -1:FOR J=0 TO I:IF LABELS[J]>LABELS[J+1] THEN SWAP LABELS[J], LABELS[J+1]
9210 NEXT J,I:IF DEBUG>1 THEN PRINT:PRINT" Post-sort":FOR I=0 TO N.LAB-1:PRINT FNHEXN$(LABELS[I],4):NEXT
9220 I=0:J=1:WHILE J<N.LAB:IF LABELS[I]<>LABELS[J] THEN I=I+1:LABELS[I]=LABELS[J]:REM REMOVE DOUBLES
9230 J=J+1:WEND
9240 N.LAB=I+1:DIM LABEL[N.LAB,1]:FOR I=0 TO N.LAB-1:LABEL[I,0]=LABELS[I]:NEXT:REM COPY THE SORTED LABELS TO LABEL[,]
9250 IF DEBUG>1 THEN PRINT" Post compression":FOR I=0 TO N.LAB-1:PRINT FNHEXN$(LABEL[I,0],4):NEXT
9260 ERASE LABELS:REM DON'T NEED THAT ONE ANYMORE
9270 IF DEBUG>O THEN PRINT" Done sorting address"
9280 RETURN:REM LABELS[] IS REMOVED, LABEL[I,0] CONTAINS UNIQUE PCODE TARGET ADDRESSES
10000 PRVALUESINDEX=0:PRLINELEN=0:PRMAXLEN=16:DIM PRVALUES[PRMAXLEN-1]:RETURN:REM INITIALISE READING THE PRUN-FILE
10001 REM PRVALUESINDEX KEEPS TRACK OF THE NUMBER OF VALUES READ FROM THE PRVALUES ARRAY
10002 REM PRLINELEN CONTAINS THE NUMBER OF VLUES ON THIS LINE
10003 REM PRMAXLEN IS THE MAXIMUN NUMBER OF VALUES IN A HEX RECORD. THIS IS NORMALLY 16, BUT IT MAY BE MORE
10010 LINE INPUT#1,PRLINE$:PRLINEINDEX=1
10020 IF MID$(PRLINE$,PRLINEINDEX,1)<>":"THEN PRINT"ERROR: LINE DOES NOT START WITH A':'";PRLINE$:STOP:REM A LINE IN A HEX-FILE STARTS WITH A ":"
10030 PRLINEINDEX=PRLINEINDEX+1
10040 PRLINELEN=VAL("&H"+MID$(PRLINE$,PRLINEINDEX,2)):PRLINEINDEX=PRLINEINDEX+2:REM THE FIRST TWO BYTES OF A LINE CONTAIN THE NUMBER OF HEX VALUES ON THIS LINE
10050 IF PRLINELEN>PRMAXLEN THEN ERASE PRVALUES:PRMAXLEN=PRLINELEN:DIM PRVALUES[PRMAXLEN-1]:REM IF WE RESERVED INSUFFICIENT ROOM FOR VALUES, ADJUST. NORMALLY, 16 VALUES SHOULD SUFFICE, MAX IS 256
10060 PRLINEADR=VAL("&H"+MID$(PRLINE$,PRLINEINDEX,4)):PRLINEINDEX=PRLINEINDEX+4:REM THE NEXT TWO BYTES CONTAIN THE LOAD ADDRESS FOR THE VALUES
10070 PRLINETYPE=VAL("&H"+MID$(PRLINE$,PRLINEINDEX,2)):PRLINEINDEX=PRLINEINDEX+2:REM THE NEXT TWO BYTES CONTAIN THE RECORD TYPE FOR THIS LINE
10080 FOR PR.I=0 TO PRLINELEN-1:PRVALUES[PR.I]=VAL("&H"+MID$(PRLINE$,PRLINEINDEX,2)):PRLINEINDEX=PRLINEINDEX+2:NEXT:REM READ PRLINELEN VALUES FROM FILE AND STORE IN PRVALUES
10090 PRCHECKSUM=PRLINELEN+PRLINEADR MOD 256 + PRLINEADR\256+PRLINETYPE:REM THE CHECKSUM CONSISTS OF ALL BYTES ON A LINE SUMMED MODULO 256
10100 FOR PR.I=0 TO PRLINELEN-1:PRCHECKSUM=PRCHECKSUM+PRVALUES[PR.I]:NEXT
10110 PRCHECKSUM=PRCHECKSUM+VAL("&H"+MID$(PRLINE$,PRLINEINDEX,2)):REM ADD ALL VALUES
10120 IF PRCHECKSUM MOD 256<>0 THEN PRINT "CHECKSUM ERROR":REM THE CHECKSUM MOD 256 SHOULD BE 0
10130 PRVALUESINDEX=0:REM AFTER READING A FRESH LINE FROM THE PRUN.HEX FILE WE START RETURNING VALUES FROM 0
10140 PREOF=(PRLINELEN=0):IF PREOF THEN RETURN:IF AT END OF FILE, THEN RETURN AFTER SETTING THE PROEF FLAG
10149 REM THE NEXT LINE IS THE ENTRY POINT FOR READING A BYTE FROM THE PRUN.HEX FILE
10150 IF PRVALUESINDEX=PRLINELEN THEN GOTO 10010:REM IF WE EXHAUSTED ALL VALUES ON A LINE, GET THE NEXT LINE
10160 PRVALUEB=PRVALUES[PRVALUESINDEX]:PRVALUEADDR=PRLINEADR+PRVALUESINDEX:PRVALUESINDEX=PRVALUESINDEX+1:RETURN
10169 REM READ A WORD FROM THE FILE. CAVEAT: THE WORD MAY BE SPLIT OVER TWO LINES!
10170 GOSUB 10150:PRVALUEW=PRVALUEB:GOSUB 10150:PRVALUEW=PRVALUEW+PRVALUEB*256:PRVALUEADDR=PRVALUEADDR-1:RETURN
11000 WHILE AC.PI<OUT.BYTE.ADDR:LSET OUT.BYTE$=CHR$(OUT.BYTE):PUT#2,AC.PI-&H100+1:AC.PI=AC.PI+1:WEND
11010 IF OUT.BYTE.ADDR>AC.PI THEN PRINT"Error: can't back up in assembly code file!":STOP
11050 LSET OUT.BYTE$=CHR$(OUT.BYTE):PUT#2,AC.PI-&H100+1:AC.PI=AC.PI+1:RETURN
11060 OUT.BYTE=FNLOW.BYTE(OUT.WORD):GOSUB 11050:OUT.BYTE=FNHIGH.BYTE(OUT.WORD):GOTO 11050
11100 IF DEBUG>O THEN PRINT"Copying code and fixing references"
11105 OPEN"O",#1,SFBN$+".COM":REF.INDX=0:OPEN"R",#3,SFBN$+".PAX",2:FIELD#3,2 AS AC.PI$
11110 I=&H100:WHILE I<AC.PI:GET#2,I-&H100+1:IF I=PRTABLE[INIT.X]+1 THEN PRINT#1,CHR$(FNLOW.BYTE(STACK.BOTTOM));:I=I+1:PRINT#1,CHR$(FNHIGH.BYTE( STACK.BOTTOM));:I=I+1:GOTO 11200
11120 IF REF.INDX<N.REF THEN IF I=REFS[REF.INDX,1] THEN J=REFS[REF.INDX,O]:GET#3,J+1:K=CVI(AC.PI$):PRINT#1,CHR$(FNLOW.BYTE(K));:I=I+1:PRINT#1,CHR$(FNHIGH.BYTE(K));:I=I+1:REF.INDX=REF.INDX+1:GOTO 11200
11130 PRINT#1,OUT.BYTE$;:I=I+1
11200 WEND:CLOSE#1,#2,#3
11210 IF DEBUG>0 THEN PRINT"Done copying code and fixing references"
11220 RETURN
