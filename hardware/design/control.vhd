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
--   The module detects the R-type ADD instruction and asserts
--   the reg_write_enable_o signal accordingly.
--   For all other instruction encodings, the register write enable signal
--   remains deasserted.
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
--! Implements instruction decoding logic based on opcode,
--! funct3, and funct7 fields.
--!
--! In the current implementation, the control unit detects
--! the R-type ADD instruction and generates the register
--! write enable signal.

library ieee;
use ieee.std_logic_1164.all;

--! @brief Entity definition of control unit
entity control is
  port (
    opcode_i           : in  std_logic_vector(6 downto 0); --! Instruction opcode
    funct3_i           : in  std_logic_vector(2 downto 0); --! Instruction funct3 field
    funct7_i           : in  std_logic_vector(6 downto 0); --! Instruction funct7 field
    reg_write_enable_o : out std_logic --! Register write enable signal
  );
end entity control;

--! @brief Architecture implementation of control logic
--! @details
--! Asserts reg_write_enable_o when the instruction encoding
--! corresponds to the R-type ADD instruction:
--! opcode  = 0110011
--! funct3  = 000
--! funct7  = 0000000
architecture arch of control is
begin

  reg_write_enable_o <= '1' when
    opcode_i = "0110011" and
    funct3_i = "000" and
    funct7_i = "0000000"
  else
    '0';

end architecture arch;
