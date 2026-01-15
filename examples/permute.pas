program permute;
const
	lb = '0';
var
	s : array[lb..'9'] of char;
	c, hb : char;

	function nextperm : boolean;
	var
		i, j : integer;
		h : char;
		nf : boolean;
	begin
		i := hb; nf := true;
		while (i>lb) and nf do begin
			i := pred(i);
			nf := s[i] > s[i+1];
		end;
		if not nf then begin
			j := hb;
			while (j>i) and (s[j]<s[i]) do
				j := pred(j);
			h := s[i]; s[i] := s[j]; s[j] := h;
			i := succ(i); j := hb;
			while i<j do begin
				h := s[i]; s[i] := s[j]; s[j] := h;
				i := succ(i); j := pred(j)
			end
		end;		
		nextperm := not nf;
	end {nextperm};

begin {permute}
	writeln('Low bound is ''', lb$, '''');
	write('Enter high bound:');
	read(hb$); writeln;
	writeln('High bound is ''', hb$, '''');
	for c := lb to hb do
		s[c] := c;
	repeat
		for c := lb to hb do
			write((s[c])$);
		writeln
	until not nextperm
end. {permute}
