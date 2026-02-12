-----------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2025
-- https://github.com/etf-unibl/pds-2025/
-----------------------------------------------------------------------------
--
-- unit name:     pc_tb
--
-- description:
--
--   This file implements a simple program counter testbench.
--
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

entity pc_tb is
end pc_tb;

architecture arch of pc_tb is
  component pc
    port (
      clk_i     : in  std_logic;
      rst_i     : in  std_logic;
      pc_next_i : in  unsigned(31 downto 0);
      pc_o      : out unsigned(31 downto 0)
    );
  end component;

  component pc_next_instruction
    port (
      pc_i      : in  unsigned(31 downto 0);
      pc_next_o : out unsigned(31 downto 0)
    );
  end component;

  signal clk_i    : std_logic := '0';
  signal rst_i    : std_logic := '0';
  signal pc_out  : unsigned(31 downto 0) := (others => '0');
  signal pc_next : unsigned(31 downto 0) := (others => '0');


  signal test_stop : std_logic := '0';
  constant c_CLK_PERIOD : time := 10 ns;

begin
  uut_pc_next_instr : pc_next_instruction
    port map (
      pc_i      => pc_out,
      pc_next_o => pc_next
    );

  uut_pc : pc
    port map (
      clk_i     => clk_i,
      rst_i     => rst_i,
      pc_next_i => pc_next,
      pc_o      => pc_out
    );

  clk_process : process
  begin
    while test_stop = '0' loop
      clk_i <= '0';
      wait for c_CLK_PERIOD/2;
      clk_i <= '1';
      wait for c_CLK_PERIOD/2;
    end loop;
    wait;
  end process clk_process;

  stim_proc : process
  begin
    rst_i <= '1';
    wait for c_CLK_PERIOD;
    rst_i <= '0';

    for i in 1 to 6 loop
      wait until rising_edge(clk_i);
      assert false report "PC = " & integer'image(to_integer(pc_out)) severity note;
    end loop;

    test_stop <= '1';
    wait;
  end process stim_proc;
end arch;
