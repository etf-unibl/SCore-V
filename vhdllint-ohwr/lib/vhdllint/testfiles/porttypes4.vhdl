library ieee;
use ieee.std_logic_1164.all;

package porttypes4_pkg is
  type my_input_t is record
    a : std_logic;
    b : std_logic_vector(1 downto 0);
  end record;
end;

use work.porttypes4_pkg.all;
entity porttypes4 is
  port (a : my_input_t);
end;
