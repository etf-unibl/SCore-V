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
  signal s_wb_select_o      : std_logic_vector(1 downto 0);
  signal s_mem_size_o       : std_logic_vector(1 downto 0);
  signal s_mem_unsigned_o   : std_logic;
  signal s_br_eq            : std_logic := '0';
  signal s_br_lt            : std_logic := '0';
  signal s_a_sel            : std_logic;
  signal s_pc_sel           : std_logic;
  signal s_br_un            : std_logic;
  signal s_halt_i           : std_logic := '0';
  signal s_invalid_instr    : std_logic;

begin
  -- Instantiate the Unit Under Test (UUT)
  uut : entity design_lib.control
    port map (
      opcode_i           => s_opcode,
      funct3_i           => s_funct3,
      funct7_i           => s_funct7,
      imm_i_type_i       => s_imm_i_type,
      br_eq_i            => s_br_eq,
      br_lt_i            => s_br_lt,
      reg_write_enable_o => s_reg_write_enable,
      imm_sel_o          => s_imm_sel,
      b_sel_o            => s_b_sel,
      a_sel_o            => s_a_sel,
      alu_op_o           => s_alu_op,
      mem_rw_o           => s_mem_rw_o,
      mem_size_o         => s_mem_size_o,
      mem_unsigned_o     => s_mem_unsigned_o,
      wb_select_o        => s_wb_select_o,
      pc_sel_o           => s_pc_sel,
      br_un_o            => s_br_un,
      halt_i          => s_halt_i,
      invalid_instr_o => s_invalid_instr
    );

  -- Stimulus process
  stim_proc : process
  begin
    test_runner_setup(runner, runner_cfg);

    while test_suite loop
      if run("test_arithmetic_instr") then
        s_halt_i <= '0';
        -- R-type ADD
        s_opcode     <= "0110011";
        s_funct3     <= "000";
        s_funct7     <= "0000000";
        s_imm_i_type <= (others => '0');
        wait for 5 ns;

        check_equal(s_reg_write_enable, '1', "ADD should enable reg write");
        check_equal(s_b_sel,            '0', "ADD uses rs2");
        check_equal(to_integer(unsigned(s_wb_select_o)), 1, "ADD writeback from ALU");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_ADD), "ADD -> ALU_ADD");
        check_equal(s_invalid_instr,    '0', "ADD must be valid");

        -- R-type SUB
        s_opcode     <= "0110011";
        s_funct3     <= "000";
        s_funct7     <= "0100000";
        wait for 5 ns;

        check_equal(s_reg_write_enable, '1', "SUB should enable reg write");
        check_equal(s_b_sel,            '0', "SUB uses rs2");
        check_equal(to_integer(unsigned(s_wb_select_o)), 1, "SUB writeback from ALU");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_SUB), "SUB -> ALU_SUB");
        check_equal(s_invalid_instr,    '0', "SUB must be valid");

        -- I-type ADDI
        s_opcode     <= "0010011";
        s_funct3     <= "000";
        s_funct7     <= (others => '0');
        s_imm_i_type <= (others => '0');
        wait for 5 ns;

        check_equal(s_reg_write_enable, '1', "ADDI should enable reg write");
        check_equal(s_b_sel,            '1', "ADDI uses immediate");
        check_equal(to_integer(unsigned(s_wb_select_o)), 1, "ADDI writeback from ALU");
        check_equal(to_integer(unsigned(s_imm_sel)), 1, "ADDI imm_sel should be I-type (001)");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_ADD), "ADDI -> ALU_ADD");
        check_equal(s_invalid_instr,    '0', "ADDI must be valid");

      elsif run("test_logic_instr") then
         s_halt_i <= '0';
        -- R-type SLT
        s_opcode     <= "0110011";
        s_funct3     <= "010";
        s_funct7     <= "0000000";
        wait for 5 ns;

        check_equal(s_reg_write_enable, '1', "SLT should enable reg write");
        check_equal(s_b_sel,            '0', "SLT uses rs2");
        check_equal(to_integer(unsigned(s_wb_select_o)), 1, "SLT writeback from ALU");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_SLT), "SLT -> ALU_SLT");
        check_equal(s_invalid_instr,    '0', "SLT must be valid");

        -- R-type SLTU
        s_opcode     <= "0110011";
        s_funct3     <= "011";
        s_funct7     <= "0000000";
        wait for 5 ns;

        check_equal(s_reg_write_enable, '1', "SLTU should enable reg write");
        check_equal(s_b_sel,            '0', "SLTU uses rs2");
        check_equal(to_integer(unsigned(s_wb_select_o)), 1, "SLTU writeback from ALU");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_SLTU), "SLTU -> ALU_SLTU");
        check_equal(s_invalid_instr,    '0', "SLTU must be valid");

        -- R-type AND
        s_opcode     <= "0110011";
        s_funct3     <= "111";
        s_funct7     <= "0000000";
        wait for 5 ns;

        check_equal(s_reg_write_enable, '1', "AND should enable reg write");
        check_equal(s_b_sel,            '0', "AND uses rs2");
        check_equal(to_integer(unsigned(s_wb_select_o)), 1, "AND writeback from ALU");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_AND), "AND -> ALU_AND");
        check_equal(s_invalid_instr,    '0', "AND must be valid");

        -- R-type OR
        s_opcode     <= "0110011";
        s_funct3     <= "110";
        s_funct7     <= "0000000";
        wait for 5 ns;

        check_equal(s_reg_write_enable, '1', "OR should enable reg write");
        check_equal(s_b_sel,            '0', "OR uses rs2");
        check_equal(to_integer(unsigned(s_wb_select_o)), 1, "OR writeback from ALU");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_OR), "OR -> ALU_OR");
        check_equal(s_invalid_instr,    '0', "OR must be valid");

        -- R-type XOR
        s_opcode     <= "0110011";
        s_funct3     <= "100";
        s_funct7     <= "0000000";
        wait for 5 ns;

        check_equal(s_reg_write_enable, '1', "XOR should enable reg write");
        check_equal(s_b_sel,            '0', "XOR uses rs2");
        check_equal(to_integer(unsigned(s_wb_select_o)), 1, "XOR writeback from ALU");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_XOR), "XOR -> ALU_XOR");
        check_equal(s_invalid_instr,    '0', "XOR must be valid");

        -- R-type SLL
        s_opcode     <= "0110011";
        s_funct3     <= "001";
        s_funct7     <= "0000000";
        wait for 5 ns;

        check_equal(s_reg_write_enable, '1', "SLL should enable reg write");
        check_equal(s_b_sel,            '0', "SLL uses rs2");
        check_equal(to_integer(unsigned(s_wb_select_o)), 1, "SLL writeback from ALU");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_SLL), "SLL -> ALU_SLL");
        check_equal(s_invalid_instr,    '0', "SLL must be valid");

        -- R-type SRL
        s_opcode     <= "0110011";
        s_funct3     <= "101";
        s_funct7     <= "0000000";
        wait for 5 ns;

        check_equal(s_reg_write_enable, '1', "SRL should enable reg write");
        check_equal(s_b_sel,            '0', "SRL uses rs2");
        check_equal(to_integer(unsigned(s_wb_select_o)), 1, "SRL writeback from ALU");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_SRL), "SRL -> ALU_SRL");
        check_equal(s_invalid_instr,    '0', "SRL must be valid");

        -- R-type SRA
        s_opcode     <= "0110011";
        s_funct3     <= "101";
        s_funct7     <= "0100000";
        wait for 5 ns;

        check_equal(s_reg_write_enable, '1', "SRA should enable reg write");
        check_equal(s_b_sel,            '0', "SRA uses rs2");
        check_equal(to_integer(unsigned(s_wb_select_o)), 1, "SRA writeback from ALU");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_SRA), "SRA -> ALU_SRA");
        check_equal(s_invalid_instr,    '0', "SRA must be valid");

        -- I-type XORI
        s_opcode     <= "0010011";
        s_funct3     <= "100";
        s_funct7     <= (others => '0');
        s_imm_i_type <= x"123";
        wait for 5 ns;

        check_equal(s_reg_write_enable, '1', "XORI should enable reg write");
        check_equal(s_b_sel,            '1', "XORI uses immediate");
        check_equal(to_integer(unsigned(s_wb_select_o)), 1, "XORI writeback from ALU");
        check_equal(to_integer(unsigned(s_imm_sel)), 1, "XORI imm_sel should be I-type (001)");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_XOR), "XORI -> ALU_XOR");
        check_equal(s_invalid_instr,    '0', "XORI must be valid");

        -- I-type ORI
        s_opcode     <= "0010011";
        s_funct3     <= "110";
        s_imm_i_type <= x"7FF";
        wait for 5 ns;

        check_equal(s_reg_write_enable, '1', "ORI should enable reg write");
        check_equal(s_b_sel,            '1', "ORI uses immediate");
        check_equal(to_integer(unsigned(s_wb_select_o)), 1, "ORI writeback from ALU");
        check_equal(to_integer(unsigned(s_imm_sel)), 1, "ORI imm_sel should be I-type (001)");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_OR), "ORI -> ALU_OR");
        check_equal(s_invalid_instr,    '0', "ORI must be valid");

        -- I-type ANDI
        s_opcode     <= "0010011";
        s_funct3     <= "111";
        s_imm_i_type <= x"001";
        wait for 5 ns;

        check_equal(s_reg_write_enable, '1', "ANDI should enable reg write");
        check_equal(s_b_sel,            '1', "ANDI uses immediate");
        check_equal(to_integer(unsigned(s_wb_select_o)), 1, "ANDI writeback from ALU");
        check_equal(to_integer(unsigned(s_imm_sel)), 1, "ANDI imm_sel should be I-type (001)");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_AND), "ANDI -> ALU_AND");
        check_equal(s_invalid_instr,    '0', "ANDI must be valid");

        -- I-type SLTI
        s_opcode     <= "0010011";
        s_funct3     <= "010";
        s_imm_i_type <= x"800";
        wait for 5 ns;

        check_equal(s_reg_write_enable, '1', "SLTI should enable reg write");
        check_equal(s_b_sel,            '1', "SLTI uses immediate");
        check_equal(to_integer(unsigned(s_wb_select_o)), 1, "SLTI writeback from ALU");
        check_equal(to_integer(unsigned(s_imm_sel)), 1, "SLTI imm_sel should be I-type (001)");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_SLT), "SLTI -> ALU_SLT");
        check_equal(s_invalid_instr,    '0', "SLTI must be valid");

        -- I-type SLTIU
        s_opcode     <= "0010011";
        s_funct3     <= "011";
        s_imm_i_type <= x"555";
        wait for 5 ns;

        check_equal(s_reg_write_enable, '1', "SLTIU should enable reg write");
        check_equal(s_b_sel,            '1', "SLTIU uses immediate");
        check_equal(to_integer(unsigned(s_wb_select_o)), 1, "SLTIU writeback from ALU");
        check_equal(to_integer(unsigned(s_imm_sel)), 1, "SLTIU imm_sel should be I-type (001)");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_SLTU), "SLTIU -> ALU_SLTU");
        check_equal(s_invalid_instr,    '0', "SLTIU must be valid");

        -- I-type SLLI: funct3=001, imm[11:5]=0000000
        s_opcode     <= "0010011";
        s_funct3     <= "001";
        s_funct7     <= (others => '0');
        s_imm_i_type <= "0000000" & "00101";
        wait for 5 ns;

        check_equal(s_reg_write_enable, '1', "SLLI should enable reg write");
        check_equal(s_b_sel,            '1', "SLLI uses immediate");
        check_equal(to_integer(unsigned(s_wb_select_o)), 1, "SLLI writeback from ALU");
        check_equal(to_integer(unsigned(s_imm_sel)), 1, "SLLI imm_sel should be I-type (001)");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_SLL), "SLLI -> ALU_SLL");
        check_equal(s_invalid_instr,    '0', "SLLI must be valid");

        -- I-type SRLI: funct3=101, imm[11:5]=0000000
        s_opcode     <= "0010011";
        s_funct3     <= "101";
        s_imm_i_type <= "0000000" & "00011";
        wait for 5 ns;

        check_equal(s_reg_write_enable, '1', "SRLI should enable reg write");
        check_equal(s_b_sel,            '1', "SRLI uses immediate");
        check_equal(to_integer(unsigned(s_wb_select_o)), 1, "SRLI writeback from ALU");
        check_equal(to_integer(unsigned(s_imm_sel)), 1, "SRLI imm_sel should be I-type (001)");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_SRL), "SRLI -> ALU_SRL");
        check_equal(s_invalid_instr,    '0', "SLRI must be valid");

        -- I-type SRAI: funct3=101, imm[11:5]=0100000
        s_opcode     <= "0010011";
        s_funct3     <= "101";
        s_imm_i_type <= "0100000" & "00100";
        wait for 5 ns;

        check_equal(s_reg_write_enable, '1', "SRAI should enable reg write");
        check_equal(s_b_sel,            '1', "SRAI uses immediate");
        check_equal(to_integer(unsigned(s_wb_select_o)), 1, "SRAI writeback from ALU");
        check_equal(to_integer(unsigned(s_imm_sel)), 1, "SRAI imm_sel should be I-type (001)");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_SRA), "SRAI -> ALU_SRA");
        check_equal(s_invalid_instr,    '0', "SRAI must be valid");

      elsif run("test_load_store_instr") then

        s_halt_i <= '0';

        -----------------------------------------------------------------------
        -- LOADS: LB, LH, LW, LBU, LHU  (opcode = 0000011)
        -- Expected:
        --  imm_sel = 001, b_sel=1, alu_op=ADD, wb_select=0, mem_rw=0
        --  reg_write_enable=1
        --  mem_size = funct3(1 downto 0)
        --    00 byte
        --    01 half
        --    10 word
        --  mem_unsigned = funct3(2)   (1 for LBU/LHU)
        -----------------------------------------------------------------------
        s_opcode     <= "0000011";
        s_funct7     <= (others => '0');
        s_imm_i_type <= (others => '0');

        -- LB (funct3=000)
        s_funct3 <= "000";
        wait for 5 ns;
        check_equal(s_reg_write_enable, '1', "LB should write rd");
        check_equal(s_mem_rw_o,         '0', "LB should read memory");
        check_equal(to_integer(unsigned(s_wb_select_o)), 0, "LB wb from memory");
        check_equal(s_b_sel,            '1', "LB uses immediate");
        check_equal(s_imm_sel, std_logic_vector'("001"), "LOAD imm_sel must be 001");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_ADD), "LB addr via ADD");
        check_equal(s_mem_size_o, std_logic_vector'("00"), "LB mem_size byte");
        check_equal(s_mem_unsigned_o,   '0',  "LB signed");
        check_equal(s_invalid_instr,    '0', "LB must be valid");

        -- LH (funct3=001)
        s_funct3 <= "001";
        wait for 5 ns;
        check_equal(s_reg_write_enable, '1', "LH should write rd");
        check_equal(s_mem_rw_o,         '0', "LH should read memory");
        check_equal(to_integer(unsigned(s_wb_select_o)), 0, "LH wb from memory");
        check_equal(s_b_sel,            '1', "LH uses immediate");
        check_equal(s_imm_sel, std_logic_vector'("001"), "LOAD imm_sel must be 001");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_ADD), "LH addr via ADD");
        check_equal(s_mem_size_o, std_logic_vector'("01"), "LH mem_size half");
        check_equal(s_mem_unsigned_o,   '0',  "LH signed");
        check_equal(s_invalid_instr,    '0', "LH must be valid");

        -- LW (funct3=010)
        s_funct3 <= "010";
        wait for 5 ns;
        check_equal(s_reg_write_enable, '1', "LW should write rd");
        check_equal(s_mem_rw_o,         '0', "LW should read memory");
        check_equal(to_integer(unsigned(s_wb_select_o)), 0, "LW wb from memory");
        check_equal(s_b_sel,            '1', "LW uses immediate");
        check_equal(s_imm_sel, std_logic_vector'("001"), "LOAD imm_sel must be 001");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_ADD), "LW addr via ADD");
        check_equal(s_mem_size_o, std_logic_vector'("10"), "LW mem_size word");
        check_equal(s_mem_unsigned_o,   '0',  "LW signed");
        check_equal(s_invalid_instr,    '0', "LW must be valid");

        -- LBU (funct3=100)
        s_funct3 <= "100";
        wait for 5 ns;
        check_equal(s_reg_write_enable, '1', "LBU should write rd");
        check_equal(s_mem_rw_o,         '0', "LBU should read memory");
        check_equal(to_integer(unsigned(s_wb_select_o)), 0, "LBU wb from memory");
        check_equal(s_b_sel,            '1', "LBU uses immediate");
        check_equal(s_imm_sel, std_logic_vector'("001"), "LOAD imm_sel must be 001");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_ADD), "LBU addr via ADD");
        check_equal(s_mem_size_o, std_logic_vector'("00"), "LBU mem_size byte");
        check_equal(s_mem_unsigned_o,   '1',  "LBU unsigned");
        check_equal(s_invalid_instr,    '0', "LBU must be valid");

        -- LHU (funct3=101)
        s_funct3 <= "101";
        wait for 5 ns;
        check_equal(s_reg_write_enable, '1', "LHU should write rd");
        check_equal(s_mem_rw_o,         '0', "LHU should read memory");
        check_equal(to_integer(unsigned(s_wb_select_o)), 0, "LHU wb from memory");
        check_equal(s_b_sel,            '1', "LHU uses immediate");
        check_equal(s_imm_sel, std_logic_vector'("001"), "LOAD imm_sel must be 001");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_ADD), "LHU addr via ADD");
        check_equal(s_mem_size_o, std_logic_vector'("01"), "LHU mem_size half");
        check_equal(s_mem_unsigned_o,   '1',  "LHU unsigned");
        check_equal(s_invalid_instr,    '0', "LHU must be valid");

        -----------------------------------------------------------------------
        -- STORES: SB, SH, SW (opcode = 0100011)
        -- Expected:
        --  imm_sel = 010, b_sel=1, alu_op=ADD, mem_rw=1
        --  reg_write_enable=0, wb_select stays default (0)
        --  mem_size = funct3(1 downto 0)
        --  mem_unsigned should remain default '0' (not used for store)
        -----------------------------------------------------------------------
        s_opcode     <= "0100011";
        s_funct7     <= (others => '0');
        s_imm_i_type <= (others => '0');

        -- SB (funct3=000)
        s_funct3 <= "000";
        wait for 5 ns;
        check_equal(s_reg_write_enable, '0', "SB must not write rd");
        check_equal(s_mem_rw_o,         '1', "SB must write memory");
        check_equal(s_b_sel,            '1', "SB uses immediate");
        check_equal(s_imm_sel, std_logic_vector'("010"), "LOAD imm_sel must be 010");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_ADD), "SB addr via ADD");
        check_equal(s_mem_size_o, std_logic_vector'("00"), "SB mem_size byte");
        check_equal(s_mem_unsigned_o,   '0',  "SB unsigned flag unused -> default 0");
        check_equal(s_invalid_instr,    '0', "SB must be valid");

        -- SH (funct3=001)
        s_funct3 <= "001";
        wait for 5 ns;
        check_equal(s_reg_write_enable, '0', "SH must not write rd");
        check_equal(s_mem_rw_o,         '1', "SH must write memory");
        check_equal(s_b_sel,            '1', "SH uses immediate");
        check_equal(s_imm_sel, std_logic_vector'("010"), "LOAD imm_sel must be 010");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_ADD), "SH addr via ADD");
        check_equal(s_mem_size_o, std_logic_vector'("01"), "SH mem_size half");
        check_equal(s_mem_unsigned_o,   '0',  "SH unsigned flag unused -> default 0");
        check_equal(s_invalid_instr,    '0', "SH must be valid");

        -- SW (funct3=010)
        s_funct3 <= "010";
        wait for 5 ns;
        check_equal(s_reg_write_enable, '0', "SW must not write rd");
        check_equal(s_mem_rw_o,         '1', "SW must write memory");
        check_equal(s_b_sel,            '1', "SW uses immediate");
        check_equal(s_imm_sel, std_logic_vector'("010"), "LOAD imm_sel must be 010");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_ADD), "SW addr via ADD");
        check_equal(s_mem_size_o, std_logic_vector'("10"), "SW mem_size word");
        check_equal(s_mem_unsigned_o,   '0',  "SW unsigned flag unused -> default 0");
        check_equal(s_invalid_instr,    '0', "SB must be valid");

      elsif run("test_invalid_encodings") then

        s_halt_i <= '0';

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
        check_equal(to_integer(unsigned(s_wb_select_o)), 0, "Invalid opcode: wb_select must be 0");
        check_equal(to_integer(unsigned(s_imm_sel)), 0, "Invalid opcode: imm_sel must be 000");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_NOP), "Invalid opcode: ALU must be NOP");
        check_equal(s_invalid_instr,    '1', "Invalid opcode must assert invalid_instr_o");


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
        check_equal(to_integer(unsigned(s_wb_select_o)), 0, "R-type illegal funct7: wb_select default");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_NOP), "R-type illegal funct7: ALU_NOP");
        check_equal(s_invalid_instr,    '1', "R-type illegal funct7 must assert invalid_instr_o");


        ---------------------------------------------------------------------------
        -- 3) R-type opcode, SRL/SRA group (funct3=101) but illegal funct7
        --    Allowed: 0000000 (SRL), 0100000 (SRA)
        ---------------------------------------------------------------------------
        s_opcode     <= "0110011";
        s_funct3     <= "101";
        s_funct7     <= "0010000";   -- illegal
        wait for 5 ns;

        check_equal(s_reg_write_enable, '0', "R-type shift illegal funct7: must not write");
        check_equal(to_integer(unsigned(s_wb_select_o)), 0, "R-type shift illegal funct7: wb_select default");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_NOP), "R-type shift illegal funct7: ALU_NOP");
        check_equal(s_invalid_instr,    '1', "R-type shift illegal funct7 must assert invalid_instr_o");


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
        check_equal(to_integer(unsigned(s_wb_select_o)), 0, "SLLI illegal imm[11:5]: wb_select default");
        check_equal(to_integer(unsigned(s_imm_sel)), 0, "SLLI illegal imm[11:5]: imm_sel default");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_NOP), "SLLI illegal imm[11:5]: ALU_NOP");
        check_equal(s_invalid_instr,    '1', "Illegal SLLI must assert invalid_instr_o");


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
        check_equal(to_integer(unsigned(s_wb_select_o)), 0, "SRLI/SRAI illegal imm[11:5]: wb_select default");
        check_equal(to_integer(unsigned(s_imm_sel)), 0, "SRLI/SRAI illegal imm[11:5]: imm_sel default");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_NOP), "SRLI/SRAI illegal imm[11:5]: ALU_NOP");
        check_equal(s_invalid_instr,    '1', "Illegal SRLI/SRAI must assert invalid_instr_o");

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
        check_equal(s_invalid_instr,    '1', "Unsupported LOAD funct3 must assert invalid_instr_o");

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
        check_equal(s_invalid_instr,    '1', "Unsupported STORE funct3 must assert invalid_instr_o");

        ---------------------------------------------------------------------------
        -- 8) JALR opcode (1100111) but unsupported funct3 (must be 000)
        ---------------------------------------------------------------------------
        s_opcode <= "1100111";
        s_funct3 <= "010";
        s_imm_i_type <= (others => '0');
        wait for 5 ns;
        check_equal(s_reg_write_enable, '0', "JALR unsupported funct3: must not write");
        check_equal(to_integer(unsigned(s_wb_select_o)), 0, "JALR unsupported funct3: wb_select default");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_NOP), "JALR unsupported funct3: ALU_NOP");
        check_equal(s_invalid_instr,    '1', "Unsupported JALR funct3 must assert invalid_instr_o");

        ---------------------------------------------------------------------------
        -- 9) Reserved opcode similar to U-type (e.g., 1010111)
        ---------------------------------------------------------------------------
        s_opcode <= "1010111";
        s_imm_i_type <= (others => '1');
        wait for 5 ns;
        check_equal(s_reg_write_enable, '0', "Reserved U-like opcode: must not write");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_NOP), "Reserved U-like opcode: ALU_NOP");
        check_equal(s_invalid_instr,    '1', "Reserved opcode must assert invalid_instr_o");
        ---------------------------------------------------------------------------
        -- 10) Reserved opcode similar to J-type (e.g., 1101011)
        ---------------------------------------------------------------------------
        s_opcode <= "1101011";
        wait for 5 ns;
        check_equal(s_reg_write_enable, '0', "Reserved J-like opcode: must not write");
        check_equal(to_integer(unsigned(s_imm_sel)), 0, "Reserved J-like: imm_sel default");
        check_equal(s_invalid_instr,    '1', "Reserved opcode must assert invalid_instr_o");

      elsif run("test_branch_instr") then

        s_halt_i <= '0';

        ---------------------------------------------------------------------------
        -- BRANCH Instructions: BEQ, BNE, BLT, BGE, BLTU, BGEU (opcode = 1100011)
        -- Expected default B-type signals:
        -- imm_sel = 011, b_sel = 1, a_sel = 1, alu_op = ADD, reg_write_enable = 0
        ---------------------------------------------------------------------------

        s_opcode <= "1100011";
        s_imm_i_type <= (others => '0');

        -- BEQ (funct3 = 000): Branch if rs1 == rs2
        s_funct3 <= "000";
        s_br_eq  <= '1'; -- Simulate rs1 == rs2
        wait for 5 ns;
        check_equal(s_pc_sel, '1', "BEQ: pc_sel should be 1 when br_eq is 1");
        check_equal(s_a_sel, '1', "B-type: a_sel must be 1 (PC)");
        check_equal(s_b_sel, '1', "B-type: b_sel must be 1 (Imm)");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_ADD), "B-type: ALU_ADD for target calculation");
        check_equal(s_reg_write_enable, '0', "B-type: reg_write must be 0");
        check_equal(to_integer(unsigned(s_imm_sel)), 3, "B-type: imm_sel must be 011");
        check_equal(s_invalid_instr, '0', "BEQ must be valid");

        -- BNE (funct3 = 001): Branch if rs1 != rs2
        s_funct3 <= "001";
        s_br_eq  <= '1'; -- Inputs are equal, condition is false
        wait for 5 ns;
        check_equal(s_pc_sel, '0', "BNE: pc_sel should be 0 when br_eq is 1");
        check_equal(s_invalid_instr, '0', "BNE must be valid");

        s_br_eq  <= '0'; -- Inputs are not equal, condition is true
        wait for 5 ns;
        check_equal(s_pc_sel, '1', "BNE: pc_sel should be 1 when br_eq is 0");
        check_equal(s_invalid_instr, '0', "BNE must be valid");

        -- BLT (funct3 = 100): Branch if rs1 < rs2 (signed)
        s_funct3 <= "100";
        s_br_lt  <= '1'; -- Simulate rs1 < rs2
        wait for 5 ns;
        check_equal(s_pc_sel, '1', "BLT: pc_sel should be 1 when br_lt is 1");
        check_equal(s_br_un, '0', "BLT: br_un signal must be 0 (signed)");
        check_equal(s_invalid_instr, '0', "BLT must be valid");

        -- BLTU (funct3 = 110): Branch if rs1 < rs2 (unsigned)
        s_funct3 <= "110";
        s_br_lt  <= '1';
        wait for 5 ns;
        check_equal(s_br_un, '1', "BLTU: br_un signal must be 1 (unsigned)");
        check_equal(s_pc_sel, '1', "BLTU: pc_sel should be 1 when br_lt is 1");
        check_equal(s_invalid_instr, '0', "BLTU must be valid");

        -- BGEU (funct3 = 111): Branch if rs1 >= rs2 (unsigned)
        s_funct3 <= "111";
        s_br_lt  <= '1'; -- rs1 < rs2, so rs1 >= rs2 is false
        wait for 5 ns;
        check_equal(s_br_un, '1', "BGEU: br_un signal must be 1");
        check_equal(s_pc_sel, '0', "BGEU: pc_sel should be 0 when br_lt is 1");
        check_equal(s_invalid_instr, '0', "BGEU must be valid");

      elsif run("test_upper_and_jump_instr") then

        s_halt_i <= '0';

        -----------------------------------------------------------------------
        -- UPPER IMMEDIATE: LUI, AUIPC (opcodes 0110111, 0010111)
        -----------------------------------------------------------------------

        -- LUI (Load Upper Immediate)
        s_opcode <= "0110111";
        wait for 5 ns;
        check_equal(s_reg_write_enable, '1', "LUI: reg_write must be 1");
        check_equal(to_integer(unsigned(s_imm_sel)), 4, "LUI: imm_sel must be U-type (100)");
        check_equal(s_a_sel, '0', "LUI: a_sel must be 0 (rs1 is x0)");
        check_equal(s_b_sel, '1', "LUI: b_sel must be 1 (immediate)");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_NOP), "LUI: ALU_ADD to pass imm");
        check_equal(to_integer(unsigned(s_wb_select_o)), 3, "LUI: wb_select must be ALU (11)");
        check_equal(s_invalid_instr, '0', "LUI must be valid");

        -- AUIPC (Add Upper Immediate to PC)
        s_opcode <= "0010111";
        wait for 5 ns;
        check_equal(s_reg_write_enable, '1', "AUIPC: reg_write must be 1");
        check_equal(to_integer(unsigned(s_imm_sel)), 4, "AUIPC: imm_sel must be U-type (100)");
        check_equal(s_a_sel, '1', "AUIPC: a_sel must be 1 (PC source)");
        check_equal(s_b_sel, '1', "AUIPC: b_sel must be 1 (immediate)");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_ADD), "AUIPC: ALU_ADD for PC+imm");
        check_equal(s_invalid_instr, '0', "AUIPC must be valid");
        -----------------------------------------------------------------------
        -- JUMPS: JAL, JALR (opcodes 1101111, 1100111)
        -----------------------------------------------------------------------

        -- JAL (Jump and Link)
        s_opcode <= "1101111";
        wait for 5 ns;
        check_equal(s_reg_write_enable, '1', "JAL: reg_write must be 1");
        check_equal(to_integer(unsigned(s_imm_sel)), 5, "JAL: imm_sel must be J-type (101)");
        check_equal(s_a_sel, '1', "JAL: a_sel must be 1 (PC source)");
        check_equal(s_pc_sel, '1', "JAL: pc_sel must be 1 (always taken)");
        check_equal(to_integer(unsigned(s_wb_select_o)), 2, "JAL: wb_select must be PC+4 (10)");
        check_equal(s_invalid_instr, '0', "JAL must be valid");

        -- JALR (Jump and Link Register)
        s_opcode <= "1100111";
        s_funct3 <= "000";
        wait for 5 ns;
        check_equal(s_reg_write_enable, '1', "JALR: reg_write must be 1");
        check_equal(to_integer(unsigned(s_imm_sel)), 1, "JALR: imm_sel must be I-type (001)");
        check_equal(s_a_sel, '0', "JALR: a_sel must be 0 (rs1 source)");
        check_equal(s_pc_sel, '1', "JALR: pc_sel must be 1 (always taken)");
        check_equal(to_integer(unsigned(s_wb_select_o)), 2, "JALR: wb_select must be PC+4 (10)");
        check_equal(s_invalid_instr, '0', "JALR must be valid");

      elsif run("test_halt_behavior") then

        s_halt_i     <= '1';
        s_opcode     <= "1111111";
        s_funct3     <= "111";
        s_funct7     <= (others => '1');
        s_imm_i_type <= (others => '1');
        s_br_eq      <= '1';
        s_br_lt      <= '1';
        wait for 5 ns;

        check_equal(s_reg_write_enable, '0', "HALT: reg_write must stay default");
        check_equal(s_b_sel,            '0', "HALT: b_sel must stay default");
        check_equal(s_a_sel,            '0', "HALT: a_sel must stay default");
        check_equal(t_alu_op'image(s_alu_op), t_alu_op'image(ALU_NOP), "HALT: ALU must stay NOP");
        check_equal(s_mem_rw_o,         '0', "HALT: mem_rw must stay default");
        check_equal(to_integer(unsigned(s_wb_select_o)), 0, "HALT: wb_select must stay default");
        check_equal(to_integer(unsigned(s_imm_sel)), 0, "HALT: imm_sel must stay default");
        check_equal(s_pc_sel,           '0', "HALT: pc_sel must stay default");
        check_equal(s_br_un,            '0', "HALT: br_un must stay default");
        check_equal(s_invalid_instr,    '0', "HALT: invalid_instr_o must remain 0");

      end if;
    end loop;

    test_runner_cleanup(runner);
  end process stim_proc;
end arch;
