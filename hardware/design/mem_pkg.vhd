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

use std.textio.all;

use ieee.std_logic_textio.all;

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
    4      => x"00000003",
    5      => x"00000007",
    19     => x"F0000000",
    20     => x"0000000F",
    21     => x"00000033",
    25     => x"00000001",
    26     => x"00000002",
    27     => x"00000002",
    28     => x"FFFFFFFF",
    29     => x"FFFFFFFE",
    others => (others => '0')
  );
  --! @brief Maximums of DMEM memory and IMEM memory
  constant c_TOTAL_BYTES : integer := 1024;

  --! @brief Array type representing the instruction memory storage.
  subtype t_byte  is std_logic_vector(7 downto 0);
  type t_bytes    is array (0 to c_TOTAL_BYTES - 1) of t_byte;

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
    24     => "00001111",  -- x20 = 0x0000000F
    25     => "00000000",
    26     => "00000000",
    27     => "00000000",
    28     => "00110011",  -- x21 = 0x00000033
    29     => "00000000",
    30     => "00000000",
    31     => "00000000",
    32     => "00000000",
    33     => "00000000",
    34     => "00000000",
    35     => "00000000",
    36     => "11110000",  -- 0x000000F0
    37     => "00000000",
    38     => "00000000",
    39     => "00000000",
    others => (others => '0')
  );
end mem_pkg;

package body mem_pkg is
end package body mem_pkg;
