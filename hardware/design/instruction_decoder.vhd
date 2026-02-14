-----------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2025
-- https://github.com/etf-unibl/SCore-V
-----------------------------------------------------------------------------
--
-- unit name:     instruction_decoder
--
-- description:
--
--   Instruction decoder for the record-based IMEM interface.
--   Reconstructs the 32-bit instruction word and extracts common fields
--   (rs1/rs2/rd/funct3/funct7) as well as format-specific immediates.
--
--   For instruction formats where a field is not applicable, the output
--   field is driven to all zeros.
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

--! @file instruction_decoder.vhd
--! @brief Instruction decoder for record-based IMEM.
--! @details
--! The instruction memory provides a record with:
--! - opcode (instr[6:0])
--! - other_instruction_bits (instr[31:7])
--!
--! This module reconstructs the full 32-bit instruction word:
--!   instr32 = other_instruction_bits & opcode
--!
--! Then it extracts:
--! - Common fields: rs1, rs2, rd, funct3, funct7
--! - I-type immediate: imm_i_type_o = instr[31:20]
--! - S-type immediate split: imm_s_type_h_o = instr[31:25], imm_s_type_l_o = instr[11:7]
--!
--! Unused outputs for a given opcode are driven to all zeros.

library ieee;
use ieee.std_logic_1164.all;

use work.mem_pkg.all;

--! @brief Instruction decoder entity
entity instruction_decoder is
  port (
    instr_i        : in  t_instruction_rec;  --! Record-based instruction input (opcode + upper bits)
    opcode_o       : out std_logic_vector(6 downto 0); --! Opcode field (instr[6:0])
    rs1_o          : out std_logic_vector(4 downto 0); --! Register source 1 (instr[19:15])
    rs2_o          : out std_logic_vector(4 downto 0); --! Register source 2 (instr[24:20])
    rd_o           : out std_logic_vector(4 downto 0); --! Register destination (instr[11:7])
    funct3_o       : out std_logic_vector(2 downto 0); --! funct3 field (instr[14:12])
    funct7_o       : out std_logic_vector(6 downto 0); --! funct7 field (instr[31:25])
    imm_i_type_o   : out std_logic_vector(11 downto 0); --! I-type immediate (instr[31:20])
    imm_s_type_h_o : out std_logic_vector(6 downto 0); --! S-type immediate high part (instr[31:25])
    imm_s_type_l_o : out std_logic_vector(4 downto 0) --! S-type immediate low part (instr[11:7])
);
end instruction_decoder;

--! @brief Instruction decoder architecture
architecture arch of instruction_decoder is
begin

  --! @brief Combinational decode process
  --! @details
  --! Reconstructs the 32-bit instruction word from the record input and
  --! extracts fields based on opcode. All outputs are defaulted to zero to
  --! avoid latch inference.
  process(instr_i)
    variable instr32_v : std_logic_vector(31 downto 0);
  begin
    instr32_v := instr_i.other_instruction_bits & instr_i.opcode;

    rs1_o          <= (others => '0');
    rs2_o          <= (others => '0');
    rd_o           <= (others => '0');
    funct3_o       <= (others => '0');
    funct7_o       <= (others => '0');
    imm_i_type_o   <= (others => '0');
    imm_s_type_h_o <= (others => '0');
    imm_s_type_l_o <= (others => '0');

    opcode_o <= instr_i.opcode;

    case instr_i.opcode is
      when "0110011" => --! R-type (OP): 0110011
        funct7_o <= instr32_v(31 downto 25);
        rs2_o    <= instr32_v(24 downto 20);
        rs1_o    <= instr32_v(19 downto 15);
        funct3_o <= instr32_v(14 downto 12);
        rd_o     <= instr32_v(11 downto 7);

      when "0010011" | "0000011" => --! I-type examples (OP-IMM or LOAD): 0010011 or 0000011
        imm_i_type_o <= instr32_v(31 downto 20);
        rs1_o        <= instr32_v(19 downto 15);
        funct3_o     <= instr32_v(14 downto 12);
        rd_o         <= instr32_v(11 downto 7);

      when "0100011" => --! S-type (STORE): 0100011
        imm_s_type_h_o <= instr32_v(31 downto 25);
        rs2_o          <= instr32_v(24 downto 20);
        rs1_o          <= instr32_v(19 downto 15);
        funct3_o       <= instr32_v(14 downto 12);
        imm_s_type_l_o <= instr32_v(11 downto 7);

      when others =>
        null;
    end case;
  end process;
end arch;
