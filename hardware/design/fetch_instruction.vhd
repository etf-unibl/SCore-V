-----------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2025
-- https://github.com/etf-unibl/SCore-V/
-----------------------------------------------------------------------------
--
-- unit name: instruction fetch unit
--
-- description:
--
--   This file implements a simple instruction fetch logic.
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
use work.mem_pkg.all;
use ieee.numeric_std.all;

--! @brief Entity for fetching instructions from memory.
--! @details This module maps a numerical index to a structured instruction record.
entity fetch_instruction is

  generic
  (
    --! Width of the instruction address bus.
    g_ADDR_WIDTH      : integer := 32
  );
  port
  (
  instruction_count_i : in  unsigned(g_ADDR_WIDTH-1 downto 0); --! program counter which has a step of 4
  instruction_bits_o  : out t_instruction_rec                  --! instruction consisting of opcode and the rest of the bits
  );

end fetch_instruction;


--! @brief Architecture implementing the combinational lookup logic.
architecture arch of fetch_instruction is
  signal full_instruction : std_logic_vector(31 downto 0);
begin

  --! @brief Asynchronous memory read.
  --! @details Accesses the c_IMEM array defined in mem_pkg.
  full_instruction <= c_IMEM(to_integer(instruction_count_i) + 3) &
                      c_IMEM(to_integer(instruction_count_i) + 2) &
                      c_IMEM(to_integer(instruction_count_i) + 1) &
                      c_IMEM(to_integer(instruction_count_i));
  instruction_bits_o.opcode                 <= full_instruction(6 downto 0);
  instruction_bits_o.other_instruction_bits <= full_instruction(31 downto 7);

end arch;
