-- This is a simple hello test.
-- It complies with all predefined rules.

entity hello is
end hello;

architecture behav of hello is
begin
  process
  begin
    assert false report "Hello" & " world" severity note;
    wait;
  end process;
end behav;
