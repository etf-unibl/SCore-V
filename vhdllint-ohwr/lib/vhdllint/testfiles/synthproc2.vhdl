library ieee;
use ieee.std_logic_1164.all;

entity synthproc2 is
  port (clk : std_logic;
        d : std_logic;
        q : out std_logic);
end;

architecture behav of synthproc2 is
  signal mem : std_logic;
begin
  process
  begin
    wait until rising_edge(clk);
    mem <= d;
  end process;

  q <= mem;
end behav;
