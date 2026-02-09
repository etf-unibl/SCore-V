entity paren2 is
end;

architecture behav of paren2 is
begin
  process
  begin
    if true then
      null;
    end if;
  end process;
end behav;
