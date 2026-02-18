-----------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2025
-- https://github.com/etf-unibl/SCore-V/
-----------------------------------------------------------------------------
--
-- unit name:     score_v
--
-- description:
--
--   Top-level unit for SCore-V processor.
--   Integrates Program Counter, Instruction Fetch, Decoder, Control Unit,
--   Register File, and ALU. Provides instruction execution
--   with register read/write and ALU computation.
--   Currently, this implementation only supports the ADD, ADDI datapath.
--   Support for other instructions will be added in future expansions.
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
use work.mem_pkg.all;
use work.alu_pkg.all;

--! @file score_v.vhd
--! @brief Top-level SCore-V module
--! @details Implements a simple SCore-V CPU for the ADD datapath and ADDI.
--!   Integrates Program Counter, instruction fetch, decoder, control unit,
--!   register file, and ALU. Provides register read/write and ALU computation.
--!   Currently supports only ADD instruction; other instructions will be added in future.
--!   NOTE: The outputs pc_o, opcode_o, rd_o, rs1_o, rs2_o, rs1_data_o, rs2_data_o,
--!         alu_result_o, and reg_we_o are provided primarily for debug and testbench
--!         purposes, allowing detailed monitoring of their states.

entity score_v is
  port (
    clk_i        : in  std_logic;                     --! Clock input
    rst_i        : in  std_logic;                     --! Reset input

    instr_addr_o : out std_logic_vector(31 downto 0); --! PC output to memory
    instr_data_i : in  t_instruction_rec;             --! Instruction input from fetch_instruction

    pc_o         : out std_logic_vector(31 downto 0); --! Program counter value output
    opcode_o     : out std_logic_vector(6 downto 0);  --! Instruction opcode output
    rd_o         : out std_logic_vector(4 downto 0);  --! Destination register address output
    rs1_o        : out std_logic_vector(4 downto 0);  --! Source register 1 address output
    rs2_o        : out std_logic_vector(4 downto 0);  --! Source register 2 address output
    rs1_data_o   : out std_logic_vector(31 downto 0); --! Source register 1 data output
    rs2_data_o   : out std_logic_vector(31 downto 0); --! Source register 2 data output
    alu_result_o : out std_logic_vector(31 downto 0); --! ALU result output
    reg_we_o     : out std_logic                      --! Register write enable output
  );
end score_v;

--! @brief Architecture arch for top-level SCore-V CPU
--! @details Instantiates and connects all CPU submodules:
--!   PC, PC next, instruction fetch, instruction decoder, control unit,
--!   register file, and ALU. Handles the ADD datapath for now.
architecture arch of score_v is

  --! @brief Internal PC signals
  signal pc_sig       : std_logic_vector(31 downto 0); --! Current PC
  signal pc_next_sig  : std_logic_vector(31 downto 0); --! Next sequential PC

  --! @brief Instruction and decoding signals
  signal instr_sig    : t_instruction_rec;             --! Fetched instruction

  signal opcode_sig   : std_logic_vector(6 downto 0);  --! Decoded opcode
  signal rd_sig       : std_logic_vector(4 downto 0);  --! Decoded destination register
  signal rs1_sig      : std_logic_vector(4 downto 0);  --! Decoded source register 1
  signal rs2_sig      : std_logic_vector(4 downto 0);  --! Decoded source register 2
  signal funct3_sig   : std_logic_vector(2 downto 0);  --! Decoded funct3 field
  signal funct7_sig   : std_logic_vector(6 downto 0);  --! Decoded funct7 field

  --! @brief Register file signals
  signal rs1_data_sig : std_logic_vector(31 downto 0);   --! Data from source register 1
  signal rs2_data_sig : std_logic_vector(31 downto 0);   --! Data from source register 2
  signal alu_result_sig : std_logic_vector(31 downto 0); --! ALU computation result
  signal reg_we_sig   : std_logic := '0';                --! Register write enable

  --! @brief Datapath integration and control signals for addi
  signal imm_sig       : std_logic_vector(31 downto 0); --! Immediate value output from the Immediate Generator
  signal alu_b_sig     : std_logic_vector(31 downto 0); --! ALU operand B input, selected between rs2_data and imm_sig
  signal imm_sel_sig   : std_logic_vector(2 downto 0);  --! Selection signal for Immediate Generator to define instruction format
  signal b_sel_sig     : std_logic;                     --! Control signal for ALU operand B source selection
  signal alu_op_sig    : t_alu_op;                      --! Operation selection signal for the ALU controller

  --! @brief Program Counter (PC) module
  --! @details Holds and updates the current program counter value based on
  --!   the next PC input and clock/reset signals.
  component pc is
    port (
      clk_i     : in  std_logic;
      rst_i     : in  std_logic;
      pc_next_i : in  std_logic_vector(31 downto 0);
      pc_o      : out std_logic_vector(31 downto 0)
    );
  end component;

  --! @brief Next sequential PC calculation
  --! @details Computes the next PC value by incrementing the current PC.
  component pc_next_instruction is
    port (
      pc_i       : in  std_logic_vector(31 downto 0);
      pc_next_o  : out std_logic_vector(31 downto 0)
    );
  end component;

  --! @brief Instruction decoder
  --! @details Decodes fetched instruction into opcode, register addresses,
  --!   funct3/funct7 fields, and immediate fields.
  component instruction_decoder is
    port (
      instr_i         : in  t_instruction_rec;
      opcode_o        : out std_logic_vector(6 downto 0);
      rs1_o           : out std_logic_vector(4 downto 0);
      rs2_o           : out std_logic_vector(4 downto 0);
      rd_o            : out std_logic_vector(4 downto 0);
      funct3_o        : out std_logic_vector(2 downto 0);
      funct7_o        : out std_logic_vector(6 downto 0);
      imm_i_type_o    : out std_logic_vector(11 downto 0);
      imm_s_type_h_o  : out std_logic_vector(6 downto 0);
      imm_s_type_l_o  : out std_logic_vector(4 downto 0)
    );
  end component;

  --! @brief Control unit
  --! @details Generates control signals such as register write enable
  --!   based on opcode and funct fields from the decoded instruction.
  component control is
    port (
      opcode_i           : in  std_logic_vector(6 downto 0);
      funct3_i           : in  std_logic_vector(2 downto 0);
      funct7_i           : in  std_logic_vector(6 downto 0);
      reg_write_enable_o : out std_logic;
      imm_sel_o          : out std_logic_vector(2 downto 0);
      b_sel_o            : out std_logic;
      alu_op_o           : out t_alu_op
    );
  end component;

  component imm_gen is
    port (
      instruction_bits_i : in  std_logic_vector(24 downto 0);
      imm_sel_i          : in  std_logic_vector(2 downto 0);
      imm_o              : out std_logic_vector(31 downto 0)
    );
  end component;

  component alu_operand_b_mux is
    port (
      in0_i : in  std_logic_vector(31 downto 0);
      in1_i : in  std_logic_vector(31 downto 0);
      sel_i : in  std_logic;
      out_o : out std_logic_vector(31 downto 0)
    );
  end component;

  --! @brief Register file
  --! @details Contains CPU registers. Supports reading two source registers
  --!   and writing to a destination register on write enable signal.
  component reg_file is
    port (
      clk_i        : in  std_logic;
      reg_write_i  : in  std_logic;
      rs1_addr_i   : in  std_logic_vector(4 downto 0);
      rs2_addr_i   : in  std_logic_vector(4 downto 0);
      rd_addr_i    : in  std_logic_vector(4 downto 0);
      rd_data_i    : in  std_logic_vector(31 downto 0);
      rs1_data_o   : out std_logic_vector(31 downto 0);
      rs2_data_o   : out std_logic_vector(31 downto 0)
    );
  end component;

  --! @brief Arithmetic Logic Unit (ALU)
  --! @details Performs arithmetic and logic operations on input operands
  --!   and provides the result as output.
  component alu is
    port (
      a_i : in  std_logic_vector(31 downto 0);
      b_i : in  std_logic_vector(31 downto 0);
      y_o : out std_logic_vector(31 downto 0)
    );
  end component;

