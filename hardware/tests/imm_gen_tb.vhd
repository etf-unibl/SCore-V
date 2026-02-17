-----------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2025
-- https://github.com/etf-unibl/SCore-V/
-----------------------------------------------------------------------------
--
-- unit name:     imm_gen_tb
--
-- description:
--
--   This file implements self-checking testbench for immediate generator unit
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

entity imm_gen_tb is
  generic (runner_cfg : string);
end imm_gen_tb;

architecture arch of imm_gen_tb is

  signal instruction_bits_i :  std_logic_vector(24 downto 0) := (others => '0'); --! Instruction bits
  signal imm_sel_i          :  std_logic_vector(2 downto 0) := (others => '0');  --! Immediate select
  signal imm_o              :  std_logic_vector(31 downto 0);  --! 32-bit immediate output
  
  constant c_SEL_I_TYPE : std_logic_vector(2 downto 0) := "001";
  constant c_SEL_S_TYPE : std_logic_vector(2 downto 0) := "010";

begin

  uut_imm_gen : entity design_lib.imm_gen
    port map (
	  instruction_bits_i => instruction_bits_i,
	  imm_sel_i          => imm_sel_i,
	  imm_o              => imm_o
    );

  main : process
  begin
    test_runner_setup(runner, runner_cfg);

    while test_suite loop
	  if run("test_imm_gen") then 
	    instruction_bits_i <= (others => '0');
        instruction_bits_i(24 downto 13) <= std_logic_vector(to_signed(100, 12));
        imm_sel_i <= c_SEL_I_TYPE;
        
        wait for 10 ns;
        check_equal(to_integer(signed(imm_o)), 100, "I-Type Positive failed");
		
        instruction_bits_i <= (others => '0');
        instruction_bits_i(24 downto 13) <= std_logic_vector(to_signed(-5, 12));
        imm_sel_i <= c_SEL_I_TYPE;

        wait for 10 ns;
        check_equal(to_integer(signed(imm_o)), -5, "I-Type Negative failed");
		
		    instruction_bits_i <= (others => '0');
        instruction_bits_i(24 downto 18) <= "0111111"; 
        instruction_bits_i(4 downto 0)   <= "11111";  
        imm_sel_i <= c_SEL_S_TYPE;
        
        wait for 10 ns;
        check_equal(to_integer(signed(imm_o)), 2047, "S-positive failed");

        instruction_bits_i(24 downto 18) <= "1111111";
        instruction_bits_i(4 downto 0)   <= "11111";
        imm_sel_i <= c_SEL_S_TYPE;
        wait for 10 ns;
        check_equal(to_integer(signed(imm_o)), -1, "S-Negative failed");
		
		    imm_sel_i <= "000"; 
		
        wait for 10 ns;
        check_equal(to_integer(signed(imm_o)), 0, "Default case should output zero");
		
		end if;
	end loop;
	
    test_runner_cleanup(runner);
  end process main;
end arch;
