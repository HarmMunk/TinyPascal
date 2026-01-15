PROGRAM PROBLEEM854;
CONST
  MAX = 25000;
  SUM = 35; MINX = 8999;
VAR
  X : INTEGER;
    
FUNCTION PRIME(X) : INTEGER;
  VAR
    T : INTEGER;
    P : INTEGER;
  BEGIN
    T := 3;
    REPEAT
	    P := (X MOD T) <> 0;
	    T := T + 2;
	UNTIL NOT P OR ((T * T) > X);
	PRIME := P
  END {PRIME};

FUNCTION DIGITSUM(X) : INTEGER;
  VAR
    D : INTEGER;
  BEGIN
    D := 0;
    WHILE X > 0 DO BEGIN
      D := D + X MOD 10; X := X DIV 10
    END;
    DIGITSUM := D
  END {DIGITSUM};
 
 BEGIN
   X := MINX;
   WHILE X < MAX DO BEGIN
     IF PRIME(X) AND (DIGITSUM(X) = SUM) THEN
       WRITELN('Eureka:', 	X);
     X := X + 2;
   END
 END {PROBLEEM854}.  
