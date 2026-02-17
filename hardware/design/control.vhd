-----------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2025
-- https://github.com/etf-unibl/SCore-V
-----------------------------------------------------------------------------
--
-- unit name:     control
--
-- description:
--
--   This file implements a combinational control unit for the RISC-V core.
--   The control unit performs instruction decoding based on the opcode,
--   funct3, and funct7 fields and generates the appropriate control signals
--   for the datapath.
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

--! @file control.vhd
--! @brief Combinational control unit for the RISC-V core
--! @details
--! This module decodes the instruction fields provided by the instruction decoder
--! (opcode/funct3/funct7) and generates datapath control signals.
--!
--! Currently supported instructions:
--! - R-type ADD   (opcode=0110011, funct3=000, funct7=0000000)
--! - I-type ADDI  (opcode=0010011 (OP-IMM), funct3=000)
--!
--! Generated control signals (current scope):
--! - reg_write_enable_o : Enables writeback into rd.
--! - b_sel_o            : Selects ALU operand B source (0=rs2, 1=imm32).
--! - imm_sel_o          : Selects immediate generation path for I-type immediate.
--! - alu_op_o           : Selects ALU operation (ALU_ADD / ALU_NOP).
--!
--! Notes:
--! - For unsupported instructions all outputs are driven to safe defaults:
--!   no register write, ALU_NOP, operand B defaults to rs2, imm_sel_o deasserted.

library ieee;
use ieee.std_logic_1164.all;
use work.alu_pkg.all;

--! @brief Entity definition of control unit
entity control is
  port (
    opcode_i           : in  std_logic_vector(6 downto 0); --! Instruction opcode
    funct3_i           : in  std_logic_vector(2 downto 0); --! Instruction funct3 field
    funct7_i           : in  std_logic_vector(6 downto 0); --! Instruction funct7 field
    reg_write_enable_o : out std_logic;  --! Register write enable signal
    imm_sel_o          : out std_logic;  --! Immediate select/qualifier (1=use I-type imm path, 0=inactive)
    b_sel_o            : out std_logic;  --! ALU operand B select (0=rs2_data, 1=immediate)
    alu_op_o           : out t_alu_op    --! ALU operation select (e.g. ALU_ADD, ALU_NOP)
  );
end entity control;

--! @brief Architecture implementation of control logic
--! @details
--! Provides safe defaults first, then overrides them when a supported
--! instruction encoding is detected.
architecture arch of control is
begin

  comb_proc : process (opcode_i, funct3_i, funct7_i)
  begin
    reg_write_enable_o <= '0';
    b_sel_o            <= '0';
    alu_op_o           <= ALU_NOP;
    imm_sel_o          <= '0';

    if (opcode_i = "0110011") and (funct3_i = "000") and (funct7_i = "0000000") then
      reg_write_enable_o <= '1';
      b_sel_o            <= '0';
      alu_op_o           <= ALU_ADD;  --! R-type ADD

    elsif (opcode_i = "0010011") and (funct3_i = "000") then
      imm_sel_o          <= '1';
      reg_write_enable_o <= '1';
      b_sel_o            <= '1';
      alu_op_o           <= ALU_ADD; --! I-type ADDI (OP-IMM)
    end if;
  end process comb_proc;

end architecture arch;
