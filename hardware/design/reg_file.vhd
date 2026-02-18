-----------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2025
-- https://github.com/etf-unibl/SCore-V.git
-----------------------------------------------------------------------------
--
-- unit name:     reg_file
--
-- description:
--
--   Standard RISC-V register file with x0 hardwired to zero.
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

--! @brief Register File module for RV32I processor.
--! @details This module implements 32 general-purpose 32-bit registers.
--! It supports dual asynchronous reads and a single synchronous write.
--! Register x0 is hardwired to zero.
entity reg_file is
  port (
    clk_i        : in  std_logic;                     --! System clock signal
    reg_write_i  : in  std_logic;                     --! Write enable control signal
    rs1_addr_i   : in  std_logic_vector(4 downto 0);  --! Address for source register 1
    rs2_addr_i   : in  std_logic_vector(4 downto 0);  --! Address for source register 2
    rd_addr_i    : in  std_logic_vector(4 downto 0);  --! Address for destination register
    rd_data_i    : in  std_logic_vector(31 downto 0); --! Data to be written to destination register
    rs1_data_o   : out std_logic_vector(31 downto 0); --! Output data from source register 1
    rs2_data_o   : out std_logic_vector(31 downto 0)  --! Output data from source register 2
  );
end reg_file;

--! @brief RTL implementation of the Register File.
--! @details Accesses the regs defined in mem_pkg.
architecture arch of reg_file is
begin

  --! Read logic for rs1: returns zero if address is 0, otherwise returns register value.
  rs1_data_o <= (others => '0') when rs1_addr_i = "00000"
              else regs(to_integer(unsigned(rs1_addr_i)));

  --! Read logic for rs2: returns zero if address is 0, otherwise returns register value.
  rs2_data_o <= (others => '0') when rs2_addr_i = "00000"
              else regs(to_integer(unsigned(rs2_addr_i)));

  --! @brief Synchronous Write Process.
  --! @details Writes data to rd_addr_i on the rising edge of the clock if write enable is active
  --! and the destination address is not register x0.
  process(clk_i)
  begin
    if rising_edge(clk_i) then
      if reg_write_i = '1' and rd_addr_i /= "00000" then
        regs(to_integer(unsigned(rd_addr_i))) <= rd_data_i;
      end if;
    end if;
  end process;

end arch;
