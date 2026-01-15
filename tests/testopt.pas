program testopt;

procedure noparams;
begin
end noparams;

procedure oneparam(i: integer);
begin
end oneparam;

procedure twoparams(i, j: integer);
begin
end twoparams;

procedure threeparams(i, j, k: integer);
begin
end threeparams;

procedure fourparams(i, j, k, l: integer);
begin
end fourparams;

var
  i, j: integer;
  
  ar: array [1..2] of integer;

begin
  noparams;
  oneparam(0);
  twoparams(0, 1);
  threeparams(0, 1, 2);
  fourparams(0, 1, 2, 3);

  j:= 0;
  j := j + 5;
  ar[j] := 0;
  
  j := j + 5;
  repeat
    ar[j] := 0
  until 1;
  
  ar[j] := ar[j] + 5;
  
  j := -10;
  j := -0;
  
  ar[j+2] := 0;
  ar[i-1] := 1;
  i := i + 1;
  
  j := 0;
  
end.