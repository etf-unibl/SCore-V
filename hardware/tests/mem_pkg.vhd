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


  --! @brief Array type representing the instruction memory storage.
  subtype t_byte  is std_logic_vector(7 downto 0);
  type t_bytes is array (0 to 200) of t_byte;

  --! @brief Constant array containing the program to be executed.
  --! @details This serves as the ROM for the instruction fetch unit.
  constant c_IMEM : t_bytes := (
    0      => "10110011",
    1      => "10000111",
    2      => "00010000",
    3      => "00000000",
    4      => "10110011",
    5      => "10000011",
    6      => "00010001",
    7      => "00000000",
    8      => "10110011",
    9      => "10000111",
    10     => "00010011",
    11     => "00000000",
    12     => "10110011",
    13     => "10000111",
    14     => "00010111",
    15     => "00000000",
    16     => "10110011",
    17     => "10000111",
    18     => "00011111",
    19     => "00000000",
    20     => "00000000",
    21     => "00000000",
    22     => "00000000",
    23     => "10110011",
    24     => "00000000",
    25     => "00000000",
    26     => "10000111",
    27     => "10110011",
    28     => "00000000",
    29     => "00000000",
    30     => "10000111",
    31     => "10110011",
    32     => "00000000",
    33     => "00000000",
    34     => "00000000",
    others => "00000000"
  );

end mem_pkg;
