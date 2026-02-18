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
--!
--! Selection is controlled by:
--!   - wb_select_i
--!
--! Signal semantics:
--!   wb_select_i = '0'  -> mem_data_i is selected (used for LOAD instructions)
--!   wb_select_i = '1'  -> alu_result_i is selected (used for arithmetic instructions)
--!
--! Typical usage:
--!   - R-type ADD     -> wb_select_i = '1'
--!   - I-type ADDI    -> wb_select_i = '1'
--!   - I-type LW      -> wb_select_i = '0'
--!   - S-type SW      -> Don't care (register write disabled)

library ieee;
use ieee.std_logic_1164.all;

entity wb_mux is
  port (
    alu_result_i  : in  std_logic_vector(31 downto 0); --! Result produced by the ALU
    mem_data_i    : in  std_logic_vector(31 downto 0); --! Data read from data memory (DMEM)
    wb_select_i   : in  std_logic;                     --! Selection input
    wb_data_o     : out std_logic_vector(31 downto 0)  --! Final write-back data to be written into destination register (rd)
  );
end entity wb_mux;

architecture arch of wb_mux is
begin

  wb_data_o <= mem_data_i when wb_select_i = '0'
               else alu_result_i;

end arch;
