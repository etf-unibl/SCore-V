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

----------------------------------------- STRUCTURE OF INSTRUCTIONS ----------------------------------------
--
------------------------------------------------  R - TYPE  ------------------------------------------------
--
-- instruction    |31|FUNCT7|25|    |24|RS2|20|      |19|RS1|15|   |14|FUNCT3|12|   |11|RD|7|   |6|OPCODE|0|
-- ADD                0000000          xxxxx            yyyyy           000           zzzzz       0110011
--
------------------------------------------------  I - TYPE  ------------------------------------------------
--
-- instruction    |31|IMM[11:0]|20|       |19|RS1|15|       |14|FUNCT3|12|       |11|RD|7|      |6|OPCODE|0|
-- ADDI             xxxxxxxxxxxx             yyyyy              000                zzzzz          0010011
-- LOAD WORD        xxxxxxxxxxxx             yyyyy              010                zzzzz          0000011
--
------------------------------------------------  S - TYPE  ------------------------------------------------
--
-- instruction   |31|IMM[11:5]|25|  |24|RS2|20|  |19|RS1|15|  |14|FUNCT3|12|   |11|IMM[4:0]|7|  |6|OPCODE|0|
-- STORE WORD         xxxxxxx          yyyyy         zzzzz         010             xxxxx          0100011
--
------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

--! @brief Global definitions for instruction formats and memory.
package mem_pkg is
  --! @brief Generic instruction record representing raw fetch data.
  type t_instruction_rec is record

    opcode                      : std_logic_vector(6 downto 0);  --! Instruction opcode (bits 6:0)
    other_instruction_bits      : std_logic_vector(24 downto 0); --! Remaining bits (31:7)

  end record t_instruction_rec;

  --! @brief Array type representing the registers storage.
  type t_regs is array (0 to 31) of std_logic_vector(31 downto 0);
  signal regs : t_regs := (
    0      => x"00000000",
    1      => x"00000003",
    2      => x"00000005",
    others => (others => '0')
  );

  --! @brief Array type representing the instruction memory storage.
  subtype t_byte  is std_logic_vector(7 downto 0);
  type t_bytes is array (0 to 255) of t_byte;

  --! @brief Array representing the data memory storage.
  signal DMEM : t_bytes := (
    0      => "11111111",
    1      => "00000000",
    2      => "11001100",
    3      => "00110011",
    4      => "10101010",
    5      => "10101010",
    6      => "11110000",
    7      => "00001111",
    8      => "10000000",
    9      => "00000000",
    10     => "00000000",
    11     => "00000000",
    12     => "11000000",
    13     => "00000000",
    14     => "00000000",
    15     => "00000000", 
    16     => "00100000",
    17     => "00000000",
    18     => "00000000",
    19     => "00000000",
    20     => "11100000",
    21     => "00000000",
    22     => "00000000",
    23     => "00000000",
    24     => "00000000",  
    others => (others => '0')
  );

  --! @brief Constant array containing the program to be executed.
  --! @details This serves as the ROM for the instruction fetch unit.
  constant c_IMEM : t_bytes := (
    0      => "10110011",
    1      => "10000111",
    2      => "00010000",
    3      => "00000000", -- ADD operation ^
    4      => "10110011",
    5      => "10000011",
    6      => "00010001",
    7      => "00000000", -- ADD operation ^
    8      => "10110011",
    9      => "10000111",
    10     => "00010011",
    11     => "00000000", -- ADD operation ^
    12     => "10110011",
    13     => "10000111",
    14     => "00010111",
    15     => "00000000", -- ADD operation ^
    16     => "10110011",
    17     => "10000111",
    18     => "00011111",
    19     => "00000000", -- ADD operation ^
    20     => "10010011",
    21     => "00000000",
    22     => "10100000",
    23     => "00000000", -- ADD Immediete operation ^
    24     => "00010011",
    25     => "00000001",
    26     => "10110000",
    27     => "11111111", -- ADD Immediete operation ^
    28     => "10010011",
    29     => "10000001",
    30     => "00100000",
    31     => "00000000", -- ADD Immediete operation ^
    32     => "00000011",
    33     => "00100001",
    34     => "00000000",
    35     => "00000000", -- LOAD operation ^
    36     => "10000011",
    37     => "00100000",
    38     => "10000000",
    39     => "00000000", -- LOAD operation ^
    40     => "10100011",
    41     => "00101100",
    42     => "00010000",
    43     => "00000000",
    44     => "00000000",
    45     => "00000000",
    46     => "00000000",
    47     => "00000000",
    others => "00000000"
  );

end mem_pkg;
