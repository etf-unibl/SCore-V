entity paren3 is
end;

architecture behav of paren3 is
begin
  process
  begin
    if (true
        or false)
    then
      null;
    end if;
  end process;
end behav;
