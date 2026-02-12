-----------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2025
-- https://github.com/etf-unibl/SCore-V/
-----------------------------------------------------------------------------
--
-- unit name: memory package unit
--
-- description:
--
--   This file implements a simple memory package.
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
library ieee;
use ieee.std_logic_1164.all;

--! @brief Global definitions for instruction formats and memory.
package mem_pkg is
  --! @brief Generic instruction record representing raw fetch data.
  type t_instruction_rec is record

    opcode                      : std_logic_vector(6 downto 0);  --! Instruction opcode (bits 6:0)
    other_instruction_bits      : std_logic_vector(24 downto 0); --! Remaining bits (31:7)

  end record t_instruction_rec;

  --! @brief R-type instruction format (Register-Register).
  type t_instruction_R is record

    func7 : std_logic_vector(6 downto 0);
    rs2   : std_logic_vector(4 downto 0);
    rs1   : std_logic_vector(4 downto 0);
    func3 : std_logic_vector(2 downto 0);
    rd    : std_logic_vector(4 downto 0);

  end record t_instruction_R;

  --! @brief I-type instruction format (Immediate).
  type t_instruction_I is record

    imm   : std_logic_vector(11 downto 0);
    rs1   : std_logic_vector(4 downto 0);
    func3 : std_logic_vector(2 downto 0);
    rd    : std_logic_vector(4 downto 0);

  end record t_instruction_I;

  --! @brief S-type instruction format (Store).
  type t_instruction_S is record

    imm2  : std_logic_vector(5 downto 0);
    rs2   : std_logic_vector(4 downto 0);
    rs1   : std_logic_vector(4 downto 0);
    func3 : std_logic_vector(2 downto 0);
    imm1  : std_logic_vector(4 downto 0);

  end record t_instruction_S;

  --! @brief Array type representing the instruction memory storage.
  type t_instr_array is array (0 to 3) of t_instruction_rec;

  --! @brief Constant array containing the program to be executed.
  --! @details This serves as the ROM for the instruction fetch unit.
  constant c_IMEM : t_instr_array := (
    0 => (opcode => "0110011", other_instruction_bits => "0000000000010000100001111"),
    1 => (opcode => "0110011", other_instruction_bits => "0000000000010001100000111"),
    2 => (opcode => "0110011", other_instruction_bits => "0000000000010011100000011"),
    3 => (opcode => "0110011", other_instruction_bits => "0000000000010011100000011")
  );

end mem_pkg;
