-----------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2025
-- https://github.com/etf-unibl/SCore-V/
-----------------------------------------------------------------------------
--
-- unit name:     pc
--
-- description:
--
--   This file implements a simple Program Counter register.
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

--! @file pc.vhd
--! @brief Program Counter (PC) register
--! @details Implements a 32-bit synchronous Program Counter register.
--! The PC value is updated on the rising edge of the clock.
--! When reset is asserted, the PC is cleared to zero.
--! Otherwise, the next PC value is loaded from the input.

entity pc is
  port (
    clk_i     : in  std_logic;                     --! Input clock signal
    rst_i     : in  std_logic;                     --! Active-high synchronous reset
    pc_next_i : in  std_logic_vector(31 downto 0); --! Next PC value input
    pc_o      : out std_logic_vector(31 downto 0)  --! Current PC value output
  );
end pc;

--! @brief Architecture arch for Program Counter
--! @details Contains the PC register and synchronous update logic
architecture arch of pc is
  --! @brief Internal signal declarations
  signal pc_reg : std_logic_vector(31 downto 0); --! Internal PC register
begin

  --! @brief PC register process
  --! @details Updates PC on rising clock edge.
  --! If reset is asserted, PC is cleared to zero.
  --! Otherwise, loads the next PC value.
  pc_reg_p : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = '1' then
        pc_reg <= (others => '0');
      else
        pc_reg <= pc_next_i;
      end if;
    end if;
  end process pc_reg_p;

  --! @brief Output assignment
  --! @details Connects internal PC register to output port
  pc_o <= pc_reg;
end arch;
