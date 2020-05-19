program bdosandstack;
const
	bufferSize = 80;
	
	bufferSizeOffset    = 0;
	bufferFillOffset    = 1;
	bufferContentOffset = 2;
	
var
	buffer : integer;
	bdosResult : integer;
	i : integer;
begin
	writeln('First page for CP/M:', mem[7]%);
	writeln(stacktop(0)%);
	writeln(stacktop(1)%);
	writeln(stacktop(-1)%);
	
	buffer := stacktop(bufferSize + 2);
	mem[buffer + bufferSizeOffset] := bufferSize;
	bdosResult := bdos(10, buffer);
	writeln('buffer is at:', buffer%,
	        ', BDOS call result:', bdosResult,
	        ', Max chars:', mem[buffer + bufferSizeOffset],
	        ', chars entered:', mem[buffer + bufferFillOffset]);
	for i:= 0 to mem[buffer + bufferFillOffset] - 1 do
		write(mem[buffer + bufferContentOffset + i]$);
	writeln;	
end {stack}.
