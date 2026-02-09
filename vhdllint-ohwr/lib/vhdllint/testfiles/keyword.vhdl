entity keyword is
end;

architecture behav of keyword is
BEGIN
  process
  begin
    assert false report "Hello" severity note;
    wait;
  end process;
end behav;
