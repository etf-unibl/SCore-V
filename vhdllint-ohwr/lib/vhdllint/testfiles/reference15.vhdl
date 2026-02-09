entity reference15 is
end;

architecture behav of reference15 is
  attribute Attr : natural;
  attribute Attr of my_proc : label is 5;
begin
  my_proc: process
  begin
    assert my_proc'Attr = 3;
    wait;
  end process;
end behav;
