entity complexstmtlayout3 is
end;

architecture behav of complexstmtlayout3 is
begin
  process
    variable a : boolean;
  begin
    if false then
      null;
    elsif a
      or a then
      assert false;
    end if;
  end process;
end behav;
