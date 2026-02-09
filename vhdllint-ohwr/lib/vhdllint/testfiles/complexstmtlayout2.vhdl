entity complexstmtlayout2 is
end;

architecture behav of complexstmtlayout2 is
begin
  process
    variable a : boolean;
  begin
    if a
      or a then
      assert false;
    end if;
  end process;
end behav;
