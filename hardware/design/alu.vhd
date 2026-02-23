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
--   32-bit combinational ALU for the RISC-V core.
--   Operation is selected by alu_op_i.
--
--   Supported operations in this task:
--     - ALU_ADD : y_o = a_i + b_i (mod 2^32)
--     - ALU_SUB : y_o = a_i - b_i (mod 2^32)
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
--! @brief 32-bit combinational ALU
--! @details
--! This unit implements a combinational ALU used in the RISC-V datapath.
--! The output is determined by the operation selector `alu_op_i`.
--!
--! Supported operations:
--! - `ALU_NOP`: output is forced to 0
--! - `ALU_ADD`: unsigned addition of a_i and b_i (wrap-around modulo 2^32)
--! - `ALU_SUB`: unsigned subtraction of a_i and b_i (wrap-around modulo 2^32)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.alu_pkg.all;

--! @brief Entity definition of alu
--! @details Combinational ALU with two 32-bit operands and one 32-bit result.
entity alu is
  port (
    a_i      : in  std_logic_vector(31 downto 0); --! First operand
    b_i      : in  std_logic_vector(31 downto 0); --! Second operand
    alu_op_i : in  t_alu_op;                      --! Operation select
    y_o      : out std_logic_vector(31 downto 0)  --! Result
  );
end entity alu;

--! @brief Architecture implementation of the ALU
--! @details Pure combinational logic.
architecture arch of alu is
  signal res_s : std_logic_vector(31 downto 0);
begin

  --! @brief Combinational ALU process
  --! @details Computes the ALU result based on alu_op_i.
  process(a_i, b_i, alu_op_i)
  begin
    -- Default assignment (safe value for unsupported operations)
    res_s <= (others => '0');

    case alu_op_i is
      when ALU_NOP =>
        res_s <= (others => '0');

      when ALU_ADD =>
        res_s <= std_logic_vector(unsigned(a_i) + unsigned(b_i));

      when ALU_SUB =>
        res_s <= std_logic_vector(unsigned(a_i) - unsigned(b_i));

      when others =>
        res_s <= (others => '0');
    end case;
  end process;

  --! @brief Result output
  --! @details Drives the ALU result to the output port.
  y_o <= res_s;

end architecture arch;
