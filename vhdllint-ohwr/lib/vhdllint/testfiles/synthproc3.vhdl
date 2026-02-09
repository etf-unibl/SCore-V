library ieee;
use ieee.std_logic_1164.all;

entity synthproc3 is
  port (clk : std_logic;
        a, b : std_logic;
        q : out std_logic);
end;

architecture behav of synthproc3 is
begin
  process (a, b)
  begin
    q <= a or b;
  end process;

  --  Allowed.
  assert a /= 'Z';
end behav;
