entity noheader is
end;

architecture behav of noheader is
begin
  process
  begin
    assert false report "Hello" severity note;
    wait;
  end process;
end behav;
