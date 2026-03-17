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
use ieee.numeric_std.all;

library design_lib;

use design_lib.mem_pkg.all;


--! @brief Instruction fetch unit for the SCore-V processor.
--! @details Wraps the IMEM entity and splits the fetched 32-bit word into
--!          the t_instruction_rec record expected by the rest of the pipeline.
entity fetch_instruction is
  generic
  (
    g_ADDR_WIDTH : integer := 32;
    --! @brief Size of instruction memory in bytes.
    --! @brief Path to the instruction memory initialisation file.
    g_INIT_FILE  : string  := "instruction_memory.txt"
  );
  port
  (
    --! @brief Program counter input - byte address of current instruction.
    instruction_count_i     : in  std_logic_vector(g_ADDR_WIDTH-1 downto 0);
    --! @brief HALT state detected input
    halt_i                  : in  std_logic;
    --! @brief Fetched instruction output split into opcode and remaining bits.
    instruction_bits_o      : out t_instruction_rec;
    --! Instruction fetch address is outside valid instruction memory range
    invalid_instr_addr_o    : out std_logic;
    --! Instruction fetch address is not 4-byte aligned (PC(1 downto 0) /= "00")
    misaligned_instr_addr_o : out std_logic
  );
end fetch_instruction;

architecture arch of fetch_instruction is

  signal full_instruction : std_logic_vector(31 downto 0);

  signal addr_s            : integer;
  signal invalid_addr_s    : std_logic;
  signal misaligned_addr_s : std_logic;

begin

  --! @brief IMEM instantiation - delegates all memory storage and read logic.
  u_imem : entity design_lib.imem
    generic map (
      g_INIT_FILE => g_INIT_FILE
    )
    port map (
      addr_i => instruction_count_i,
      data_o => full_instruction
    );

  instruction_bits_o.opcode                 <= full_instruction(6 downto 0);
  instruction_bits_o.other_instruction_bits <= full_instruction(31 downto 7);

  invalid_instr_addr_o    <= invalid_addr_s;
  misaligned_instr_addr_o <= misaligned_addr_s;

end arch;
