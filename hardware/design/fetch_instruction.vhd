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
use std.textio.all;

library design_lib;

use design_lib.mem_pkg.all;


--! @brief Instruction fetch unit for the SCore-V processor.
--! @details Reads a binary instruction file at simulation elaboration time
--!          and provides asynchronous instruction word output based on the
--!          current program counter address. The memory array is local to
--!          this architecture so Quartus can infer MLAB storage instead of
--!          consuming ALMs. For synthesis, replace g_INIT_FILE with a .mif
--!          file and add the ram_init_file attribute.
entity fetch_instruction is
  generic
  (
    g_ADDR_WIDTH : integer := 32;
    --! @brief Path to the instruction memory initialisation file.
    --! @details Used in simulation only. Each line must contain one
    --!          32-bit binary word. Ignored by Quartus at synthesis.
    g_INIT_FILE  : string  := "instruction_memory.txt"
  );
  port
  (
    --! @brief Program counter input - byte address of current instruction.
    instruction_count_i : in  std_logic_vector(g_ADDR_WIDTH-1 downto 0);
    --! @brief Fetched instruction output split into opcode and remaining bits.
    instruction_bits_o  : out t_instruction_rec
  );
end fetch_instruction;

--! @brief RTL architecture for the instruction fetch unit.
--! @details Contains the instruction memory array and the asynchronous
--!          read logic. The initialize_memory function is defined locally
--!          so that both Quartus and ModelSim accept the impure function
--!          call as a signal initializer without elaboration order issues.
architecture arch of fetch_instruction is

  --! @brief Loads instruction memory from a binary text file.
  --! @details Called once at elaboration time (simulation time = 0) to
  --!          populate the local mem signal. Each line of the file must
  --!          contain exactly one 32-bit binary word. Bytes are stored
  --!          in little-endian order: bits 7:0 of the word go to byte i*4,
  --!          bits 15:8 to i*4+1, bits 23:16 to i*4+2, bits 31:24 to i*4+3.
  --!          This function is simulation-only - Quartus ignores it and
  --!          uses the ram_init_file attribute instead.
  --! @param file_name Path to the instruction memory text file.
  --! @return Populated t_bytes array with instruction data.
  --! @brief Loads instruction memory from a hex byte file.
  --! @details Each line must contain exactly one byte as a 2-digit hex value
  --!          (e.g. 37). Bytes are stored sequentially so that the 32-bit
  --!          instruction at word index i is assembled little-endian from
  --!          bytes i*4 .. i*4+3. Simulation only.
  --! @param file_name Absolute path to instruction_memory.txt.
  --! @return Populated t_bytes array sized to c_TOTAL_BYTES_IMEM.
  impure function initialize_memory(file_name : in string) return t_bytes
  is
    file     f_ptr  : text;
    variable l      : line;
    variable result : t_bytes(0 to c_TOTAL_BYTES_IMEM - 1) := (others => (others => '0'));
    variable temp   : std_logic_vector(7 downto 0);
    variable i      : integer := 0;
  begin
    file_open(f_ptr, file_name, read_mode);
    while not endfile(f_ptr) and i < c_TOTAL_BYTES_IMEM loop
      readline(f_ptr, l);
      next when l'length = 0;
      hread(l, temp);
      result(i) := temp;
      i := i + 1;
    end loop;
    file_close(f_ptr);
    return result;
  end function initialize_memory;

  --! @brief Instruction memory array sized to c_TOTAL_BYTES_IMEM.
  --! @details Initialised from g_INIT_FILE at elaboration time in simulation.
  signal mem : t_bytes(0 to c_TOTAL_BYTES_IMEM - 1) := initialize_memory(g_INIT_FILE);

  signal full_instruction : std_logic_vector(31 downto 0);

begin

  --! @brief Asynchronous read from local mem signal.
  --! @description Behaviour identical to original c_IMEM read in mem_pkg.
  full_instruction <= mem(to_integer(unsigned(instruction_count_i)) + 3) &
                      mem(to_integer(unsigned(instruction_count_i)) + 2) &
                      mem(to_integer(unsigned(instruction_count_i)) + 1) &
                      mem(to_integer(unsigned(instruction_count_i)));

  instruction_bits_o.opcode                 <= full_instruction(6 downto 0);
  instruction_bits_o.other_instruction_bits <= full_instruction(31 downto 7);

end arch;
