library ieee;
use ieee.std_logic_1164.all;
use work.mem_pkg.all;
use ieee.numeric_std.all;

entity fetch_instruction is

  generic (
    ADDR_WIDTH : integer := 2  -- Default to 2 bits
  );
  port
  (
  instruction_count	: in  unsigned(ADDR_WIDTH-1 downto 0);

  instruction_bits   : out t_instruction_rec
  
  );

end fetch_instruction;


architecture arch of fetch_instruction is

begin

	instruction_bits <= IMEM(to_integer(instruction_count));

end arch;
