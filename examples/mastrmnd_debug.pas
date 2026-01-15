program mastermind;
var
	hypnr, hypmax, tr, i, ver : integer;
	match, found : boolean;
	ans : integer;
	hyp : array[0..3] of integer;
	row : array[1..10, 0..3] of integer;
	resp : array[1..10, 1..2] of integer;
	
	function abs(n) : integer;
	begin
		if n<0 then
			abs := -n
		else
			abs := n
	end {abs};
	
	procedure clearscreen;
	begin
		write(27$,'[2J')
	end {clearscreen};
	
	procedure space(n);
	var
		i : integer;
	begin
		for i := 1 to n do
			write(' ')
	end {space};
	
	procedure signon;
	begin
		clearscreen;
		space(20); writeln('Mastermind Codebreaker');
		space(20); writeln('======================');
		writeln; writeln
	end {signon};
	
	procedure printpeg(p);
	begin
		case p of
		0 : write('rood   ');
		1 : write('blauw  ');
		2 : write('groen  ');
		3 : write('geel   ');
		4 : write('zwart  ');
		5 : write('wit    ');
		6 : write('''leeg'' ');
		otherwise
			write('foutje:', p)
		end
	end {printpeg};

	procedure printhyp;
	var
		i : integer;
	begin
		write('hyp: ');
		for i := 0 to 3 do
			printpeg(hyp[i]);
		writeln
	end {printhyp};
	
	procedure printrow(r);
	var
		i : integer;
	begin
		for i:= 0 to 3 do 
			printpeg(row[r, i])
	end {printrow};
	
	procedure printrowln(r);
	begin
		printrow(r); writeln
	end {printrowln};
	
	procedure askversion;
	begin
		repeat
			write('Welke versie (6 of 7 kleuren)');
			read(ver); writeln; writeln
		until (ver=6) or (ver=7)
	end {askversion};
	
	procedure askresponse(r);
	var
		wp, bp : integer;
		val : integer;
	begin
		repeat
			repeat
				write('Hoeveel zwarte pionnen ');
				read(bp); writeln
			until (bp>=0) and (bp<=4);
			if bp=4 then
				wp := 0
			else
				repeat
					write('Hoeveel witte pionnen ');
					read(wp); writeln
				until (wp>=0) and (wp<=4);
			val := ((bp+wp)<=4) or ((bp=3) and (wp=0));
			if not val then
				writeln('====> DAT KAN NIET <====')
		until val;
		resp[r, 1] := bp; resp[r, 2] := wp;
		writeln
	end {askresponse};
	
	function matchrow(r) : boolean;
	var
		bp, wp : integer;
		i, j : integer;
		rem : array[0..3] of integer;
		foundone : boolean;
	begin
		bp := 0; wp := 0;
		for i:= 0 to 3 do
			if row[r, i] = hyp[i] then begin
				bp := succ(bp); rem[i] := true
			end
			else
				rem[i] := false;
		for i := 0 to 3 do
			if row[r, i]<>hyp[i] then begin
				j := 0; foundone := false;
				while (j<4) and (not foundone) do begin
					if not rem[j] and (hyp[i]=row[r, j]) and (i<>j) then begin
						wp := succ(wp); rem[j] := true; foundone := true
					end;
					j := j + 1
				end
			end;
		matchrow := (bp=resp[r,1]) and (wp=resp[r,2]);
		write('row[', r, ']: '); printrow(r); writeln(' : bp=', resp[r, 1], '|', bp, '; wp=', resp[r, 2], '|', wp);
	end {matchrow};
	
	procedure nexthyp;
	var
		cy, i, temp : integer;
	begin
		cy := 1;
		for i := 0 to 3 do begin
			temp := hyp[i] + cy;
			cy := temp div ver; hyp[i] := temp mod ver
		end;
		write('nexthyp: '); printhyp;
		hypnr := succ(hypnr)
	end {nexthyp};
	
	function matchhyp(tr) : boolean;
	var
		r : integer;
		match : integer;
	begin
		writeln('********** matchhyp');
		r := 1; match := true;
		while (r<tr) and match do begin
			match := matchrow(r); r := succ(r)
		end;
		matchhyp := match
	end {matchhyp};
	
	procedure firsthyp;
	begin
		hyp[0] := abs(hyp[0]) mod ver; hyp[2] := succ(hyp[0]) mod ver;
		hyp[1] := hyp[0]; hyp[3] := hyp[2];
		writeln('Eerste gok: '); printhyp; writeln
	end {firsthyp};
	
begin {mastermind}
	repeat
		signon; askversion; hypmax := ver*ver*ver*ver;
		firsthyp; tr := 1; hypnr := 0; match := matchhyp(tr);
		repeat
			while (not match) and (hypnr<=hypmax) and (tr<10) do begin
				nexthyp; match := matchhyp(tr)
			end;
			if match then begin
				for i := 0 to 3 do
					row[tr, i] := hyp[i];
				writeln('====> Rij', tr, ':'); printrowln(tr);
				askresponse(tr);
				found := resp[tr, 1] = 4
			end
			else
				found := false;
			if not found then begin
				tr := succ(tr); nexthyp; match := matchhyp(tr)
			end;
			writeln('Found:', found);
			writeln('hypnr>hypmax:', hypnr, '>', hypmax);
			writeln('tr:', tr)
		until found or (hypnr>hypmax) or (tr>10);
		if not found then
			if (tr<=10) and (hypnr>hypmax) then begin
				writeln('Ik kan geen oplossing vinden!');
				writeln('Heeft u misschien een fout gemaakt?')
			end
			else begin
				writeln('Ik geef het op!');
				writeln('U heeft gewonnen.')
			end;
		repeat
			write('Nog een spelletje? ');
			read(ans$); writeln
		until (ans='J') or (ans='j') or (ans='N') or (ans='n')
	until (ans='N') or (ans='n')
end  {mastermind}.
	
