-----------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2025
-- https://github.com/etf-unibl/SCore-V/
-----------------------------------------------------------------------------
--
-- unit name: instruction fetch testbench unit
--
-- description:
--
--   This file implements a simple testbench file for the instruction fetch logic.
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
use ieee.std_logic_textio.all;
use work.mem_pkg.all;

library vunit_lib;
context vunit_lib.vunit_context;

--! @brief Top-level entity for the fetch instruction testbench.
--! @details Accepts runner_cfg (required by VUnit) and g_init_file
--!          (absolute path to instruction_memory.txt, set by run.py)
--!          so GHDL can find the file regardless of working directory.
entity fetch_instruction_tb is
  generic (
    --! @brief VUnit runner configuration - required by VUnit framework.
    runner_cfg  : string;
    --! @brief Absolute path to instruction_memory.txt.
    --! @details Set by run.py via tb.set_generic(). Forwarded to both
    --!          the UUT and the local golden reference signal.
    g_init_file : string := "instruction_memory.txt"
  );
end fetch_instruction_tb;

--! @brief Architecture implementing the stimulus and verification logic.
architecture arch of fetch_instruction_tb is

  --! @brief Component declaration for the Unit Under Test (UUT).
  component fetch_instruction
    generic (
      g_ADDR_WIDTH : integer := 32;
      g_INIT_FILE  : string  := "instruction_memory.txt"
    );
    port (
      instruction_count_i : in  std_logic_vector(31 downto 0);
      instruction_bits_o  : out t_instruction_rec
    );
  end component;

  -- ----------------------------------------------------------------
  --  Local initialize_memory - identical to the function inside
  --  fetch_instruction.vhd. Used to build the golden reference so
  --  the checker can compare UUT output against known-good values.
  -- ----------------------------------------------------------------
  --! @brief Loads instruction memory from a binary text file.
  --! @param file_name Absolute path to the instruction memory text file.
  --! @return Populated t_bytes array with instruction data.
  impure function initialize_memory(file_name : in string) return t_bytes is
    file     f_ptr            : text;
    variable l                : line;
    variable result           : t_bytes := (others => (others => '0'));
    variable temp             : std_logic_vector(31 downto 0);
    variable v_max_word_index : integer := (c_TOTAL_BYTES / 4) - 1;
  begin
    file_open(f_ptr, file_name, read_mode);
    for i in 0 to v_max_word_index loop
      if not endfile(f_ptr) then
        readline(f_ptr, l);
        read(l, temp);
        result(i*4)     := temp(7  downto 0);
        result(i*4 + 1) := temp(15 downto 8);
        result(i*4 + 2) := temp(23 downto 16);
        result(i*4 + 3) := temp(31 downto 24);
      else
        exit;
      end if;
    end loop;
    file_close(f_ptr);
    return result;
  end function initialize_memory;

  --! @brief Golden reference memory loaded from the same file as the UUT.
  --! @details The checker process compares UUT output against this signal.
  signal c_IMEM : t_bytes := initialize_memory(g_init_file);

  signal test_in  : std_logic_vector(31 downto 0);
  signal test_out : t_instruction_rec;

begin

  --! @brief UUT instantiation.
  --! @details Forwards g_init_file so UUT and testbench read the same file.
  uut : fetch_instruction
    generic map (
      g_ADDR_WIDTH => 32,
      g_INIT_FILE  => g_init_file
    )
    port map (
      instruction_count_i => test_in,
      instruction_bits_o  => test_out
    );

  --! @brief Main test process.
  --! @details Drives addresses and checks UUT output against golden reference.
  process
    variable full_instruction : std_logic_vector(31 downto 0);
    variable addr_int         : integer;
  begin
    test_runner_setup(runner, runner_cfg);

    --! Stimulus and checker - cycles through four addresses.
    for addr in (0, 4, 8, 16) loop
      test_in <= std_logic_vector(to_unsigned(addr, 32));
      wait for 200 ns;

      addr_int := addr;
      full_instruction := c_IMEM(addr_int + 3) &
                          c_IMEM(addr_int + 2) &
                          c_IMEM(addr_int + 1) &
                          c_IMEM(addr_int);

      check_equal(test_out.opcode, full_instruction(6 downto 0),
        "Opcode mismatch at address " & integer'image(addr_int));

      check_equal(test_out.other_instruction_bits, full_instruction(31 downto 7),
        "Instruction bits mismatch at address " & integer'image(addr_int));
    end loop;

    test_runner_cleanup(runner);
  end process;

end arch;
