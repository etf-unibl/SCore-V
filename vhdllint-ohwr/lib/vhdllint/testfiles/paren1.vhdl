entity paren1 is
end;

architecture behav of paren1 is
begin
  process
  begin
    if (true) then
      null;
    end if;
  end process;
end behav;
