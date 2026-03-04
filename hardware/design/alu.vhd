-----------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2025
-- https://github.com/etf-unibl/SCore-V/
-----------------------------------------------------------------------------
--
-- unit name:     alu
--
-- description:
--
--   32-bit combinational Arithmetic Logic Unit (ALU) for the RISC-V core.
--   The ALU executes the operation selected by alu_op_i on operands a_i and b_i.
--   Supported operations include arithmetic, logical, shift, and compare
--   operations required by the RV32I base integer instruction set.
--   For shift operations, the shift amount is taken from b_i(4 downto 0).
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
--! @brief Arithmetic Logic Unit (ALU)
--! @details
--! The operation is selected via alu_op_i (t_alu_op from alu_pkg).
--! Operands are provided as 32-bit vectors (a_i, b_i) and the result is y_o.
--! For shift operations, only b_i(4 downto 0) is used as the shift amount.
--! SLT performs signed comparison, while SLTU performs unsigned comparison.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.alu_pkg.all;

--! @brief Entity definition of alu
entity alu is
  port (
    a_i      : in  std_logic_vector(31 downto 0); --! First operand
    b_i      : in  std_logic_vector(31 downto 0); --! Second operand
    alu_op_i : in  t_alu_op;                      --! Operation select
    y_o      : out std_logic_vector(31 downto 0)  --! Result
  );
end entity alu;

--! @brief Architecture implementation of the ALU
--! @details
--! Pure combinational logic. The internal signal res_s holds the computed result.
architecture arch of alu is
  signal res_s : std_logic_vector(31 downto 0);
begin

  --! @brief Combinational ALU process
  --! @details
  --! Computes res_s based on alu_op_i, a_i and b_i.
  --! shift_count is derived from the lower 5 bits of b_i (range 0..31).
  process(a_i, b_i, alu_op_i)
    variable shift_count : natural range 0 to 31;
  begin
    shift_count := to_integer(unsigned(b_i(4 downto 0)));
    -- Default assignment (safe value for unsupported operations)
    res_s <= (others => '0');

    case alu_op_i is
      when ALU_NOP =>
        res_s <= (others => '0');

      when ALU_ADD =>
        res_s <= std_logic_vector(unsigned(a_i) + unsigned(b_i));

      when ALU_SUB =>
        res_s <= std_logic_vector(unsigned(a_i) - unsigned(b_i));

      when ALU_AND =>
        res_s <= a_i and b_i;

      when ALU_OR =>
        res_s <= a_i or b_i;

      when ALU_XOR =>
        res_s <= a_i xor b_i;

      when ALU_SLL =>
        res_s <= std_logic_vector(shift_left(unsigned(a_i), shift_count));

      when ALU_SRL =>
        res_s <= std_logic_vector(shift_right(unsigned(a_i), shift_count));

      when ALU_SRA =>
        res_s <= std_logic_vector(shift_right(signed(a_i), shift_count));

      when ALU_SLT =>
        if signed(a_i) < signed(b_i) then
          res_s <= (31 downto 1 => '0') & '1';
        else
          res_s <= (others => '0');
        end if;

      when ALU_SLTU =>
        if unsigned(a_i) < unsigned(b_i) then
          res_s <= (31 downto 1 => '0') & '1';
        else
          res_s <= (others => '0');
        end if;

      when others =>
        res_s <= (others => '0');
    end case;
  end process;

  --! @brief Result output
  --! @details Drives the ALU result to the output port.
  y_o <= res_s;

end architecture arch;
