entity indent5 is
end;

architecture behav of indent5 is
  constant b : bit_vector := x"a5";
    alias a : bit_vector (3 downto 0) is b (0 to 3);
begin
end;
