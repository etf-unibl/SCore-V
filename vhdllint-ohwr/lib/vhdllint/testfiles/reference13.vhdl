entity reference13 is
end;

architecture behav of reference13 is
  attribute attr : natural;
  attribute attr of my_proc : label is 5;
begin
  my_proc: process
  begin
    wait;
  end process;
end behav;
