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
library vunit_lib;
context vunit_lib.vunit_context;
library design_lib;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use design_lib.mem_pkg.all;

--! @brief Top-level entity for the fetch instruction testbench.
--! @details As a testbench, this entity has no ports.
entity fetch_instruction_tb is
  generic (
    runner_cfg  : string;
    --! @brief Absolute path to instruction_memory.txt, set by run.py.
    g_init_file : string := "instruction_memory.txt"
  );
end fetch_instruction_tb;

--! @brief Architecture implementing the stimulus and verification logic.
architecture arch of fetch_instruction_tb is

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

  --! @brief Loads golden IMEM reference (one hex byte per line).
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
  constant c_MEM_SIZE : integer := count_bytes(g_init_file);

  --! @brief Golden reference IMEM, sized from the file.
  constant c_IMEM : t_bytes(0 to c_MEM_SIZE - 1) := initialize_memory(g_init_file, c_MEM_SIZE);

  signal test_in                 : std_logic_vector(31 downto 0);
  signal test_out                : t_instruction_rec;
  signal halt_s                  : std_logic := '0';
  signal invalid_instr_addr_s    : std_logic := '0';
  signal misaligned_instr_addr_s : std_logic := '0';

begin

  --! @brief UUT instantiation and port mapping.
  uut_fetch_instruction : entity design_lib.fetch_instruction
    generic map (
      g_INIT_FILE => g_init_file
    )
    port map (
      instruction_count_i     => test_in,
      halt_i                  => halt_s,
      instruction_bits_o      => test_out,
      invalid_instr_addr_o    => invalid_instr_addr_s,
      misaligned_instr_addr_o => misaligned_instr_addr_s
    );

  main : process
    variable full_instruction : std_logic_vector(31 downto 0);
    variable addr_int         : integer;
  begin
    test_runner_setup(runner, runner_cfg);

    while test_suite loop
      if run("test_fetch_instruction") then
        for i in 0 to 16 loop
          if i mod 4 = 0 then
            test_in <= std_logic_vector(to_unsigned(i, 32));
            wait for 100 ns;
          end if;
          addr_int := to_integer(unsigned(test_in));
          full_instruction := c_IMEM(addr_int + 3) &
                              c_IMEM(addr_int + 2) &
                              c_IMEM(addr_int + 1) &
                              c_IMEM(addr_int) when (addr_int < c_MEM_SIZE - 3) else (others => '0');
          check_equal(test_out.opcode, full_instruction(6 downto 0),
                    "Opcode mismatch at index " & integer'image(addr_int));
          check_equal(test_out.other_instruction_bits, full_instruction(31 downto 7),
                    "Data bits mismatch at index " & integer'image(addr_int));
        end loop;

      elsif run("test_exceptions_in_fetch_instr") then

        --! HALT state detected test
        halt_s  <= '1';
        if c_MEM_SIZE >= 4 then
          test_in <= std_logic_vector(to_unsigned(0, 32));
          wait for 10 ns;
          check_equal(test_out.opcode, std_logic_vector(to_unsigned(0, 7)), 
                     "Opcode should be 0 when halted");
          check_equal(test_out.other_instruction_bits, std_logic_vector(to_unsigned(0, 25)), 
                     "Data should be 0 when halted");
        else
          info("Empty instruction memory.");
        end if;

        --! Reset after HALT state test
        halt_s   <= '0';
        if c_MEM_SIZE >= 4 then
          test_in  <= std_logic_vector(to_unsigned(0, 32));
          wait for 0 ns;  -- let signal assignments propagate before reading test_in
          addr_int := to_integer(unsigned(test_in));
          full_instruction := c_IMEM(addr_int + 3) &
                              c_IMEM(addr_int + 2) &
                              c_IMEM(addr_int + 1) &
                              c_IMEM(addr_int) when (addr_int < c_MEM_SIZE - 3) else (others => '0');
          wait for 10 ns;
          check_equal(test_out.opcode, full_instruction(6 downto 0),
                     "Opcode mismatch at index " & integer'image(addr_int));
          check_equal(test_out.other_instruction_bits, full_instruction(31 downto 7),
                     "Data bits mismatch at index " & integer'image(addr_int));          
          check_equal(invalid_instr_addr_s, '0', 
                     "Invalid instruction address flag should be '0' after active reset");
          check_equal(misaligned_instr_addr_s, '0', 
                     "Misaligned instruction address flag should be '0' after active reset");
        else
          info("Empty instruction memory.");
        end if;

        --! Misaligned instruction address access test and out of boundaries instruction address

        for i in 0 to c_MEM_SIZE - 1 loop
          addr_int := i;
          test_in  <= std_logic_vector(to_unsigned(addr_int, 32));
          wait for 10 ns;
        
          if i <= c_MEM_SIZE - 4 then
            check_equal(invalid_instr_addr_s, '0',
                        "Invalid instruction address flag should be '0' at index " & integer'image(addr_int));
            if i mod 4 = 0 then
              check_equal(misaligned_instr_addr_s, '0',
                          "Misaligned instruction address flag should be '0' for aligned address at index " & integer'image(addr_int));
              full_instruction := c_IMEM(addr_int + 3) &
                              c_IMEM(addr_int + 2) &
                              c_IMEM(addr_int + 1) &
                              c_IMEM(addr_int) when (addr_int < c_MEM_SIZE - 3) else (others => '0');
              wait for 10 ns;
              check_equal(test_out.opcode, full_instruction(6 downto 0),
                         "Opcode mismatch at index " & integer'image(addr_int));
              check_equal(test_out.other_instruction_bits, full_instruction(31 downto 7),
                         "Data bits mismatch at index " & integer'image(addr_int));
            else
              check_equal(misaligned_instr_addr_s, '1',
                          "Misaligned instruction address flag should be '1' for misaligned address at index " & integer'image(addr_int));
              full_instruction := (others => '0');
              wait for 10 ns;
              check_equal(test_out.opcode, full_instruction(6 downto 0),
                         "Opcode mismatch at index " & integer'image(addr_int));
              check_equal(test_out.other_instruction_bits, full_instruction(31 downto 7),
                         "Data bits mismatch at index " & integer'image(addr_int));

            end if;
          else
            check_equal(invalid_instr_addr_s, '1',
                        "Invalid instruction address flag should be '1' at index " & integer'image(addr_int));
            
            full_instruction := (others => '0');
              wait for 10 ns;
              check_equal(test_out.opcode, full_instruction(6 downto 0),
                         "Opcode mismatch at index " & integer'image(addr_int));
              check_equal(test_out.other_instruction_bits, full_instruction(31 downto 7),
                         "Data bits mismatch at index " & integer'image(addr_int));

            if i mod 4 = 0 then
              check_equal(misaligned_instr_addr_s, '0',
                          "Misaligned instruction address flag should be '0' for aligned invalid address at index " & integer'image(addr_int));
              
              full_instruction := (others => '0');
              wait for 10 ns;
              check_equal(test_out.opcode, full_instruction(6 downto 0),
                         "Opcode mismatch at index " & integer'image(addr_int));
              check_equal(test_out.other_instruction_bits, full_instruction(31 downto 7),
                         "Data bits mismatch at index " & integer'image(addr_int));

            else
              check_equal(misaligned_instr_addr_s, '1',
                          "Misaligned instruction address flag should be '1' for misaligned invalid address at index " & integer'image(addr_int));
              full_instruction := (others => '0');
              wait for 10 ns;
              check_equal(test_out.opcode, full_instruction(6 downto 0),
                         "Opcode mismatch at index " & integer'image(addr_int));
              check_equal(test_out.other_instruction_bits, full_instruction(31 downto 7),
                         "Data bits mismatch at index " & integer'image(addr_int));
            end if;
          end if;
        end loop;

      end if;
    end loop;

    test_runner_cleanup(runner);
  end process;

end arch;
