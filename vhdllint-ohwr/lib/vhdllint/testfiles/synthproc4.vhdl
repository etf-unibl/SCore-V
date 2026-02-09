library ieee;
use ieee.std_logic_1164.all;

entity synthproc4 is
  port (clk : std_logic;
        a, b, c : std_logic;
        q : out std_logic);
end;

architecture behav of synthproc4 is
begin
  process (a, b)
  begin
    q <= (a or b) and c;
  end process;
end behav;
