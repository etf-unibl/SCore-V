
--  This is not an header, as it doesn't start at line 1.

entity noheader2 is
end;

architecture behav of noheader2 is
begin
  process
  begin
    assert false report "Hello" severity note;
    wait;
  end process;
end behav;
