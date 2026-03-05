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
  signal mem_data_i   : std_logic_vector(31 downto 0) := (others => '0');
  signal pc4_i        : std_logic_vector(31 downto 0) := (others => '0');
  signal wb_select_i  : std_logic_vector(1 downto 0) := (others => '0');
  signal wb_data_o    : std_logic_vector(31 downto 0);

  constant c_ZERO32 : std_logic_vector(31 downto 0) := (others => '0');

begin

  uut_wb_mux: entity design_lib.wb_mux
  port map (
    alu_result_i => alu_result_i,
    mem_data_i   => mem_data_i,
    pc4_i        => pc4_i,
    wb_select_i  => wb_select_i,
    wb_data_o    => wb_data_o
  );

  main : process
  begin
    test_runner_setup(runner, runner_cfg);

    while test_suite loop
	    if run("test_b_mux") then

	      alu_result_i <= std_logic_vector(to_signed(100, 32));
        mem_data_i   <= std_logic_vector(to_signed(200, 32));
        pc4_i        <= std_logic_vector(to_signed(300, 32));

        -- "00" -> mem_data_i
        wb_select_i <= "00";
        wait for 1 ns;
        check_equal(wb_data_o, mem_data_i, "wb_select_i=00 must select mem_data_i");

        -- "01" -> alu_result_i
        wb_select_i <= "01";
        wait for 1 ns;
        check_equal(wb_data_o, alu_result_i, "wb_select_i=01 must select alu_result_i");

        -- "10" -> pc4_i
        wb_select_i <= "10";
        wait for 1 ns;
        check_equal(wb_data_o, pc4_i, "wb_select_i=10 must select pc4_i");

        -- "11" -> others => zero
        wb_select_i <= "11";
        wait for 1 ns;
        check_equal(wb_data_o, c_ZERO32, "wb_select_i=11 must drive zeros");

        -- case with negative values
        alu_result_i <= std_logic_vector(to_signed(-1, 32));
        mem_data_i   <= std_logic_vector(to_signed(-2, 32));
        pc4_i        <= std_logic_vector(to_signed(-3, 32));

        wb_select_i <= "01";
        wait for 1 ns;
        check_equal(wb_data_o, alu_result_i, "Negative value selection failed for ALU");


	  end if;
	  end loop;
	
    test_runner_cleanup(runner);
  end process main;
end arch;
