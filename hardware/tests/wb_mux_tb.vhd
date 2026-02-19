-----------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2025
-- https://github.com/etf-unibl/SCore-V/
-----------------------------------------------------------------------------
--
-- unit name:     wb_mux_tb
--
-- description:
--
--   This file implements self-checking testbench for write-back mux.
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

entity wb_mux_tb is
  generic (runner_cfg : string);
end wb_mux_tb;

architecture arch of wb_mux_tb is

  signal alu_result_i : std_logic_vector(31 downto 0) := (others => '0');
  signal mem_data_i : std_logic_vector(31 downto 0) := (others => '0');
  signal wb_select_i : std_logic := '0';
  signal wb_data_o : std_logic_vector(31 downto 0);

begin

  uut_wb_mux: entity design_lib.wb_mux
  port map (
    alu_result_i => alu_result_i,
    mem_data_i   => mem_data_i,
    wb_select_i  => wb_select_i,
    wb_data_o    => wb_data_o
  );

  main : process
  begin
    test_runner_setup(runner, runner_cfg);

    while test_suite loop
	    if run("test_b_mux") then 
	      alu_result_i <= std_logic_vector(to_signed(100, 32));
        mem_data_i <= std_logic_vector(to_signed(200, 32));
        wb_select_i <= '0';

        wait for 5 ns;
        check_equal(to_integer(signed(wb_data_o)), 200, "Failed to select mem_data_i");

	      alu_result_i <= std_logic_vector(to_signed(100, 32));
        mem_data_i <= std_logic_vector(to_signed(200, 32));
        wb_select_i <= '1';

        wait for 5 ns;
        check_equal(to_integer(signed(wb_data_o)), 100, "Failed to select alu_result_i");

        alu_result_i <= x"00000000";
        mem_data_i <= x"FFFFFFFF";
        wb_select_i <= '1';

        wait for 5 ns;
        check_equal(to_integer(signed(wb_data_o)), 0, "Failed to select alu_result_i for FFFFFFFF case");

        alu_result_i <= std_logic_vector(to_signed(101, 32));
        mem_data_i <= std_logic_vector(to_signed(102, 32));
        wb_select_i <= 'U';

        wait for 5 ns;
        check_equal(to_integer(signed(wb_data_o)), 101, "Failed to select alu_result_i for wb_select_i = U case");
	  end if;
	  end loop;
	
    test_runner_cleanup(runner);
  end process main;
end arch;
