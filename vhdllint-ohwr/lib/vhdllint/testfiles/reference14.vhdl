entity reference14 is
end;

architecture behav of reference14 is
  attribute Attr : natural;
  attribute attr of my_proc : label is 5;
begin
  my_proc: process
  begin
    wait;
  end process;
end behav;
