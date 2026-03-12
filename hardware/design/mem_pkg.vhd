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
-- SUB                0000010          xxxxx            yyyyy           000           zzzzz       0110011
-- XOR                0000000          xxxxx            yyyyy           100           zzzzz       0110011
-- OR                 0000000          xxxxx            yyyyy           110           zzzzz       0110011
-- AND                0000000          xxxxx            yyyyy           111           zzzzz       0110011
-- SLL                0000000          xxxxx            yyyyy           001           zzzzz       0110011
-- SRL                0000000          xxxxx            yyyyy           101           zzzzz       0110011
-- SRA                0000010          xxxxx            yyyyy           101           zzzzz       0110011
-- SLT                0000000          xxxxx            yyyyy           010           zzzzz       0110011
-- SLTU               0000000          xxxxx            yyyyy           011           zzzzz       0110011
--
------------------------------------------------  I - TYPE  ------------------------------------------------
--
-- instruction    |31|IMM[11:0]|20|       |19|RS1|15|       |14|FUNCT3|12|       |11|RD|7|      |6|OPCODE|0|
-- ADDI             xxxxxxxxxxxx             yyyyy              000                zzzzz          0010011
-- XORI             xxxxxxxxxxxx             yyyyy              100                zzzzz          0010011
-- ORI              xxxxxxxxxxxx             yyyyy              110                zzzzz          0010011
-- ANDI             xxxxxxxxxxxx             yyyyy              111                zzzzz          0010011
-- SLLI             xxxxxxxxxxxx             yyyyy              001                zzzzz          0010011
-- SRLI             xxxxxxxxxxxx             yyyyy              101                zzzzz          0010011
-- SRAI             xxxxxxxxxxxx             yyyyy              101                zzzzz          0010011
-- SLTI             xxxxxxxxxxxx             yyyyy              010                zzzzz          0010011
-- SLTIU            xxxxxxxxxxxx             yyyyy              011                zzzzz          0010011
-- LB               xxxxxxxxxxxx             yyyyy              000                zzzzz          0000011
-- LH               xxxxxxxxxxxx             yyyyy              001                zzzzz          0000011
-- LW               xxxxxxxxxxxx             yyyyy              010                zzzzz          0000011
-- LBU              xxxxxxxxxxxx             yyyyy              100                zzzzz          0000011
-- LHU              xxxxxxxxxxxx             yyyyy              101                zzzzz          0000011
-- JALR             xxxxxxxxxxxx             yyyyy              000                zzzzz          1100111
--
------------------------------------------------  S - TYPE  ------------------------------------------------
--
-- instruction   |31|IMM[11:5]|25|  |24|RS2|20|  |19|RS1|15|  |14|FUNCT3|12|   |11|IMM[4:0]|7|  |6|OPCODE|0|
-- SB                xxxxxxx          yyyyy         zzzzz         000             xxxxx          0100011
-- SH                xxxxxxx          yyyyy         zzzzz         001             xxxxx          0100011
-- SW                xxxxxxx          yyyyy         zzzzz         010             xxxxx          0100011
--
------------------------------------------------  B - TYPE  ------------------------------------------------
--
-- instruction   |31|IMM[12|10:5]|25|  |24|RS2|20|  |19|RS1|15|  |14|FUNCT3|12|   |11|IMM[4:1|11]|7|  |6|OPCODE|0|
-- BEQ                  xxxxxxx            yyyyy         zzzzz         000               xxxxx           1100011
-- BNE                  xxxxxxx            yyyyy         zzzzz         001               xxxxx           1100011
-- BLT                  xxxxxxx            yyyyy         zzzzz         004               xxxxx           1100011
-- BGE                  xxxxxxx            yyyyy         zzzzz         005               xxxxx           1100011
-- BLTU                 xxxxxxx            yyyyy         zzzzz         006               xxxxx           1100011
-- BGEU                 xxxxxxx            yyyyy         zzzzz         007               xxxxx           1100011
--
------------------------------------------------  J - TYPE  ------------------------------------------------
--
-- instruction   |31|imm[20|10:1|11|19:12]|12|              |11|RD|7|        |6|OPCODE|0|
-- JAL               xxxxxxxxxxxxxxxxxxxx                     yyyyy            1101111
--
------------------------------------------------  U - TYPE  ------------------------------------------------
--
-- instruction        |31|imm[31:12]|12|                |11|RD|7|        |6|OPCODE|0|
-- LUI               xxxxxxxxxxxxxxxxxxxx                 zzzzz            0110111
-- AUIPC             xxxxxxxxxxxxxxxxxxxx                 zzzzz            0010111
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
    others => (others => '0')
  );

  --! @brief Array type representing the instruction memory storage.
  subtype t_byte  is std_logic_vector(7 downto 0);
  type t_bytes    is array (natural range <>) of t_byte;

  --! @brief Array representing the data memory storage.
end mem_pkg;

package body mem_pkg is
end package body mem_pkg;
