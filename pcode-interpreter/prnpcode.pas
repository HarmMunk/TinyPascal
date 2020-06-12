program PrintPCodes;

	procedure exit(code : char);
	begin
		writeln('Exit (', code, ')'); call(0)
	end exit;

const
	system_error = %100;
	
	function new(length : integer) : integer;
	var
		old_a, new_a : integer;
	begin
		old_a := stacktop(0);
		new_a := stacktop(length);
		if (old_a - new_a) <> length then begin
			writeln('new -- error:', length, 'requested,', old_a - new_a, 'reserved.');
			exit(system_error + 1)
		end;
		new := new_a
	end new;
		
	procedure printHexByte(b : integer);
	var
		d : integer;

		procedure printhexdigit(d : integer);
		begin
			if d<10 then
				write(('0' + d)$)
			else write(('A' + d - 10)$)
		end printhexdigit;
		
	begin
		printhexdigit((b div 16) mod 16);
		printhexdigit(b mod 16)
	end printHexByte;
		
const
    TP_FCB_LEN = 2;     {Tiny Pascal file control block length}
    TP_FCB_BYTECNT = 0; {Tiny Pascal number of bytes read offset}
    TP_FCB_EMPTY = 1;   {Tiny Pascal sector read flag offset}
    
    CPM_BDOS_OPEN     = %0F;
	CPM_BDOS_CLOSE    = %10;
	CPM_BDOS_READSEQ  = %14;
    CPM_BDOS_SETDMA   = %1A;
    
	CPM_DFN_LEN = 12;	{CP/M disk + filename + ext length, parsed }
	
	CPM_FCB_LEN = %24;	{CP/M file control block (FCB) length }
	CPM_FCB_DISK = 0;
	CPM_FCB_NAME = 1;
	CPM_FCB_TYPE = 9;
    
    CPM_DMA_BUFLEN = 128; {CP/M size of a DMA buffer}
    
    CPM_DEFAULT_DMA = %80;  {Location of the default DMA buffer in page 0}
    
var
    CPMCurrentDMAAddress : integer;
    
    procedure CPM_Init;
    begin
        CPMCurrentDMAAddress := CPM_DEFAULT_DMA;
    end CPM_Init;
    
    procedure CPM_SetDMAAddr(addr : integer);
    var
        bdos_result : integer;
    begin
        bdos_result := bdos(CPM_BDOS_SETDMA, addr);
        CPMCurrentDMAAddress := addr
    end CPM_SetDMAAddr;
    
	function CPM_makeFCB({memory address of} name : integer) : integer;
	var
		i : integer;
		TP_FCB, CPM_FCB : integer;
	begin
		TP_FCB := new(TP_FCB_LEN + CPM_FCB_LEN + CPM_DMA_BUFLEN);
        { A TP FCB contains TP file administration, the CP/M FCB, and
        * the CP/M file DMA buffer}
        CPM_FCB := TP_FCB + TP_FCB_LEN;
		for i := 0 to CPM_DFN_LEN - 1 do
			mem[CPM_FCB + i] := mem[name + i];
		for i := CPM_DFN_LEN to CPM_FCB_LEN - 1 do	{Null rest of FCB}
			mem[CPM_FCB + i] := 0;
		CPM_makeFCB := CPM_FCB
	end CPM_makeFCB;
	
	function openFile(FCB : integer) : integer;
	begin
        mem[FCB - TP_FCB_LEN + TP_FCB_BYTECNT] := 0;
        mem[FCB - TP_FCB_LEN + TP_FCB_EMPTY  ] := 1;
		openFile := bdos(CPM_BDOS_OPEN, FCB)
	end openFile;
    
    function eof(FCB : integer) : boolean;
    var
        bdos_result : integer;
        old_DMA_addr : integer;
    begin
        if mem[FCB - TP_FCB_LEN + TP_FCB_EMPTY] = 1 then begin{ Must get next sector }
            old_DMA_addr := CPMCurrentDMAAddress;
            CPM_SetDMAAddr(FCB + CPM_FCB_LEN);
            bdos_result := bdos(CPM_BDOS_READSEQ, FCB);
            CPM_SetDMAAddr(old_DMA_addr);
            if bdos_result = 0 then begin
                mem[FCB - TP_FCB_LEN + TP_FCB_BYTECNT] := 0;
                mem[FCB - TP_FCB_LEN + TP_FCB_EMPTY] := 0;
                eof := false
            end
            else
                eof := true
        end
        else
            eof := false
    end eof;
    
    function getbyte(FCB) : char;
    var
        bytecnt : integer;
    begin
        bytecnt := mem[FCB - TP_FCB_LEN + TP_FCB_BYTECNT];
        getbyte := mem[FCB + CPM_FCB_LEN + bytecnt];
        if not eof(FCB) then
            if bytecnt = CPM_DMA_BUFLEN - 1 then
                mem[FCB - TP_FCB_LEN + TP_FCB_EMPTY] := 1
            else
                mem[FCB - TP_FCB_LEN + TP_FCB_BYTECNT] := bytecnt + 1
    end getbyte;
    
    function closeFile(FCB : integer) : integer;
    begin
        closeFile := bdos(CPM_BDOS_CLOSE, FCB)
    end closeFile;
	
