PROGRAM ACKERMANN;

VAR
  C : INTEGER;
  A : CHAR;

FUNCTION ACKERMANN(M,N,P: INTEGER):INTEGER;
BEGIN
  C := SUCC(C);
  IF C>1000 THEN BEGIN
    C := 0;
    WRITELN; WRITELN('Continue? '); READ(A$)
  END;
  IF (M<0) OR (N<0) OR (P<0) THEN BEGIN
    WRITELN('All parameters must be >= 0:', M, N, P)
  END
  ELSE BEGIN
    WRITELN('(',M,',',N,',',P,')', 'Basepointer ', MEM[%0103] + MEM[%0104] SHL 8);
    IF P=0 THEN
      ACKERMANN := M+N
    ELSE IF N=0 THEN
      CASE P OF
      1 : ACKERMANN := 0;
      2 : ACKERMANN := 1;
      OTHERWISE
          ACKERMANN := M
      END
    ELSE
      ACKERMANN := ACKERMANN(M, ACKERMANN(M, N-1, P), P-1)
  END
END ACKERMANN;

VAR
  M, N, P, ACK : INTEGER;

BEGIN
  WRITELN('Stacktop ', STACKTOP(0));
  WRITELN('Ackermann(181,2,2) = ', ACKERMANN(181,2,2), '[32761]');
  WRITELN('Ackermann( 31,3,2) = ', ACKERMANN( 31,1,2), '[29791]');
  WRITELN('Ackermann( 13,4,2) = ', ACKERMANN( 13,4,2), '[28561]');
  WRITELN('Ackermann(  7,5,2) = ', ACKERMANN(  7,5,2), '[16807]');
  WRITELN('Ackermann(  5,6,2) = ', ACKERMANN(  5,6,2), '[15625]');

  REPEAT
    WRITE('Enter m, n and p:'); READ(M); READ(N); READ(P); WRITELN;
    C := 0; ACK := ACKERMANN(M,N,P); WRITELN('Ackermann(', M, ',', N, ',', P, ') =', ACK);
    WRITE('Again? '); READ(A$); WRITELN;
  UNTIL (A='N') OR (A='n')
END ACKERMANN.