-----------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2025
-- https://github.com/etf-unibl/pds-2025/
-----------------------------------------------------------------------------
--
-- unit name:     alu
--
-- description:
--
--   This file implements a 32-bit combinational ALU for the RISC-V core.
--   The current implementation supports only the ADD operation and produces
--   the sum of two 32-bit input operands.
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

--! @file alu.vhd
--! @brief Arithmetic Logic Unit
--! @details
--! Implements the execution unit of the RISC-V datapath.
--! In the current development stage, the ALU performs
--! unsigned addition of two 32-bit operands.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--! @brief Entity definition of alu
entity alu is
  port (
    a_i : in  std_logic_vector(31 downto 0); --! First operand
    b_i : in  std_logic_vector(31 downto 0); --! Second operand
    y_o : out std_logic_vector(31 downto 0)  --! ALU result (a_i + b_i)
  );
end entity alu;

--! @brief Architecture implementation of the ALU
--! @details
--! Performs combinational unsigned addition:
--! y_o = a_i + b_i
architecture arch of alu is
  signal sum_s : unsigned(31 downto 0);
begin

  sum_s <= unsigned(a_i) + unsigned(b_i);
  y_o   <= std_logic_vector(sum_s);

end architecture arch;
