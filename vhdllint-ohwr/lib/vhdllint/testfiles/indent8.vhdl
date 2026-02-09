entity indent8 is
end;

architecture behav of indent8 is
  constant b : bit_vector := x"a5";
  attribute attr : natural;
   attribute attr of b : constant is 5;
begin
end;
