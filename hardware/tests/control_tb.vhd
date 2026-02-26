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
  signal s_imm_i_type       : std_logic_vector(11 downto 0) := (others => '0');
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
      imm_i_type_i       => s_imm_i_type,
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
      if run("test_arithmetic_instr") then
        -- R-type ADD
        s_opcode     <= "0110011";
        s_funct3     <= "000";
        s_funct7     <= "0000000";
        s_imm_i_type <= (others => '0');
        wait for 5 ns;

        check_equal(s_reg_write_enable, '1', "ADD should enable reg write");
        check_equal(s_b_sel,            '0', "ADD uses rs2");
        check_equal(s_wb_select_o,      '1', "ADD writeback from ALU");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_ADD), "ADD -> ALU_ADD");

        -- R-type SUB
        s_opcode     <= "0110011";
        s_funct3     <= "000";
        s_funct7     <= "0100000";
        wait for 5 ns;

        check_equal(s_reg_write_enable, '1', "SUB should enable reg write");
        check_equal(s_b_sel,            '0', "SUB uses rs2");
        check_equal(s_wb_select_o,      '1', "SUB writeback from ALU");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_SUB), "SUB -> ALU_SUB");

        -- I-type ADDI
        s_opcode     <= "0010011";
        s_funct3     <= "000";
        s_funct7     <= (others => '0');
        s_imm_i_type <= (others => '0');
        wait for 5 ns;

        check_equal(s_reg_write_enable, '1', "ADDI should enable reg write");
        check_equal(s_b_sel,            '1', "ADDI uses immediate");
        check_equal(s_wb_select_o,      '1', "ADDI writeback from ALU");
        check_equal(to_integer(unsigned(s_imm_sel)), 1, "ADDI imm_sel should be I-type (001)");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_ADD), "ADDI -> ALU_ADD");

      elsif run("test_logic_instr") then
        -- R-type SLT
        s_opcode     <= "0110011";
        s_funct3     <= "010";
        s_funct7     <= "0000000";
        wait for 5 ns;

        check_equal(s_reg_write_enable, '1', "SLT should enable reg write");
        check_equal(s_b_sel,            '0', "SLT uses rs2");
        check_equal(s_wb_select_o,      '1', "SLT writeback from ALU");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_SLT), "SLT -> ALU_SLT");

        -- R-type SLTU
        s_opcode     <= "0110011";
        s_funct3     <= "011";
        s_funct7     <= "0000000";
        wait for 5 ns;

        check_equal(s_reg_write_enable, '1', "SLTU should enable reg write");
        check_equal(s_b_sel,            '0', "SLTU uses rs2");
        check_equal(s_wb_select_o,      '1', "SLTU writeback from ALU");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_SLTU), "SLTU -> ALU_SLTU");

        -- R-type AND
        s_opcode     <= "0110011";
        s_funct3     <= "111";
        s_funct7     <= "0000000";
        wait for 5 ns;

        check_equal(s_reg_write_enable, '1', "AND should enable reg write");
        check_equal(s_b_sel,            '0', "AND uses rs2");
        check_equal(s_wb_select_o,      '1', "AND writeback from ALU");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_AND), "AND -> ALU_AND");

        -- R-type OR
        s_opcode     <= "0110011";
        s_funct3     <= "110";
        s_funct7     <= "0000000";
        wait for 5 ns;

        check_equal(s_reg_write_enable, '1', "OR should enable reg write");
        check_equal(s_b_sel,            '0', "OR uses rs2");
        check_equal(s_wb_select_o,      '1', "OR writeback from ALU");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_OR), "OR -> ALU_OR");

        -- R-type XOR
        s_opcode     <= "0110011";
        s_funct3     <= "100";
        s_funct7     <= "0000000";
        wait for 5 ns;

        check_equal(s_reg_write_enable, '1', "XOR should enable reg write");
        check_equal(s_b_sel,            '0', "XOR uses rs2");
        check_equal(s_wb_select_o,      '1', "XOR writeback from ALU");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_XOR), "XOR -> ALU_XOR");

        -- R-type SLL
        s_opcode     <= "0110011";
        s_funct3     <= "001";
        s_funct7     <= "0000000";
        wait for 5 ns;

        check_equal(s_reg_write_enable, '1', "SLL should enable reg write");
        check_equal(s_b_sel,            '0', "SLL uses rs2");
        check_equal(s_wb_select_o,      '1', "SLL writeback from ALU");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_SLL), "SLL -> ALU_SLL");

        -- R-type SRL
        s_opcode     <= "0110011";
        s_funct3     <= "101";
        s_funct7     <= "0000000";
        wait for 5 ns;

        check_equal(s_reg_write_enable, '1', "SRL should enable reg write");
        check_equal(s_b_sel,            '0', "SRL uses rs2");
        check_equal(s_wb_select_o,      '1', "SRL writeback from ALU");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_SRL), "SRL -> ALU_SRL");

        -- R-type SRA
        s_opcode     <= "0110011";
        s_funct3     <= "101";
        s_funct7     <= "0100000";
        wait for 5 ns;

        check_equal(s_reg_write_enable, '1', "SRA should enable reg write");
        check_equal(s_b_sel,            '0', "SRA uses rs2");
        check_equal(s_wb_select_o,      '1', "SRA writeback from ALU");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_SRA), "SRA -> ALU_SRA");

        -- I-type XORI
        s_opcode     <= "0010011";
        s_funct3     <= "100";
        s_funct7     <= (others => '0');
        s_imm_i_type <= x"123";
        wait for 5 ns;

        check_equal(s_reg_write_enable, '1', "XORI should enable reg write");
        check_equal(s_b_sel,            '1', "XORI uses immediate");
        check_equal(s_wb_select_o,      '1', "XORI writeback from ALU");
        check_equal(to_integer(unsigned(s_imm_sel)), 1, "XORI imm_sel should be I-type (001)");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_XOR), "XORI -> ALU_XOR");

        -- I-type ORI
        s_opcode     <= "0010011";
        s_funct3     <= "110";
        s_imm_i_type <= x"7FF";
        wait for 5 ns;

        check_equal(s_reg_write_enable, '1', "ORI should enable reg write");
        check_equal(s_b_sel,            '1', "ORI uses immediate");
        check_equal(s_wb_select_o,      '1', "ORI writeback from ALU");
        check_equal(to_integer(unsigned(s_imm_sel)), 1, "ORI imm_sel should be I-type (001)");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_OR), "ORI -> ALU_OR");

        -- I-type ANDI
        s_opcode     <= "0010011";
        s_funct3     <= "111";
        s_imm_i_type <= x"001";
        wait for 5 ns;

        check_equal(s_reg_write_enable, '1', "ANDI should enable reg write");
        check_equal(s_b_sel,            '1', "ANDI uses immediate");
        check_equal(s_wb_select_o,      '1', "ANDI writeback from ALU");
        check_equal(to_integer(unsigned(s_imm_sel)), 1, "ANDI imm_sel should be I-type (001)");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_AND), "ANDI -> ALU_AND");

        -- I-type SLTI
        s_opcode     <= "0010011";
        s_funct3     <= "010";
        s_imm_i_type <= x"800";
        wait for 5 ns;

        check_equal(s_reg_write_enable, '1', "SLTI should enable reg write");
        check_equal(s_b_sel,            '1', "SLTI uses immediate");
        check_equal(s_wb_select_o,      '1', "SLTI writeback from ALU");
        check_equal(to_integer(unsigned(s_imm_sel)), 1, "SLTI imm_sel should be I-type (001)");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_SLT), "SLTI -> ALU_SLT");

        -- I-type SLTIU
        s_opcode     <= "0010011";
        s_funct3     <= "011";
        s_imm_i_type <= x"555";
        wait for 5 ns;

        check_equal(s_reg_write_enable, '1', "SLTIU should enable reg write");
        check_equal(s_b_sel,            '1', "SLTIU uses immediate");
        check_equal(s_wb_select_o,      '1', "SLTIU writeback from ALU");
        check_equal(to_integer(unsigned(s_imm_sel)), 1, "SLTIU imm_sel should be I-type (001)");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_SLTU), "SLTIU -> ALU_SLTU");
        
        -- I-type SLLI: funct3=001, imm[11:5]=0000000
        s_opcode     <= "0010011";
        s_funct3     <= "001";
        s_funct7     <= (others => '0');
        s_imm_i_type <= "0000000" & "00101";
        wait for 5 ns;

        check_equal(s_reg_write_enable, '1', "SLLI should enable reg write");
        check_equal(s_b_sel,            '1', "SLLI uses immediate");
        check_equal(s_wb_select_o,      '1', "SLLI writeback from ALU");
        check_equal(to_integer(unsigned(s_imm_sel)), 1, "SLLI imm_sel should be I-type (001)");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_SLL), "SLLI -> ALU_SLL");

        -- I-type SRLI: funct3=101, imm[11:5]=0000000
        s_opcode     <= "0010011";
        s_funct3     <= "101";
        s_imm_i_type <= "0000000" & "00011";
        wait for 5 ns;

        check_equal(s_reg_write_enable, '1', "SRLI should enable reg write");
        check_equal(s_b_sel,            '1', "SRLI uses immediate");
        check_equal(s_wb_select_o,      '1', "SRLI writeback from ALU");
        check_equal(to_integer(unsigned(s_imm_sel)), 1, "SRLI imm_sel should be I-type (001)");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_SRL), "SRLI -> ALU_SRL");

        -- I-type SRAI: funct3=101, imm[11:5]=0100000
        s_opcode     <= "0010011";
        s_funct3     <= "101";
        s_imm_i_type <= "0100000" & "00100";
        wait for 5 ns;

        check_equal(s_reg_write_enable, '1', "SRAI should enable reg write");
        check_equal(s_b_sel,            '1', "SRAI uses immediate");
        check_equal(s_wb_select_o,      '1', "SRAI writeback from ALU");
        check_equal(to_integer(unsigned(s_imm_sel)), 1, "SRAI imm_sel should be I-type (001)");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_SRA), "SRAI -> ALU_SRA");

      elsif run("test_load_store_instr") then
        s_opcode <= "0000011"; -- LW
        s_funct3 <= "010";
        s_funct7 <= (others => '0');
        s_imm_i_type <= (others => '0');
        wait for 5 ns;

        check_equal(s_reg_write_enable, std_logic'('1'), "LOAD should write to register");
        check_equal(s_mem_rw_o, std_logic'('0'), "LOAD should read from memory");
        check_equal(s_wb_select_o, std_logic'('0'), "LOAD should read data from memory");
        check_equal(s_b_sel, std_logic'('1'), "LOAD uses immediate ADD");
        check_equal(s_imm_sel, std_logic_vector'("001"), "LOAD imm_sel must be 001");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_ADD), "Address is calculated using ALU_ADD");

        s_opcode <= "0100011"; -- SW
        s_funct3 <= "010";
        s_funct7 <= (others => '0');
        wait for 5 ns;

        check_equal(s_reg_write_enable, std_logic'('0'), "STORE should read from register");
        check_equal(s_mem_rw_o, std_logic'('1'), "STORE should write to memory");
        check_equal(s_b_sel, std_logic'('1'), "STORE uses immediate ADD");
        check_equal(s_imm_sel, std_logic_vector'("010"), "STORE imm_sel must be 010");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_ADD), "Address is calculated using ALU_ADD");
      
      elsif run("test_invalid_encodings") then
        ---------------------------------------------------------------------------
        -- 1) Completely invalid opcode
        ---------------------------------------------------------------------------
        s_opcode     <= "1111111";
        s_funct3     <= "111";
        s_funct7     <= (others => '1');
        s_imm_i_type <= (others => '1');
        wait for 5 ns;

        check_equal(s_reg_write_enable, '0', "Invalid opcode: reg_write must be 0");
        check_equal(s_b_sel,            '0', "Invalid opcode: b_sel must be 0");
        check_equal(s_mem_rw_o,         '0', "Invalid opcode: mem_rw must be 0");
        check_equal(s_wb_select_o,      '0', "Invalid opcode: wb_select must be 0");
        check_equal(to_integer(unsigned(s_imm_sel)), 0, "Invalid opcode: imm_sel must be 000");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_NOP), "Invalid opcode: ALU must be NOP");


        ---------------------------------------------------------------------------
        -- 2) R-type opcode, but illegal funct7 for ADD/SUB group (funct3=000)
        --    Only funct7=0000000 (ADD) and 0100000 (SUB) are allowed.
        ---------------------------------------------------------------------------
        s_opcode     <= "0110011";
        s_funct3     <= "000";
        s_funct7     <= "1111111";   -- illegal
        s_imm_i_type <= (others => '0');
        wait for 5 ns;

        check_equal(s_reg_write_enable, '0', "R-type illegal funct7: must not write");
        check_equal(s_b_sel,            '0', "R-type illegal funct7: b_sel default");
        check_equal(s_wb_select_o,      '0', "R-type illegal funct7: wb_select default");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_NOP), "R-type illegal funct7: ALU_NOP");


        ---------------------------------------------------------------------------
        -- 3) R-type opcode, SRL/SRA group (funct3=101) but illegal funct7
        --    Allowed: 0000000 (SRL), 0100000 (SRA)
        ---------------------------------------------------------------------------
        s_opcode     <= "0110011";
        s_funct3     <= "101";
        s_funct7     <= "0010000";   -- illegal
        wait for 5 ns;

        check_equal(s_reg_write_enable, '0', "R-type shift illegal funct7: must not write");
        check_equal(s_wb_select_o,      '0', "R-type shift illegal funct7: wb_select default");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_NOP), "R-type shift illegal funct7: ALU_NOP");


        ---------------------------------------------------------------------------
        -- 4) I-type opcode, SLLI (funct3=001) but imm[11:5] not 0000000 => invalid
        ---------------------------------------------------------------------------
        s_opcode     <= "0010011";
        s_funct3     <= "001";
        s_funct7     <= (others => '0'); -- funct7 not used for I-type in this design
        s_imm_i_type <= "0100000" & "00001"; -- illegal for SLLI
        wait for 5 ns;

        check_equal(s_reg_write_enable, '0', "SLLI illegal imm[11:5]: must not write");
        check_equal(s_b_sel,            '0', "SLLI illegal imm[11:5]: b_sel default");
        check_equal(s_wb_select_o,      '0', "SLLI illegal imm[11:5]: wb_select default");
        check_equal(to_integer(unsigned(s_imm_sel)), 0, "SLLI illegal imm[11:5]: imm_sel default");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_NOP), "SLLI illegal imm[11:5]: ALU_NOP");


        ---------------------------------------------------------------------------
        -- 5) I-type opcode, SRLI/SRAI (funct3=101) but imm[11:5] is neither
        --    0000000 nor 0100000 => invalid
        ---------------------------------------------------------------------------
        s_opcode     <= "0010011";
        s_funct3     <= "101";
        s_imm_i_type <= "1111111" & "00010"; -- illegal for SRLI/SRAI
        wait for 5 ns;

        check_equal(s_reg_write_enable, '0', "SRLI/SRAI illegal imm[11:5]: must not write");
        check_equal(s_b_sel,            '0', "SRLI/SRAI illegal imm[11:5]: b_sel default");
        check_equal(s_wb_select_o,      '0', "SRLI/SRAI illegal imm[11:5]: wb_select default");
        check_equal(to_integer(unsigned(s_imm_sel)), 0, "SRLI/SRAI illegal imm[11:5]: imm_sel default");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_NOP), "SRLI/SRAI illegal imm[11:5]: ALU_NOP");

        ---------------------------------------------------------------------------
        -- 6) LOAD opcode but unsupported funct3
        --    Supported funct3 for LOAD: 000(LB),001(LH),010(LW),100(LBU),101(LHU)
        ---------------------------------------------------------------------------
        s_opcode     <= "0000011";
        s_funct7     <= (others => '0');
        s_imm_i_type <= (others => '0');

        -- Example unsupported funct3 = 011
        s_funct3 <= "011";
        wait for 5 ns;

        check_equal(s_reg_write_enable, '0', "LOAD with unsupported funct3 must not write regfile");
        check_equal(s_mem_rw_o,         '0', "LOAD with unsupported funct3 must not write memory");
        check_equal(s_b_sel,            '0', "LOAD with unsupported funct3: b_sel default");
        check_equal(to_integer(unsigned(s_imm_sel)), 0, "LOAD with unsupported funct3: imm_sel default");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_NOP), "LOAD with unsupported funct3: ALU_NOP");

        ---------------------------------------------------------------------------
        -- 7) STORE opcode but unsupported funct3
        --    Supported funct3 for STORE: 000(SB),001(SH),010(SW)
        ---------------------------------------------------------------------------
        s_opcode     <= "0100011";
        s_funct7     <= (others => '0');
        s_imm_i_type <= (others => '0');

        -- Example unsupported funct3 = 100
        s_funct3 <= "100";
        wait for 5 ns;

        check_equal(s_reg_write_enable, '0', "STORE with unsupported funct3 must not write regfile");
        check_equal(s_mem_rw_o,         '0', "STORE with unsupported funct3 must not write memory");
        check_equal(s_b_sel,            '0', "STORE with unsupported funct3: b_sel default");
        check_equal(to_integer(unsigned(s_imm_sel)), 0, "STORE with unsupported funct3: imm_sel default");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_NOP), "STORE with unsupported funct3: ALU_NOP");
      end if;
    end loop;

    test_runner_cleanup(runner);
  end process stim_proc;
end arch;