begin

  --! @brief Program Counter instance
  u_pc : pc
    port map (
      clk_i     => clk_i,
      rst_i     => rst_i,
      pc_next_i => pc_next_sig,
      pc_o      => pc_sig
    );

  --! @brief Next PC computation
  u_pc_next : pc_next_instruction
    port map (
      pc_i      => pc_sig,
      pc_next_o => pc_next_sig
    );

  --! @brief Instruction decoder
  u_decoder : instruction_decoder
    port map (
      instr_i         => instr_data_i,
      opcode_o        => opcode_sig,
      rs1_o           => rs1_sig,
      rs2_o           => rs2_sig,
      rd_o            => rd_sig,
      funct3_o        => funct3_sig,
      funct7_o        => funct7_sig,
      imm_i_type_o    => open,
      imm_s_type_h_o  => open,
      imm_s_type_l_o  => open
    );

  --! @brief Control unit instance
  u_control : control
    port map (
      opcode_i           => opcode_sig,
      funct3_i           => funct3_sig,
      funct7_i           => funct7_sig,
      reg_write_enable_o => reg_we_sig,
      imm_sel_o          => imm_sel_sig,
      b_sel_o            => b_sel_sig,
      alu_op_o           => alu_op_sig
    );

  u_imm_gen : imm_gen
    port map (
      instruction_bits_i => instr_data_i.other_instruction_bits,
      imm_sel_i          => imm_sel_sig,
      imm_o              => imm_sig
    );

  --! @brief Register file
  u_regfile : reg_file
    port map (
      clk_i       => clk_i,
      reg_write_i => reg_we_sig,
      rs1_addr_i  => rs1_sig,
      rs2_addr_i  => rs2_sig,
      rd_addr_i   => rd_sig,
      rd_data_i   => alu_result_sig,
      rs1_data_o  => rs1_data_sig,
      rs2_data_o  => rs2_data_sig
    );

  --! @brief ALU Operand B Multiplexer
  u_alu_mux : alu_operand_b_mux
    port map (
      in0_i => rs2_data_sig,
      in1_i => imm_sig,
      sel_i => b_sel_sig,
      out_o => alu_b_sig
    );

  --! @brief ALU
  u_alu : alu
    port map (
      a_i => rs1_data_sig,
      b_i => alu_b_sig,
      y_o => alu_result_sig
    );

  --! @brief Output assignments
  instr_addr_o <= pc_sig;
  pc_o         <= pc_sig;
  opcode_o     <= opcode_sig;
  rd_o         <= rd_sig;
  rs1_o        <= rs1_sig;
  rs2_o        <= rs2_sig;
  rs1_data_o   <= rs1_data_sig;
  rs2_data_o   <= rs2_data_sig;
  alu_result_o <= alu_result_sig;
  reg_we_o     <= reg_we_sig;

end arch;
