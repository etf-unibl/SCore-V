entity complexstmtlayout11 is
end;

architecture behav of complexstmtlayout11 is
  procedure proc is
  begin
    null;
  end proc;
begin
  process
    variable v : natural;
  begin
    case v is
      when 1 =>
        wait for 1 ns;
      when 2 =>
        wait for 2 ns;
      when others =>
        proc;
    end case;
  end process;
end behav;
