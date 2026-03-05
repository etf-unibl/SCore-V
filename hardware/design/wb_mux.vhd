-----------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2025
-- https://github.com/etf-unibl/SCore-V
-----------------------------------------------------------------------------
--
-- unit name:     wb_mux
--
-- description:
--
--   This file implements the write-back multiplexer for the RISC-V core.
--   The multiplexer selects the data source that will be written into
--   the destination register (rd) of the register file.
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

--! @file wb_mux.vhd
--! @brief Write-back multiplexer for the RISC-V core datapath
--! @details
--! This module selects the data source that will be written back
--! into the register file (rd).
--!
--! The multiplexer has two inputs:
--!   - alu_result_i : Result produced by the ALU
--!   - mem_data_i   : Data read from data memory (DMEM)
--!   - pc4_i        : PC + 4 (JAL/JALR link address)
--!
--! Selection is controlled by a 2-bit select input:
--!   wb_select_i = "00" -> mem_data_i (used for LOAD instructions)
--!   wb_select_i = "01" -> alu_result_i (used for arithmetic instructions)
--!   wb_select_i = "10" -> pc4_i
--!   wb_select_i = "11" -> imm_lui_i

library ieee;
use ieee.std_logic_1164.all;

entity wb_mux is
  port (
    alu_result_i  : in  std_logic_vector(31 downto 0); --! Result produced by the ALU
    mem_data_i    : in  std_logic_vector(31 downto 0); --! Data read from data memory (DMEM)
    pc4_i         : in  std_logic_vector(31 downto 0); --! PC + 4 (JAL/JALR)
    imm_lui_i     : in  std_logic_vector(31 downto 0); --! rd = imm << 12 (generated in imm generator) for LUI instruction
    wb_select_i   : in  std_logic_vector(1 downto 0);  --! Selection input
    wb_data_o     : out std_logic_vector(31 downto 0)  --! Final write-back data to be written into destination register (rd)
  );
end entity wb_mux;

architecture arch of wb_mux is
begin
  with wb_select_i select
    wb_data_o <= mem_data_i when "00",
                 alu_result_i  when "01",
                 pc4_i when "10",
                 imm_lui_i when others; -- "11"
end arch;
