-----------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2025
-- https://github.com/etf-unibl/SCore-V/
-----------------------------------------------------------------------------
--
-- unit name: data memory (DMEM)
--
-- description:
--
--   This file implements the data memory as a separate entity.
--   It is initialised from a hex word file at simulation elaboration time.
--   Memory size is derived automatically from the number of lines in the
--   initialisation file (each line is one 32-bit word, so 4 bytes).
--   Reads are asynchronous; writes are synchronous (rising clock edge).
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


--! @brief Data Memory (DMEM) entity for the SCore-V processor.
--! @details Initialised from a hex word file (one 32-bit word per line) at
--!          elaboration time. Memory size is derived automatically from the
--!          file (lines * 4 bytes). Supports byte-addressed asynchronous
--!          reads and synchronous writes of byte, halfword, or word width.
entity dmem is
  generic
  (
    --! @brief Path to the data memory initialisation file.
    --! @details Each line must contain one 32-bit word as 8 hex chars (e.g. 7D5C0837).
    g_INIT_FILE : string := "data_memory.txt"
  );
  port
  (
    clk_i               : in  std_logic;                     --! Global clock signal
    addr_i              : in  std_logic_vector(31 downto 0); --! Byte address for read/write access
    we_i                : in  std_logic;                     --! Write enable: '1' = write, '0' = read
    width_i             : in  std_logic_vector(1 downto 0);  --! Access width: byte=00, halfword=01, word=1x
    data_write_i        : in  std_logic_vector(31 downto 0); --! Data to write (synchronous)
    data_read_o         : out std_logic_vector(31 downto 0); --! Data read output (asynchronous, zero-extended)
    invalid_addr_o      : out std_logic;                     --! Trying to access out of bounds address
    misaligned_access_o : out std_logic                      --! Trying to access misaligned address
  );
end dmem;

architecture arch of dmem is

  --! @brief Counts non-blank lines in the init file to determine word count.
  impure function count_words(file_name : in string) return integer
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
  end function count_words;

  --! @brief Loads DMEM from a hex word file (one 32-bit word per line) at elaboration.
  impure function initialize_dmem(file_name : in string; mem_size : in integer) return t_bytes
  is
    file     f_ptr  : text;
    variable l      : line;
    variable result : t_bytes(0 to mem_size - 1) := (others => (others => '0'));
    variable word   : std_logic_vector(31 downto 0);
    variable i      : integer := 0;
  begin
    file_open(f_ptr, file_name, read_mode);
    while not endfile(f_ptr) and i < mem_size - 3 loop
      readline(f_ptr, l);
      next when l'length = 0;
      hread(l, word);
      result(i)     := word(7  downto 0);
      result(i + 1) := word(15 downto 8);
      result(i + 2) := word(23 downto 16);
      result(i + 3) := word(31 downto 24);
      i := i + 4;
    end loop;
    file_close(f_ptr);
    return result;
  end function initialize_dmem;

  --! @brief Memory size in bytes derived from the init file at elaboration time.
  constant c_MEM_SIZE : integer := count_words(g_INIT_FILE) * 4;

  --! @brief Byte-addressable data memory array, initialised at elaboration time.
  signal mem : t_bytes(0 to c_MEM_SIZE - 1) := initialize_dmem(g_INIT_FILE, c_MEM_SIZE);

  signal address                  : integer;
  signal memory_bound             : integer;
  signal is_invalid_addr_read     : std_logic := '0';
  signal is_misaligned_addr_read  : std_logic := '0';
  signal is_invalid_addr_write    : std_logic := '0';
  signal is_misaligned_addr_write : std_logic := '0';

begin

  address      <= to_integer(signed(addr_i));
  --memory_bound <= c_MEM_SIZE - 2 when width_i = "00" else
  --                c_MEM_SIZE - 3 when width_i = "01" else
  --                c_MEM_SIZE - 4;

  --! @brief Asynchronous zero-extended read.
  process(address, width_i, mem, addr_i) is
    variable v_result             : std_logic_vector(31 downto 0);
    variable v_is_invalid_addr    : std_logic;
    variable v_is_misaligned_addr : std_logic;
  begin
    result               := (others => '0');
    v_is_invalid_addr    := '0';
    v_is_misaligned_addr := '0';
  case width_i is
    when "00" =>  -- byte
      if address >= 0 and address <= c_MEM_SIZE - 1 then
        result := x"000000" & mem(address);
      else
        v_is_invalid_addr := '1';
      end if;
    when "01" =>  -- halfword
      if address < 0 or address > c_MEM_SIZE - 2 then
        v_is_invalid_addr := '1';
      elsif addr_i(0) /= '0' then
        v_is_misaligned_addr := '1';
      else
        result := x"0000" & mem(address + 1) & mem(address);
      end if;
    when others =>  -- word
      if address < 0 or address > c_MEM_SIZE - 4 then
        v_is_invalid_addr := '1';
      elsif addr_i(1 downto 0) /= "00" then
        v_is_misaligned_addr := '1';
      else
        result := mem(address + 3) & mem(address + 2) &
                  mem(address + 1) & mem(address);
      end if;
  end case;

  data_read_o              <= result;
  is_invalid_addr_read     <= v_is_invalid_addr;
  is_misaligned_addr_read  <= v_is_misaligned_addr;
end process;

  --! @brief Synchronous write.
  process(clk_i) is
    variable v_is_invalid_addr     : std_logic;
    variable v_is_misaligned_addr  : std_logic; 
  begin
    v_is_invalid_addr    := '0';
    v_is_misaligned_addr := '0';

    if rising_edge(clk_i) then
      if we_i = '1' then
        case width_i is
          when "00" => -- byte
            if address >= 0 and address <= c_MEM_SIZE - 1 then
              mem(address) <= data_write_i(7 downto 0);
            else
              v_is_invalid_addr    := '1';
            end if;
          when "01" => -- half
            if address >= 0 and address <= c_MEM_SIZE - 2 then
              if addr_i(0) = '0' then
                mem(address)     <= data_write_i(7 downto 0);
                mem(address + 1) <= data_write_i(15 downto 8);
              else
                v_is_misaligned_addr := '1';
              end if;
            else
              v_is_invalid_addr    := '1';
            end if;
          when others => -- word
            if address >= 0 and address <= c_MEM_SIZE - 4 then
              if addr_i(1 downto 0) = "00" then
                mem(address)     <= data_write_i(7 downto 0);
                mem(address + 1) <= data_write_i(15 downto 8);
                mem(address + 2) <= data_write_i(23 downto 16);
                mem(address + 3) <= data_write_i(31 downto 24);
              else
                v_is_misaligned_addr := '1';
              end if;
            else
              v_is_invalid_addr    := '1';
            end if;
        end case;
      end if;
    end if;

    is_invalid_addr_write     <= v_is_invalid_addr;
    is_misaligned_addr_write  <= v_is_misaligned_addr;
  end process;

  invalid_addr_o      <= is_invalid_addr_read or is_invalid_addr_write;
  misaligned_access_o <= is_misaligned_addr_read or is_misaligned_addr_write;

end arch;
