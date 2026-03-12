-----------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2025
-- https://github.com/etf-unibl/SCore-V/
-----------------------------------------------------------------------------
--
-- unit name: instruction memory (IMEM)
--
-- description:
--
--   This file implements the instruction memory as a separate entity.
--   It is initialised from a hex byte file at simulation elaboration time
--   and provides asynchronous (combinational) read access.
--   Memory size is derived automatically from the number of lines in the
--   initialisation file.
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


--! @brief Instruction Memory (IMEM) entity for the SCore-V processor.
--! @details Initialised from a hex byte file (one byte per line) at
--!          elaboration time. Memory size is derived automatically from
--!          the file. Provides asynchronous 32-bit word read access via
--!          a byte address input.
entity imem is
  generic
  (
    --! @brief Path to the instruction memory initialisation file.
    --! @details Each line must contain one byte as a 2-digit hex value (e.g. 37).
    g_INIT_FILE : string := "instruction_memory.txt"
  );
  port
  (
    --! @brief Byte address of the instruction to read.
    addr_i : in  std_logic_vector(31 downto 0);
    --! @brief 32-bit instruction word at addr_i (asynchronous).
    data_o : out std_logic_vector(31 downto 0)
  );
end imem;

architecture arch of imem is

  --! @brief Counts non-blank lines in the init file to determine memory size.
  impure function count_bytes(file_name : in string) return integer
  is
    file     f_ptr : text;
    variable l     : line;
    variable n     : integer := 0;
  begin
    file_open(f_ptr, file_name, read_mode);
    while not endfile(f_ptr) loop
      readline(f_ptr, l);
      if l'length > 0 then
        n := n + 1;
      end if;
    end loop;
    file_close(f_ptr);
    return n;
  end function count_bytes;

  --! @brief Loads IMEM from a hex byte file (one byte per line) at elaboration.
  impure function initialize_memory(file_name : in string; mem_size : in integer) return t_bytes
  is
    file     f_ptr  : text;
    variable l      : line;
    variable result : t_bytes(0 to mem_size - 1) := (others => (others => '0'));
    variable temp   : std_logic_vector(7 downto 0);
    variable i      : integer := 0;
  begin
    file_open(f_ptr, file_name, read_mode);
    while not endfile(f_ptr) and i < mem_size loop
      readline(f_ptr, l);
      next when l'length = 0;
      hread(l, temp);
      result(i) := temp;
      i := i + 1;
    end loop;
    file_close(f_ptr);
    return result;
  end function initialize_memory;

  --! @brief Memory size derived from the init file at elaboration time.
  constant c_MEM_SIZE : integer := count_bytes(g_INIT_FILE);

  --! @brief Instruction memory contents, initialised at elaboration time.
  constant c_MEM : t_bytes(0 to c_MEM_SIZE - 1) := initialize_memory(g_INIT_FILE, c_MEM_SIZE);

begin

  --! @brief Asynchronous little-endian 32-bit read.
  data_o <= c_MEM(to_integer(unsigned(addr_i)) + 3) &
            c_MEM(to_integer(unsigned(addr_i)) + 2) &
            c_MEM(to_integer(unsigned(addr_i)) + 1) &
            c_MEM(to_integer(unsigned(addr_i)));

end arch;
