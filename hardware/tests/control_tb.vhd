-----------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2025
-- https://github.com/etf-unibl/SCore-V/
-----------------------------------------------------------------------------
--
-- unit name:     control_tb
--
-- description:
--
--   This file implements self-checking testbench for control unit
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

entity control_tb is
  generic (runner_cfg : string);
end control_tb;

architecture arch of control_tb is

  -- Signals to connect to UUT
  signal s_opcode           : std_logic_vector(6 downto 0) := (others => '0');
  signal s_funct3           : std_logic_vector(2 downto 0) := (others => '0');
  signal s_funct7           : std_logic_vector(6 downto 0) := (others => '0');
  signal s_reg_write_enable : std_logic;

begin
  -- Instantiate the Unit Under Test (UUT)
  uut: entity design_lib.control
    port map (
      opcode_i           => s_opcode,
      funct3_i           => s_funct3,
      funct7_i           => s_funct7,
      reg_write_enable_o => s_reg_write_enable
    );

  -- Stimulus process
  stim_proc: process
  begin
    test_runner_setup(runner, runner_cfg);

    while test_suite loop
      if run("test_add_instr") then
        info("Testing add instruction");
        s_opcode <= "0110011";
        s_funct3 <= "000";
        s_funct7 <= "0000000";
        
        wait for 10 ns;
        if s_reg_write_enable /= '1' then
          failure("Output should be 1");
        end if;
      end if;
    end loop;

    test_runner_cleanup(runner);
  end process stim_proc;
end arch;
