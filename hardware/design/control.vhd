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
--! Generated control signals:
--!
--! - reg_write_enable_o:
--!     Enables writeback into register file (rd).
--!
--! - imm_sel_o:
--!     Immediate format selector for ImmGen.
--!     "001" = I-type immediate
--!     "010" = S-type immediate
--!
--! - b_sel_o:
--!     Selects ALU operand B source.
--!     '0' = rs2_data
--!     '1' = imm32
--!
--! - alu_op_o:
--!     Selects ALU operation (e.g. ALU_ADD, ALU_NOP).
--!
--! - mem_rw_o:
--!     Data memory control.
--!     '0' = Read
--!     '1' = Write
--!
--! - wb_select_o:
--!     Write-back multiplexer select.
--!     '0' = Data memory output (DataR)
--!     '1' = ALU result

library ieee;
use ieee.std_logic_1164.all;
use work.alu_pkg.all;

--! @brief Entity definition of control unit
entity control is
  port (
    opcode_i           : in  std_logic_vector(6 downto 0);  --! Instruction opcode
    funct3_i           : in  std_logic_vector(2 downto 0);  --! Instruction funct3 field
    funct7_i           : in  std_logic_vector(6 downto 0);  --! Instruction funct7 field
    imm_i_type_i       : in  std_logic_vector(11 downto 0); --! I-type immediate (instr[31:20])
    reg_write_enable_o : out std_logic;                     --! Register write enable signal
    imm_sel_o          : out std_logic_vector(2 downto 0);  --! Immediate select/qualifier
    b_sel_o            : out std_logic;                     --! ALU operand B select (0=rs2_data, 1=immediate)
    alu_op_o           : out t_alu_op;                      --! ALU operation select
    mem_rw_o           : out std_logic;                     --! Data memory control
    wb_select_o        : out std_logic                      --! Write-back multiplexer select
  );
end entity control;

--! @brief Architecture implementation of control logic
--! @details
--! Provides safe defaults first, then overrides them when a supported
--! instruction encoding is detected.
architecture arch of control is
begin

  comb_proc : process (opcode_i, funct3_i, funct7_i, imm_i_type_i)
  begin
    reg_write_enable_o <= '0';
    b_sel_o            <= '0';
    alu_op_o           <= ALU_NOP;
    imm_sel_o          <= "000";
    mem_rw_o           <= '0';
    wb_select_o        <= '0';

-- =========================================================
--                 R-type ALU instructions
-- =========================================================
    if opcode_i = "0110011" then

      if funct3_i = "000" then
        if funct7_i = "0000000" then
          reg_write_enable_o <= '1';
          wb_select_o        <= '1';
          alu_op_o           <= ALU_ADD;
        elsif funct7_i = "0100000" then
          reg_write_enable_o <= '1';
          wb_select_o        <= '1';
          alu_op_o           <= ALU_SUB;
        end if;

      elsif (funct3_i = "001") and (funct7_i = "0000000") then
        reg_write_enable_o <= '1';
        wb_select_o        <= '1';
        alu_op_o           <= ALU_SLL;

      elsif (funct3_i = "010") and (funct7_i = "0000000") then
        reg_write_enable_o <= '1';
        wb_select_o        <= '1';
        alu_op_o           <= ALU_SLT;

      elsif (funct3_i = "011") and (funct7_i = "0000000") then
        reg_write_enable_o <= '1';
        wb_select_o        <= '1';
        alu_op_o           <= ALU_SLTU;

      elsif (funct3_i = "100") and (funct7_i = "0000000") then
        reg_write_enable_o <= '1';
        wb_select_o        <= '1';
        alu_op_o           <= ALU_XOR;

      elsif funct3_i = "101" then
        if funct7_i = "0000000" then
          reg_write_enable_o <= '1';
          wb_select_o        <= '1';
          alu_op_o           <= ALU_SRL;
        elsif funct7_i = "0100000" then
          reg_write_enable_o <= '1';
          wb_select_o        <= '1';
          alu_op_o           <= ALU_SRA;
        end if;

      elsif (funct3_i = "110") and (funct7_i = "0000000") then
        reg_write_enable_o <= '1';
        wb_select_o        <= '1';
        alu_op_o           <= ALU_OR;

      elsif (funct3_i = "111") and (funct7_i = "0000000") then
        reg_write_enable_o <= '1';
        wb_select_o        <= '1';
        alu_op_o           <= ALU_AND;
      end if;

-- =========================================================
--            I-type ALU immediate instructions
-- =========================================================
    elsif opcode_i = "0010011" then
      if funct3_i = "000" then
        imm_sel_o          <= "001";
        b_sel_o            <= '1';
        reg_write_enable_o <= '1';
        wb_select_o        <= '1';
        alu_op_o           <= ALU_ADD;

      elsif funct3_i = "010" then
        imm_sel_o          <= "001";
        b_sel_o            <= '1';
        reg_write_enable_o <= '1';
        wb_select_o        <= '1';
        alu_op_o           <= ALU_SLT;

      elsif funct3_i = "011" then
        imm_sel_o          <= "001";
        b_sel_o            <= '1';
        reg_write_enable_o <= '1';
        wb_select_o        <= '1';
        alu_op_o           <= ALU_SLTU;

      elsif funct3_i = "100" then
        imm_sel_o          <= "001";
        b_sel_o            <= '1';
        reg_write_enable_o <= '1';
        wb_select_o        <= '1';
        alu_op_o           <= ALU_XOR;

      elsif funct3_i = "110" then
        imm_sel_o          <= "001";
        b_sel_o            <= '1';
        reg_write_enable_o <= '1';
        wb_select_o        <= '1';
        alu_op_o           <= ALU_OR;

      elsif funct3_i = "111" then
        imm_sel_o          <= "001";
        b_sel_o            <= '1';
        reg_write_enable_o <= '1';
        wb_select_o        <= '1';
        alu_op_o           <= ALU_AND;

      elsif funct3_i = "001" then
        if imm_i_type_i(11 downto 5) = "0000000" then
          imm_sel_o          <= "001";
          b_sel_o            <= '1';
          reg_write_enable_o <= '1';
          wb_select_o        <= '1';
          alu_op_o           <= ALU_SLL;
        end if;

      elsif funct3_i = "101" then
        if imm_i_type_i(11 downto 5) = "0000000" then
          imm_sel_o          <= "001";
          b_sel_o            <= '1';
          reg_write_enable_o <= '1';
          wb_select_o        <= '1';
          alu_op_o           <= ALU_SRL;
        elsif imm_i_type_i(11 downto 5) = "0100000" then
          imm_sel_o          <= "001";
          b_sel_o            <= '1';
          reg_write_enable_o <= '1';
          wb_select_o        <= '1';
          alu_op_o           <= ALU_SRA;
        end if;
      end if;

-- =========================================================
--               LOAD and STORE instructions
-- =========================================================
    elsif (opcode_i = "0000011") and (funct3_i = "010") then
      imm_sel_o          <= "001";
      reg_write_enable_o <= '1';
      b_sel_o            <= '1';
      alu_op_o           <= ALU_ADD; -- LW address calc

    elsif (opcode_i = "0100011") and (funct3_i = "010") then
      imm_sel_o          <= "010";
      b_sel_o            <= '1';
      alu_op_o           <= ALU_ADD; -- SW address calc
      mem_rw_o           <= '1';

    end if;

  end process comb_proc;

end architecture arch;
