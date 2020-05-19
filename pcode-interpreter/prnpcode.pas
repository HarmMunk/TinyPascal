program PrintPCodes;

	procedure exit(code);
	var
		r : integer;
	begin
		writeln('Exit (', code, ')'); call(0)
	end {exit};

const
	system_error = %100;
	
	function new(length) : integer;
	var
		old_a, new_a : integer;
	begin
		old_a := stacktop(0);
		new_a := stacktop(length);
		if (old_a - new_a) <> length then begin
			writeln('new -- error:', length, 'requested,', old_a - new_a, 'reserved.');
			exit(system_error + 1)
		end;
		new := new_a;
	end {new};
		
const
	CPM_BDOS_OPEN = %0F;
	
	CPM_DFN_LEN = 12;	{CP/M disk + filename + ext length, parsed }
	
	CPM_FCBLEN = %24;	{CP/M file control block (FCB) length }
	CPM_FCB_DISK = 0;
	CPM_FCB_NAME = 1;
	CPM_FCB_TYPE = 9;
	
	
	
	function CPM_makeFCB({memory address of} name) : integer;
	var
		i : integer;
		FCB_a : integer;
	begin
		FCB_a := new(CPM_FCBLEN);
		for i := 0 to CPM_DFN_LEN - 1 do
			mem[FCB_a + i] := mem[name + i];
		for i := CPM_DFN_LEN to CPM_FCBLEN - 1 do	{Null rest of FCB}
			mem[FCB_a + i] := 0;
		CPM_makeFCB := FCB_a
	end {CPM_makeFCB};
	
	function openFile(FCB) : integer;
	begin
		openFile := bdos(CPM_BDOS_OPEN, FCB)
	end {openFile};
	
const
	CPM_RAM = %0000;
	CPM_COMTAIL = %0080;
	CPM_COMTAIL_COUNT = %0080;
	CPM_FCB1 = %005C;
	CPM_FCB2 = %006C;
var
	i : integer;
	PCodeFile : integer;
	bdos_result : integer;
	
	procedure printhexbyte(b);
	var
		d : integer;

		procedure printhexdigit(d);
		begin
			if d<10 then
				write(('0' + d)$)
			else write(('A' + d - 10)$)
		end {printhexdigit};
		
	begin
		printhexdigit((b div 16) mod 16);
		printhexdigit(b mod 16);
		write(' ')
	end {printhexbyte};
		
begin
	for i := 1 to mem[CPM_COMTAIL_COUNT] do
		write(mem[CPM_COMTAIL+i]$);
	writeln;
	
	if mem[CPM_COMTAIL_COUNT] = 0 then begin
		writeln('Missing filename argument'); exit (1)
	end;

	if mem[CPM_FCB1 + 0] > 0 then
		write((mem[CPM_FCB1] - 1 + 'A')$, ':');
	for i := 1 to 8 do
		write(mem[CPM_FCB1 + i]$);
	write('.');
	for i := 1 to 3 do
		write(mem[CPM_FCB1 + 8 + i]$);
	writeln;

	PCodeFile := CPM_makeFCB(CPM_FCB1);
	
	writeln('Open file result:', openFile(PCodeFile));
	for i := 16 to 32 do
		printhexbyte(mem[PCodeFile + i]);
	writeln
end {PrintPCodes}.
