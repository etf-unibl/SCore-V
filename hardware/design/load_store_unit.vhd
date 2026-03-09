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
use work.mem_pkg.all;

use std.textio.all;

use ieee.std_logic_textio.all;

--! @brief Entity for the Load Store Unit (LSU).
--! @details This unit interfaces with the Data Memory (DMEM) defined in mem_pkg.
--! It supports 32-bit (word) synchronous writes and asynchronous reads.
entity load_store_unit is
  generic (
    --! @brief Absolute path to data_memory.txt, set by run.py.
    --! @details Each line must contain one byte as a 2-digit hex value.
    --!          Used in simulation only - Quartus ignores this.
    g_INIT_FILE : string := "data_memory.txt"
  );
  port (
    clk_i               : in  std_logic;                     --! Global clock signal
    rst_i               : in  std_logic;                     --! Asynchronous reset, active high
    sign_i              : in  std_logic;                     --! Bit telling the sign of the data to be read
                                                             --! (1 = unsigned, 0 = signed)
    width_i             : in  std_logic_vector(1 downto 0);  --! Type of the data to be read (byte=00, halfword=01, word=10)
    addr_i              : in  std_logic_vector(31 downto 0); --! Memory address for access
    mem_RW_i            : in  std_logic;                     --! Read/Write control: '1' for Write, '0' for Read
    data_write_i        : in  std_logic_vector(31 downto 0); --! Data to be stored in memory
    data_read_o         : out std_logic_vector(31 downto 0); --! Data loaded from memory
    invalid_addr_o      : out std_logic;                     --! Trying to access out-of-bounds address
    misaligned_access_o : out std_logic                      --! Trying to access misaligned address
  );
end load_store_unit;

--! @brief Architecture implementing the LSU logic.
architecture arch of load_store_unit is
  --! Internal signal to hold the 32-bit word assembled from byte-addressable DMEM.
  signal word_to_read : std_logic_vector(31 downto 0);
  signal address      : integer;

  --! @brief Loads DMEM from a hex byte file at elaboration time.
  --! @param file_name Absolute path to data_memory.txt.
  --! @return Populated t_bytes array.
  --! @brief Loads DMEM from a hex byte file at elaboration time.
  --! @details Each line must contain one byte as a 2-digit hex value (e.g. FF).
  --!          SIMULATION ONLY - Quartus ignores this function.
  --! @param file_name Absolute path to data_memory.txt.
  --! @return Populated t_bytes array.
  impure function initialize_dmem(file_name : in string) return t_bytes
  is
    file     f_ptr  : text;
    variable l      : line;
    variable result : t_bytes := (others => (others => '0'));
    variable temp   : std_logic_vector(7 downto 0);
  begin
    file_open(f_ptr, file_name, read_mode);
    for i in 0 to c_TOTAL_BYTES - 1 loop
      exit when endfile(f_ptr);
      readline(f_ptr, l);
      hread(l, temp);
      result(i) := temp;
    end loop;
    file_close(f_ptr);
    return result;
  end function initialize_dmem;

  --! @brief Data memory array initialised from file at elaboration time.
  signal DMEM                 : t_bytes := initialize_dmem(g_INIT_FILE);
  signal memory_bound         : integer;
  signal is_invalid_addr      : std_logic;
  signal is_misaligned_addr   : std_logic;
begin
  --! @brief Concurrent address conversion.
  address <= to_integer(signed(addr_i));
  memory_bound <= c_TOTAL_BYTES - 1 when width_i = "00" else
                  c_TOTAL_BYTES - 2 when width_i = "01" else
                  c_TOTAL_BYTES - 4;

  is_invalid_addr <= '1' when address < 0 or address > memory_bound else '0';

  --! @brief Misaligned address detection process
  --! @details Checks if the requested memory access is misaligned based on the data width:
  --!  - **Byte (00)**: always aligned, no restriction.
  --!  - **Halfword (01)**: must be aligned to 2 bytes -> address bit 0 must be 0.
  --!  - **Word (10, 11)**: must be aligned to 4 bytes -> address bits 1 downto 0 must be "00".
  --!  - Sets 'is_misaligned_addr' signal to '1' if misaligned, otherwise '0'.
  process(address, width_i)
  begin
    case width_i is
      when "01" => --! Halfword
        is_misaligned_addr <= addr_i(0);
      when "10" | "11" => --! Word
        if addr_i(1 downto 0) /= "00" then
          is_misaligned_addr <= '1';
        else
          is_misaligned_addr <= '0';
        end if;
      when others => --! Byte is always aligned
        is_misaligned_addr <= '0';
    end case;
  end process;

  --! @brief Data Read and Sign Extension Logic.
  --! @details Performs an asynchronous read from the byte-addressable DMEM.
  --! The process formats the output based on the requested data width and sign:
  --! - **Byte (00)**: Loads 8 bits. Sign-extends if sign_i = '0', zero-extends if sign_i = '1'.
  --! - **Halfword (01)**: Loads 16 bits. Sign-extends if sign_i = '0', zero-extends if sign_i = '1'.
  --! - **Word (10)**: Loads 32 bits directly from four consecutive memory locations.
  --! width_i = 11 is interpreted the same way as the width_i = 10.
  --! @note This process is combinatorial and updates whenever address, control signals, or memory content changes.
  --! @warning Validates that the address is within [0, memory_bound] to prevent out-of-bounds array access during simulation.
  process(address, sign_i, width_i, mem_RW_i, DMEM, is_invalid_addr, is_misaligned_addr) is
    variable word_to_read_var : std_logic_vector(31 downto 0);
  begin
    if is_invalid_addr = '0' and is_misaligned_addr = '0' then
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

  --! @brief Synchronous Store Process.
  --! @details Handles writing 32-bit words into the byte-oriented DMEM array.
  --! The operation is only performed on the rising edge of clk_i when mem_RW_i is active.
  --! @param clk_i Sensitivity to the system clock.
  process(rst_i, clk_i) is
  begin
    if rst_i = '1' then
    --! Empty
    elsif rising_edge(clk_i) then
      if mem_RW_i = '1' and is_misaligned_addr = '0' and is_invalid_addr = '0' then
        case width_i is
          when "00" => --! STORE BYTE (SB)
            DMEM(address)     <= data_write_i(7 downto 0);
          when "01" => --! STORE HALFWORD (SH)
            DMEM(address)     <= data_write_i(7 downto 0);
            DMEM(address + 1) <= data_write_i(15 downto 8);
          when others => --! STORE WORD (SW)
            DMEM(address)     <= data_write_i(7 downto 0);
            DMEM(address + 1) <= data_write_i(15 downto 8);
            DMEM(address + 2) <= data_write_i(23 downto 16);
            DMEM(address + 3) <= data_write_i(31 downto 24);
        end case;
      end if;
    end if;
  end process;

  --! @brief Output multiplexer.
  --! @details Drives data_read_o with the loaded word if reading, or zero if writing.
  data_read_o         <= word_to_read when mem_RW_i = '0' and rst_i = '0' else (others => '0');

  invalid_addr_o      <= is_invalid_addr;
  misaligned_access_o <= is_misaligned_addr;
end arch;
