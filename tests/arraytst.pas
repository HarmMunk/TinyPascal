program arraytest;
const
  low=1; up=9;
var
  i, j, k: integer;
  a: array [low..up, low..up, low..up] of integer;
  c, d, e: array [low..up, low..up] of integer;
  
begin
  for i:= low to up do
    for j:= low to up do
      for k:= low to up do
        a[i, j, k]:= 100*i +10*j + k;
  
  writeln('array a[1..9, 1..9, 1..9]');
  for i:= low to up do begin
    for j:= low to up do begin
      for k:= low to up do
        write(a[i, j, k]);
      writeln
    end;
    writeln
  end;
  writeln;

  for i:= low to up do
    for j:= low to up do begin
      c[i, j]:= i*10 + j; d[i, j]:= (up-i+1)*10 + (up-j+1)
    end;

  writeln('array c[1..9, 1..9]');
  for i:= low to up do begin
    for j:= low to up do
      write(c[i,j]);
    writeln
  end;
  writeln;

  writeln('array d[1..9, 1..9]');
  for i:= low to up do begin
    for j:= low to up do
      write(d[i,j]);
    writeln
  end;

  for i:= low to up do 
    for j:= low to up do begin
      e[i, j]:= 0;
      for k:= low to up do
        e[i, j]:= e[i, j] + c[i, k]*d[k, j]
    end;
  writeln;
    
  writeln('array k[1..9, 1..9] = c x d');
  for i:= low to up do begin
    for j:= low to up do
      write(e[i,j]);
    writeln
  end;

end.
