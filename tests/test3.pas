program test3;
var
  i, j: integer;
  
procedure print(i);
  begin
    write('Output value: '); writeln(i)
  end;

begin
  i := 1; j := 2;
  print(i); print(j); print(i+j)
end.
