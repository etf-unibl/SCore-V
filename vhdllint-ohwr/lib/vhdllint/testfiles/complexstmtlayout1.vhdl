entity complexstmtlayout1 is
end;

architecture behav of complexstmtlayout1 is
begin
  process
    variable a : boolean;
  begin
    if a then
      assert false;
    elsif true then
      null;
    end if;
  end process;
end behav;
