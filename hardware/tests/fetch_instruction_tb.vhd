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
library vunit_lib;  
context vunit_lib.vunit_context;
library design_lib;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use design_lib.mem_pkg.all;

--! @brief Top-level entity for the fetch instruction testbench.
--! @details As a testbench, this entity has no ports.
entity fetch_instruction_tb is
  generic (runner_cfg : string);
end fetch_instruction_tb;

--! @brief Architecture implementing the stimulus and verification logic.
architecture arch of fetch_instruction_tb is

  signal test_in  : std_logic_vector(31 downto 0);
  signal test_out : t_instruction_rec;

begin
  --! @brief UUT instantiation and port mapping.
  uut_fetch_instruction : entity design_lib.fetch_instruction
    port map(
    instruction_count_i => test_in,
    instruction_bits_o  => test_out
    );
  
  main : process
    variable full_instruction : std_logic_vector(31 downto 0);
    variable addr_int         : integer;

  begin
    test_runner_setup(runner, runner_cfg);
    
    while test_suite loop
      if run("test_fetch_instruction") then
        for i in 0 to 16 loop
          if i mod 4 = 0 then 
            test_in <= std_logic_vector(to_unsigned(i, 32));
            wait for 100 ns;
          end if;
          addr_int := to_integer(unsigned(test_in));
          full_instruction := c_IMEM(addr_int + 3) &
                        c_IMEM(addr_int + 2) &
                        c_IMEM(addr_int + 1) &
                        c_IMEM(addr_int);
        end loop;
        check_equal(test_out.opcode, full_instruction(6 downto 0), 
                    "Opcode mismatch at index " & integer'image(addr_int));

        check_equal(test_out.other_instruction_bits, full_instruction(31 downto 7), 
                    "Data bits mismatch at index " & integer'image(addr_int));
      end if;
    end loop;

    test_runner_cleanup(runner);
  end process;
end arch;
