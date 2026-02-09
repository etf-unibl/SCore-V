entity unused1 is
  port (a : bit;
        b : out bit);
end;

architecture behav of unused1 is
begin
  --  b is not referenced.
  assert a = '1';
end;