const
	CPM_RAM = %0000;
	CPM_COMTAIL = %0080;
	CPM_COMTAIL_COUNT = %0080;
	CPM_FCB1 = %005C;
	CPM_FCB2 = %006C;
    
    procedure writeCPMFileName({address of} name : integer);
    var
        i : integer;
        
        procedure printNoneSpace(ch : char);
        begin
            if ch <> ' ' then
                write(ch$)
        end printNoneSpace;
        
    begin
        if mem[CPM_FCB1 + 0] > 0 then
                write((mem[CPM_FCB1] - 1 + 'A')$, ':');
        for i := 1 to 8 do
            printNoneSpace(mem[CPM_FCB1 + i]);
        write('.');
        for i := 1 to 3 do
            printNoneSpace(mem[CPM_FCB1 + 8 + i])
    end writeCPMFileName;
    
    procedure printIndexed(oc : integer);
    begin
        if oc > 16 then
            write('X')
        else
            write(' ')
    end printIndexed;
    
    procedure writePCode(oc, p1, p2 : integer);
    begin
        case oc mod 16 of
        0 : write('LIT  ');
        1 : write('OPR  ');
        2 : begin
                write('LOD'); printIndexed(oc); write(' ')
            end;
        3 : begin
                write('STO'); printIndexed(oc); write(' ')
            end;
        4 : write('CAL  ');
        5 : write('INT  ');
        6 : write('JMP  ');
        7 : write('JPC  ');
        8 : write('CSP  ');
        else
            write('???  ')
        end;
        printHexByte(p1);
        write(', ', p2)
    end writePCode;
    
    procedure writelnPCode(oc, p1, p2 : integer);
    begin
        writePCode(oc, p1, p2);
        writeln
    end writelnPCode;
    
var
	pcode_end : boolean;
	PCodeFile : integer;
    opcode, p1, p2 : integer;
    pcode_index : integer;
	
begin
	CPM_Init;
    
    if mem[CPM_COMTAIL_COUNT] < 2 then begin 
        {command tail should be at least a space and one character}
		writeln('Missing filename argument'); exit(1)
	end;

    PCodeFile := CPM_makeFCB(CPM_FCB1);
    
    if openFile(PCodeFile) = %FF then begin
        write('Could not open ''');
        writeCPMFileName(PCodeFile);
        writeln('''');
        exit(2);
	end;

    pcode_end := false; pcode_index := 0;
    while not (eof(PCodeFile) or (pcode_end)) do begin
        p1 := getbyte(PCodeFile); opcode := getbyte(PCodeFile);
        p2 := getbyte(PCodeFile) or (getbyte(PCodeFile) shl 8);
        pcode_end := (opcode = %FF) and (p1 = %FF) and (p2 = %FFFF);
        if not pcode_end then begin
            write(pcode_index, ': '); writelnPCode(opcode, p1, p2)
        end;
        pcode_index := succ(pcode_index)
    end;
    
    if closeFile(PCodeFile) = %FF then begin
        write('Could not close ''');
        writeCPMFileName(PCodeFile);
        writeln('''')
	end;
    
end PrintPCodes.
