entity keyword2 is
end;

architecture behav of keyword2 is
begin
  process
  begin
    assert false report "Hello" severity note;
    wait;
  end process;
End behav;
