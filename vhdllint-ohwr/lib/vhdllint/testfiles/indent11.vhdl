entity indent11 is
end;

library ieee;
use ieee.std_logic_1164.all;

architecture behav of indent11 is
  signal s : std_logic register;
    disconnect s : std_logic after 3 ns;
begin
end;
