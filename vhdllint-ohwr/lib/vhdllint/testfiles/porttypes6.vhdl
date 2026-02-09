library ieee;
use ieee.std_logic_1164.all;

package porttypes6_pkg is
  type my_input_a_t is record
    a : std_logic;
    b : std_logic_vector(1 downto 0);
  end record;

  type my_input_t is record
    c : my_input_a_t;
    d : std_logic;
  end record;
end;

use work.porttypes6_pkg.all;
entity porttypes6 is
  port (a : my_input_t);
end;
