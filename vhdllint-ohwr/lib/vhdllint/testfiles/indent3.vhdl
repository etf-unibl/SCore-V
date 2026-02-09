--  Incorrect place for case
entity indent3 is
  port (i : natural;
        o : out natural);
end;

architecture behav of indent3 is
begin
  process
  begin
    case i is
      when 0 => o <= 1;
      when 1 | 2 => o <= 3;
      when 3 => o <= 0;
      when 4
         | 5 =>
        o <= 5;
      when others =>
        o <= 4;
    end case;
  end process;
end;
