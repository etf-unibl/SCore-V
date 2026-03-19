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

library design_lib;
use design_lib.mem_pkg.all;

--! @brief Entity for the Load Store Unit (LSU).
--! @details Wraps the DMEM entity and adds sign/zero-extension on loads
--!          and reset/mux logic on the output.
entity load_store_unit is
  generic (
    --! @brief Absolute path to data_memory.txt (one 32-bit hex word per line).
    g_INIT_FILE : string := "data_memory.txt"
  );
  port (
    mem_en_i            : in std_logic;
    clk_i               : in  std_logic;                     --! Global clock signal
    rst_i               : in  std_logic;                     --! Asynchronous reset, active high
    sign_i              : in  std_logic;                     --! '1' = unsigned (zero-extend), '0' = signed (sign-extend)
    width_i             : in  std_logic_vector(1 downto 0);  --! byte=00, halfword=01, word=1x
    addr_i              : in  std_logic_vector(31 downto 0); --! Memory address for access
    mem_RW_i            : in  std_logic;                     --! '1' = Write, '0' = Read
    data_write_i        : in  std_logic_vector(31 downto 0); --! Data to store
    data_read_o         : out std_logic_vector(31 downto 0); --! Data loaded from memory
    invalid_addr_o      : out std_logic;                     --! Trying to access out of bounds address 
    misaligned_access_o : out std_logic                      --! Trying to access misaligned address
  );
end load_store_unit;

architecture arch of load_store_unit is

  --! @brief Raw word read back from DMEM (no sign extension yet).
  signal raw_data            : std_logic_vector(31 downto 0);
  --! @brief Sign/zero-extended word ready for the pipeline.
  signal word_to_read        : std_logic_vector(31 downto 0);
  --! @brief Exception handling flags
  signal invalid_addr_s      : std_logic := '0';
  signal misaligned_access_s : std_logic := '0';

begin

  --! @brief DMEM instantiation.
  u_dmem : entity design_lib.dmem
    generic map (
      g_INIT_FILE => g_INIT_FILE
    )
    port map (
      clk_i               => clk_i,
      rst_i               => rst_i,
      addr_i              => addr_i,
      we_i                => mem_RW_i,
      width_i             => width_i,
      data_write_i        => data_write_i,
      data_read_o         => raw_data,
      invalid_addr_o      => invalid_addr_s,
      misaligned_access_o => misaligned_access_s
    );

  --! @brief Sign / zero extension on the raw byte or halfword read from DMEM.
  --! @details DMEM always returns zero-extended values; LSU applies sign
  --!          extension here when sign_i = '0'.
  process(raw_data, sign_i, width_i) is
  begin
    case width_i is
      when "00" =>  -- byte
        if sign_i = '1' then
          word_to_read <= x"000000" & raw_data(7 downto 0);
        else
          word_to_read <= (31 downto 8 => raw_data(7)) & raw_data(7 downto 0);
        end if;
      when "01" =>  -- halfword
        if sign_i = '1' then
          word_to_read <= x"0000" & raw_data(15 downto 0);
        else
          word_to_read <= (31 downto 16 => raw_data(15)) & raw_data(15 downto 0);
        end if;
      when others =>  -- word
        word_to_read <= raw_data;
    end case;
  end process;

  --! @brief Output mux: zero during reset or when writing.
  data_read_o         <= word_to_read when mem_RW_i = '0' and rst_i = '0' else (others => '0');

  invalid_addr_o      <= invalid_addr_s      when mem_en_i = '1' else '0';
  misaligned_access_o <= misaligned_access_s when mem_en_i = '1' else '0';

end arch;
