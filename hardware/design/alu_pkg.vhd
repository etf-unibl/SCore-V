-----------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2025
-- https://github.com/etf-unibl/SCore-V
-----------------------------------------------------------------------------
--
-- unit name:     alu_pkg
--
-- description:
--
--   Shared ALU type definitions.
--   Defines the enumerated ALU operation selector type (t_alu_op) used by:
--     - the control unit to select an ALU operation, and
--     - the ALU to execute the selected operation.
--
--   Supported operations include arithmetic, logical, shift, and compare
--   operations required by the RV32I base integer instruction set.
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

--! @file alu_pkg.vhd
--! @brief ALU shared type definitions
--! @details
--! Defines the ALU operation selector type `t_alu_op`.
--! The control unit drives an `alu_op` signal of this type to select
--! the operation performed by the ALU.

library ieee;
use ieee.std_logic_1164.all;

package alu_pkg is

  --! @brief Enumerated ALU operation type
  type t_alu_op is (
    ALU_NOP,
    ALU_ADD,
    ALU_SUB,
    ALU_AND,
    ALU_OR,
    ALU_XOR,
    ALU_SLL,
    ALU_SRL,
    ALU_SRA,
    ALU_SLT,
    ALU_SLTU
  );

end package alu_pkg;
