-----------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2025
-- https://github.com/etf-unibl/SCore-V/
-----------------------------------------------------------------------------
--
-- unit name:     branch_comparator
--
-- description:
--
--   32-bit combinational Branch Comparator for RV32I B-type instructions.
--   The comparator produces:
--     - br_eq_o: asserted when A == B
--     - br_lt_o: asserted when A < B
--   Signedness for the less-than comparison is selected by br_un_i:
--     - br_un_i = '0' -> signed comparison
--     - br_un_i = '1' -> unsigned comparison
--
--   The control unit uses br_eq_o and br_lt_o (and their negations)
--   to realize BEQ/BNE/BLT/BGE/BLTU/BGEU decisions.
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

--! @file branch_comparator.vhd
--! @brief Combinational branch comparator (BrEq/BrLT)
--! @details
--! Generates br_eq_o and br_lt_o flags used by the control unit for RV32I branches.
--! br_lt_o depends on br_un_i (signed/unsigned selection).

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity branch_comparator is
  port (
    a_i     : in  std_logic_vector(31 downto 0); --! Operand A (rs1_data)
    b_i     : in  std_logic_vector(31 downto 0); --! Oprenad B (rs2_data)
    br_un_i : in  std_logic;                     --! '1' unsigned LT, '0' signed LT
    br_eq_o : out std_logic;                     --! '1' when A==B
    br_lt_o : out std_logic                      --! '1' when A<B (mode-select)
  );
end entity branch_comparator;

architecture arch of branch_comparator is
begin

  br_eq_o <= '1' when a_i = b_i else '0';
  br_lt_o <= '1' when br_un_i = '0' and signed(a_i) < signed(b_i) else
           '1' when br_un_i = '1' and unsigned(a_i) < unsigned(b_i) else
           '0';
end arch;
