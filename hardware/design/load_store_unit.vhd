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

--! @brief Entity for the Load Store Unit (LSU).
--! @details This unit interfaces with the Data Memory (DMEM) defined in mem_pkg.
--! It supports 32-bit (word) synchronous writes and asynchronous reads.
entity load_store_unit is
  port (
    clk_i        : in  std_logic;                     --! Global clock signal
    rst_i        : in  std_logic;                     --! Asynchronous reset, active high
    addr_i       : in  std_logic_vector(31 downto 0); --! Memory address for access
    mem_RW_i     : in  std_logic;                     --! Read/Write control: '1' for Write, '0' for Read
    data_write_i : in  std_logic_vector(31 downto 0); --! Data to be stored in memory
    data_read_o  : out std_logic_vector(31 downto 0)  --! Data loaded from memory
  );
end load_store_unit;

--! @brief Architecture implementing the LSU logic.
architecture arch of load_store_unit is
  --! Internal signal to hold the 32-bit word assembled from byte-addressable DMEM.
  signal word_to_read : std_logic_vector(31 downto 0);
  signal address : integer;
begin

  --! @brief Concurrent address conversion.
  address <= to_integer(unsigned(addr_i));

  --! @brief 32-bit Word Reconstruction logic.
  --! @details Performs an asynchronous read from DMEM.
  --! @warning Checks if address is within safe bounds (Max Index - 3) to prevent simulation crashes.
  word_to_read <=
  x"00000000" when address > 252 else
  DMEM(address + 3) &
  DMEM(address + 2) &
  DMEM(address + 1) &
  DMEM(address);

  --! @brief Synchronous Store Process.
  --! @details Handles writing 32-bit words into the byte-oriented DMEM array.
  --! The operation is only performed on the rising edge of clk_i when mem_RW_i is active.
  --! @param clk_i Sensitivity to the system clock.
  process(clk_i) is
  begin
    if rising_edge(clk_i) then
      if mem_RW_i = '1' then
        DMEM(to_integer(unsigned(addr_i)))     <= data_write_i(7 downto 0);
        DMEM(to_integer(unsigned(addr_i)) + 1) <= data_write_i(15 downto 8);
        DMEM(to_integer(unsigned(addr_i)) + 2) <= data_write_i(23 downto 16);
        DMEM(to_integer(unsigned(addr_i)) + 3) <= data_write_i(31 downto 24);
      end if;
    end if;
  end process;

  --! @brief Output multiplexer.
  --! @details Drives data_read_o with the loaded word if reading, or zero if writing.
  data_read_o <= word_to_read when mem_RW_i = '0' and rst_i = '0' else (others => '0');
end arch;
