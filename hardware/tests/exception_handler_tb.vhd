-----------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2025
-- https://github.com/etf-unibl/SCore-V/
-----------------------------------------------------------------------------
--
-- unit name:     exception_handler_tb
--
-- description:
--
--   This file implements self-checking testbench for exception handling 
--   module.
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

entity exception_handler_tb is
  generic (runner_cfg : string);
end exception_handler_tb;

architecture arch of exception_handler_tb is

constant c_T                  : time      := 10 ns;
signal clk_i                  : std_logic := '0';
signal rst_i                  : std_logic := '0';
signal misaligned_access_i    : std_logic := '0'; 
signal invalid_address_i      : std_logic := '0'; 
signal invalid_instruction_i  : std_logic := '0';
signal halt_processor_o       : std_logic;
  
begin

  uut_exception_handler: entity design_lib.exception_handler
  port map (
  clk_i                  => clk_i,
  rst_i                  => rst_i,
  misaligned_access_i    => misaligned_access_i,
  invalid_address_i      => invalid_address_i,
  invalid_instruction_i  => invalid_instruction_i,
  halt_processor_o       => halt_processor_o
  );
 
  clk_process : process
  begin
    clk_i <= '0';
    wait for c_T/2;
    clk_i <= '1';
    wait for c_T/2;
  end process;

  main : process
  begin
    test_runner_setup(runner, runner_cfg);

    while test_suite loop
	  if run("test_exception_handler") then 
	  
	    misaligned_access_i <= '1';
        wait for c_T;
		check_equal(halt_processor_o, '1', 
		           "MAC: Processor should be in HALT state, but halt_processor_o is still equal to 0!");
	    
		rst_i <= '1';
		wait for c_T;
		check_equal(halt_processor_o, '0', 
		           "MAC: Processor should be activated, but halt_processor_o is still equal to 1!");
				   
	    rst_i <= '0';
		check_equal(halt_processor_o, '0', 
		           "MAC: Processor should be activated, but halt_processor_o is still equal to 1!");
	    
		invalid_address_i <= '1';
        wait for c_T;
		check_equal(halt_processor_o, '1', 
		           "IAC: Processor should be in HALT state, but halt_processor_o is still equal to 0!");
	    
		rst_i <= '1';
		wait for c_T;
		check_equal(halt_processor_o, '0', 
		           "IAC: Processor should be activated, but halt_processor_o is still equal to 1!");
				   
	    rst_i <= '0';
		check_equal(halt_processor_o, '0', 
		           "IAC: Processor should be activated, but halt_processor_o is still equal to 1!");
				   
		invalid_instruction_i <= '1';
        wait for c_T;
		check_equal(halt_processor_o, '1', 
		           "IIC: Processor should be in HALT state, but halt_processor_o is still equal to 0!");
	    
		rst_i <= '1';
		wait for c_T;
		check_equal(halt_processor_o, '0', 
		           "IIC: Processor should be activated, but halt_processor_o is still equal to 1!");
				   
	    rst_i <= '0';
		check_equal(halt_processor_o, '0', 
		           "IIC: Processor should be activated, but halt_processor_o is still equal to 1!");
		
	  end if;
	end loop;
	
    test_runner_cleanup(runner);
  end process main;
end arch;
