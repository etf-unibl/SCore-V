library ieee;
use ieee.std_logic_1164.all;

entity synthproc1 is
  port (clk : std_logic;
        d : std_logic;
        q : out std_logic);
end synthproc1;

architecture behav of synthproc1 is
  signal mem : std_logic;
begin
  process (clk)
  begin
    if rising_edge(clk) then
      mem <= d;
    end if;
  end process;

  q <= mem;
end behav;
