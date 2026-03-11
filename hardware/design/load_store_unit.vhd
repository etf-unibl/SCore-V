-----------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2025
-- https://github.com/etf-unibl/SCore-V/
-----------------------------------------------------------------------------
--
-- unit name: load store unit (LSU)
--
-- description:
--
--   This file implements load and store operations on DMEM.
--   DMEM is declared as a package-level signal in mem_pkg so that
--   simulation testbenches can read it directly for signature dumps.
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

library design_lib;
use design_lib.mem_pkg.all;

--! @brief Entity for the Load Store Unit (LSU).
--! @details Interfaces with the package-level DMEM signal in mem_pkg.
--!          Supports byte, halfword and word reads (with sign extension)
--!          and synchronous byte, halfword and word writes.
entity load_store_unit is
  generic (
    --! @brief Absolute path to data_memory.txt, set by run.py.
    --! @details Each line must contain one 32-bit word as an 8-digit hex value
    --!          (e.g. 7D5C0837). Used in simulation only.
    g_INIT_FILE : string := "data_memory.txt"
  );
  port (
    clk_i        : in  std_logic;                     --! Global clock signal
    rst_i        : in  std_logic;                     --! Asynchronous reset, active high
    sign_i       : in  std_logic;                     --! '1' = unsigned read, '0' = signed read
    width_i      : in  std_logic_vector(1 downto 0);  --! Access width: byte=00, halfword=01, word=10
    addr_i       : in  std_logic_vector(31 downto 0); --! Byte address for the memory access
    mem_RW_i     : in  std_logic;                     --! '1' = write, '0' = read
    data_write_i : in  std_logic_vector(31 downto 0); --! Data to write to memory
    data_read_o  : out std_logic_vector(31 downto 0)  --! Data read from memory
  );
end load_store_unit;

--! @brief Architecture implementing the LSU logic.
architecture arch of load_store_unit is

  signal word_to_read : std_logic_vector(31 downto 0);
  signal address      : integer;
  signal memory_bound : integer;

  --! @brief Initialise the package-level DMEM from data_memory.txt at elaboration time.
  --! @details Each line contains one 32-bit word as 8 hex chars (e.g. 7D5C0837).
  --!          The word is stored in little-endian byte order:
  --!            DMEM(base+0) = bits  7:0  (LSB)
  --!            DMEM(base+1) = bits 15:8
  --!            DMEM(base+2) = bits 23:16
  --!            DMEM(base+3) = bits 31:24 (MSB)
  --! @param file_name Absolute path to data_memory.txt.
  --! @return Populated t_bytes array sized to c_TOTAL_BYTES_DMEM.
  impure function initialize_dmem(file_name : in string) return t_bytes
  is
    file     f_ptr  : text;
    variable l      : line;
    variable result : t_bytes(0 to c_TOTAL_BYTES_DMEM - 1) := (others => (others => '0'));
    variable word   : std_logic_vector(31 downto 0);
    variable i      : integer := 0;
  begin
    file_open(f_ptr, file_name, read_mode);
    while not endfile(f_ptr) and i < c_TOTAL_BYTES_DMEM - 3 loop
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

begin

  --! @brief Initialise package-level DMEM from file at elaboration time.
  DMEM <= initialize_dmem(g_INIT_FILE);

  address      <= to_integer(signed(addr_i));
  memory_bound <= c_TOTAL_BYTES_DMEM - 2 when width_i = "00" else
                  c_TOTAL_BYTES_DMEM - 3 when width_i = "01" else
                  c_TOTAL_BYTES_DMEM - 4;

  --! @brief Asynchronous read with sign extension.
  process(address, sign_i, width_i, mem_RW_i, DMEM) is
    variable word_to_read_var : std_logic_vector(31 downto 0);
  begin
    if address >= 0 and address <= memory_bound then
      case width_i is
        when "00" =>
          if sign_i = '1' then
            word_to_read_var := x"000000" & DMEM(address);
          else
            word_to_read_var := (31 downto 8 => DMEM(address)(7)) & DMEM(address);
          end if;
        when "01" =>
          if sign_i = '1' then
            word_to_read_var := x"0000" & DMEM(address + 1) & DMEM(address);
          else
            word_to_read_var := (31 downto 16 => DMEM(address + 1)(7)) & DMEM(address + 1) & DMEM(address);
          end if;
        when others =>
          word_to_read_var := DMEM(address + 3) &
                              DMEM(address + 2) &
                              DMEM(address + 1) &
                              DMEM(address);
      end case;
    else
      word_to_read_var := (others => '0');
    end if;
    word_to_read <= word_to_read_var;
  end process;

  --! @brief Synchronous write process.
  process(rst_i, clk_i) is
  begin
    if rst_i = '1' then
      null;
    elsif rising_edge(clk_i) then
      if mem_RW_i = '1' and address >= 0 and address <= c_TOTAL_BYTES_DMEM - 4 then
        case width_i is
          when "00" =>
            DMEM(address)     <= data_write_i(7  downto 0);
          when "01" =>
            DMEM(address)     <= data_write_i(7  downto 0);
            DMEM(address + 1) <= data_write_i(15 downto 8);
          when others =>
            DMEM(address)     <= data_write_i(7  downto 0);
            DMEM(address + 1) <= data_write_i(15 downto 8);
            DMEM(address + 2) <= data_write_i(23 downto 16);
            DMEM(address + 3) <= data_write_i(31 downto 24);
        end case;
      end if;
    end if;
  end process;

  data_read_o <= word_to_read when mem_RW_i = '0' and rst_i = '0' else (others => '0');

end arch;
