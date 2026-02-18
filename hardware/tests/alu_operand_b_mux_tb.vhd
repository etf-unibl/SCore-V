-----------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2025
-- https://github.com/etf-unibl/SCore-V/
-----------------------------------------------------------------------------
--
-- unit name:     alu_operand_b_mux_tb
--
-- description:
--
--   This file implements self-checking testbench for ALU B-operand 
--   mux module.
--
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

library vunit_lib;
context vunit_lib.vunit_context;

library design_lib;

entity alu_operand_b_mux_tb is
  generic (runner_cfg : string);
end alu_operand_b_mux_tb;

architecture arch of alu_operand_b_mux_tb is

  signal in0_i : std_logic_vector(31 downto 0) := (others => '0');
  signal in1_i : std_logic_vector(31 downto 0) := (others => '0');
  signal sel_i : std_logic := '0';
  signal out_o : std_logic_vector(31 downto 0);

begin

  uut_alu_operand_b_mux: entity design_lib.alu_operand_b_mux
  port map (
    in0_i => in0_i,
    in1_i => in1_i,
    sel_i => sel_i,
    out_o => out_o
  );

  main : process
  begin
    test_runner_setup(runner, runner_cfg);

    while test_suite loop
	  if run("test_b_mux") then 
	    in0_i <= std_logic_vector(to_signed(100, 32));
        in1_i <= std_logic_vector(to_signed(200, 32));
        sel_i <= '0';

        wait for 5 ns;
        check_equal(to_integer(signed(out_o)), 100, "Failed to select in0_i");

	    in0_i <= std_logic_vector(to_signed(100, 32));
        in1_i <= std_logic_vector(to_signed(200, 32));
        sel_i <= '1';

        wait for 5 ns;
        check_equal(to_integer(signed(out_o)), 200, "Failed to select in1_i");

        in0_i <= x"00000000";
        in1_i <= x"FFFFFFFF";
        sel_i <= '1';

        wait for 5 ns;
        check_equal(to_integer(signed(out_o)), -1, "Failed to select in1_i for FFFFFFFF case");

        in0_i <= std_logic_vector(to_signed(101, 32));
        in1_i <= std_logic_vector(to_signed(102, 32));
        sel_i <= 'U';

        wait for 5 ns;
        check_equal(to_integer(signed(out_o)), 102 , "Failed to select in1_i for sel_i = U case");

	  end if;
	end loop;
	
    test_runner_cleanup(runner);
  end process main;
end arch;
