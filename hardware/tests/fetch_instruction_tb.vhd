-----------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2025
-- https://github.com/etf-unibl/SCore-V/
-----------------------------------------------------------------------------
--
-- unit name: instruction fetch testbench unit
--
-- description:
--
--   This file implements a simple testbench file for the instruction fetch logic.
--
-----------------------------------------------------------------------------
-- Copyright (c) 2025 Faculty of Electrical Engineering
-----------------------------------------------------------------------------
-- The MIT License
-----------------------------------------------------------------------------
-- Copyright 2025 Faculty of Electrical Engineering
--
-- Permission is hereby granted, free of charge, to any person obtaining a
-- copy of this software and associated documentation files (the "Software"),
-- to deal in the Software without restriction, including without limitation
-- the rights to use, copy, modify, merge, publish, distribute, sublicense,
-- and/or sell copies of the Software, and to permit persons to whom
-- the Software is furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
-- THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
-- ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
-- OTHER DEALINGS IN THE SOFTWARE
-----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.mem_pkg.all;

--! @brief Top-level entity for the fetch instruction testbench.
--! @details As a testbench, this entity has no ports.
entity fetch_instruction_tb is
end fetch_instruction_tb;

--! @brief Architecture implementing the stimulus and verification logic.
architecture arch of fetch_instruction_tb is
  --! Component declaration for the Unit Under Test (UUT)
  component fetch_instruction
    port
    (
        instruction_count_i : in  unsigned(31 downto 0);
        instruction_bits_o  : out t_instruction_rec
    );
  end component;

  signal test_in  : unsigned(31 downto 0);
  signal test_out : t_instruction_rec;

begin
  --! @brief UUT instantiation and port mapping.
  uut : fetch_instruction
    port map(
    instruction_count_i => test_in,
    instruction_bits_o  => test_out
    );

  --! Stimulus process : Cycles through addresses
  process
  begin
    test_in <= to_unsigned(0, 32);
    wait for 200 ns;
    test_in <= to_unsigned(4, 32);
    wait for 200 ns;
    test_in <= to_unsigned(8, 32);
    wait for 200 ns;
    test_in <= to_unsigned(16, 32);
    wait for 200 ns;
    wait;
  end process;

  --! Checker process : Checks the values in the LUT based on the input signal
  process
    variable full_instruction : std_logic_vector(31 downto 0);
  begin
    wait on test_in;
    wait for 100 ns;
    full_instruction := c_IMEM(to_integer(test_in + 3)) &
                         c_IMEM(to_integer(test_in + 2)) &
                         c_IMEM(to_integer(test_in + 1)) &
                         c_IMEM(to_integer(test_in));
    assert (test_out.opcode = full_instruction(6 downto 0))
      report "Opcode mismatch at index " & integer'image(to_integer(test_in))
      severity error;
    assert (test_out.other_instruction_bits = full_instruction(31 downto 7))
      report "Data bits mismatch at index " & integer'image(to_integer(test_in))
      severity error;
  end process;
end arch;
