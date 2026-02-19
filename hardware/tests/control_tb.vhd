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
library vunit_lib;
context vunit_lib.vunit_context;
library design_lib;
use design_lib.alu_pkg.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity control_tb is
  generic (runner_cfg : string);
end control_tb;

architecture arch of control_tb is

  -- Signals to connect to UUT
  signal s_opcode           : std_logic_vector(6 downto 0) := (others => '0');
  signal s_funct3           : std_logic_vector(2 downto 0) := (others => '0');
  signal s_funct7           : std_logic_vector(6 downto 0) := (others => '0');
  signal s_reg_write_enable : std_logic;
  signal s_imm_sel          : std_logic_vector(2 downto 0);
  signal s_b_sel            : std_logic;
  signal s_alu_op           : t_alu_op;
  signal s_mem_rw_o         : std_logic;
  signal s_wb_select_o      : std_logic;

begin
  -- Instantiate the Unit Under Test (UUT)
  uut: entity design_lib.control
    port map (
      opcode_i           => s_opcode,
      funct3_i           => s_funct3,
      funct7_i           => s_funct7,
      reg_write_enable_o => s_reg_write_enable,
      imm_sel_o          => s_imm_sel,
      b_sel_o            => s_b_sel,         
      alu_op_o           => s_alu_op,
      mem_rw_o           => s_mem_rw_o,
      wb_select_o        => s_wb_select_o
    );

  -- Stimulus process
  stim_proc: process
  begin
    test_runner_setup(runner, runner_cfg);

    while test_suite loop
      if run("test_add_instr") then
        s_opcode <= "0110011";
        s_funct3 <= (others => '0');
        s_funct7 <= (others => '0');

        wait for 5 ns;
        check_equal(s_reg_write_enable, std_logic'('1'), "ADD should enable register write");
        check_equal(s_b_sel, '0', "ADD should select rs2 (b_sel=0)");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_ADD), "ADD should perform addition");

        s_opcode <= "0010011";
        s_funct3 <= (others => '0');
        s_funct7 <= (others => '0');

        wait for 5 ns;
        check_equal(s_reg_write_enable, std_logic'('1'), "ADDI should enable register write");
        check_equal(s_b_sel, std_logic'('1'), "ADDI should select rs2 (b_sel=1)");
        check_equal(to_integer(unsigned(s_imm_sel)), 1, "ADDI should use I-type immediate selection");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_ADD), "ADDI should perform addition");

        s_opcode <= (others => '0');
        
        wait for 5 ns;
        check_equal(s_reg_write_enable, std_logic'('0'), "Default should disable write");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_NOP), "Default should be NOP");

      elsif run("test_load_store_instr") then
        s_opcode <= "0000011"; -- LW
        s_funct3 <= "010";
        s_funct7 <= (others => '0');

        wait for 5 ns;
        check_equal(s_reg_write_enable, std_logic'('1'), "LOAD should write to register");
        check_equal(s_mem_rw_o, std_logic'('0'), "LOAD should read from memory");
        check_equal(s_wb_select_o, std_logic'('0'), "LOAD should read data from memory");
        check_equal(s_b_sel, std_logic'('1'), "LOAD uses immediate ADD");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_ADD), "Address is calculated using ALU_ADD");

        s_opcode <= "0100011"; -- SW
        s_funct3 <= "010";
        s_funct7 <= (others => '0');

        wait for 5 ns;
        check_equal(s_reg_write_enable, std_logic'('0'), "STORE should read from register");
        check_equal(s_mem_rw_o, std_logic'('1'), "STORE should write to memory");
        check_equal(s_wb_select_o, std_logic'('0'), "STORE should write data to memory");
        check_equal(s_b_sel, std_logic'('1'), "STORE uses immediate ADD");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_ADD), "Address is calculated using ALU_ADD");

        s_opcode <= "1111111"; -- Undefined opcode
        s_funct3 <= "111";
        s_funct7 <= (others => '1');

        wait for 5 ns;
        check_equal(s_reg_write_enable, std_logic'('0'), "Undefined op should have all zeros");
        check_equal(s_mem_rw_o, std_logic'('0'), "Undefined op should have all zeros");
        check_equal(s_wb_select_o, std_logic'('0'), "Undefined op should have all zeros");
        check_equal(s_b_sel, std_logic'('0'), "Undefined op should have all zeros");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_NOP), "When undefined opcode NOP is used");        

      end if;
    end loop;

    test_runner_cleanup(runner);
  end process stim_proc;
end arch;
