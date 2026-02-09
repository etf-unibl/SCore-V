library ieee;
use ieee.std_logic_1164.all;

package porttypes5_pkg is
  type my_input_t is record
    bad : std_ulogic;
    b : std_logic_vector(1 downto 0);
  end record;
end;

use work.porttypes5_pkg.all;
entity porttypes5 is
  port (a : my_input_t);
end;
