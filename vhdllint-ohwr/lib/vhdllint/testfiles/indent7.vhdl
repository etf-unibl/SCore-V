entity indent7 is
end;

architecture behav of indent7 is
  constant b : bit_vector := x"a5";
  attribute attr : natural;
  attribute attr of b : constant is 5;
begin
end;
