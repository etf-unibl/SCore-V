-----------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2025
-- https://github.com/etf-unibl/SCore-V/
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
      pc_next_i : in  std_logic_vector(31 downto 0);
      pc_o      : out std_logic_vector(31 downto 0)
    );
  end component;

  component pc_next_instruction
    port (
      pc_i      : in  std_logic_vector(31 downto 0);
      pc_next_o : out std_logic_vector(31 downto 0)
    );
  end component;

  signal clk_i      : std_logic := '0';
  signal rst_i      : std_logic := '0';
  signal pc_out     : std_logic_vector(31 downto 0) := (others => '0');
  signal pc_next    : std_logic_vector(31 downto 0) := (others => '0');
  signal sim_stop_s : std_logic := '0';

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
    while sim_stop_s = '0' loop
      clk_i <= '0';
      wait for c_CLK_PERIOD/2;
      clk_i <= '1';
      wait for c_CLK_PERIOD/2;
    end loop;
    wait;
  end process clk_process;

  -- PC increment uses unsigned arithmetic (numeric_std).
  -- Since the PC is 32-bit wide, addition is performed modulo 2^32.
  -- Therefore, when PC = 0xFFFFFFFC and 4 is added,
  -- the result wraps around to 0x00000000.
  stim_proc : process
    variable expected_pc : std_logic_vector(31 downto 0);
  begin
    --- Test 1: Reset
    rst_i <= '1';
    wait until rising_edge(clk_i);
    wait until rising_edge(clk_i);
    expected_pc := (others => '0');
    assert pc_out = expected_pc
      report "FAIL: PC not 0 after reset!"
      severity failure;

    rst_i <= '0';

    --- Test 2: First cycle after reset
    wait until rising_edge(clk_i);
    assert pc_out = expected_pc
      report "FAIL: PC changed in first cycle after reset!"
      severity failure;

    --- Test 3: Normal increment
    for i in 1 to 5 loop
      wait until rising_edge(clk_i);
      expected_pc := std_logic_vector(unsigned(expected_pc) + 4);
      assert pc_out = expected_pc
        report "FAIL: PC increment incorrect!"
        severity failure;
    end loop;

    --- Test 4: Reset during operation
    rst_i <= '1';
    wait until rising_edge(clk_i);
    wait until rising_edge(clk_i);
    expected_pc := (others => '0');
    assert pc_out = expected_pc
      report "FAIL: PC not reset during operation!"
      severity failure;

    rst_i <= '0';

    assert false report "All tests passed!" severity note;

    sim_stop_s <= '1';
    wait;

  end process stim_proc;

end arch;
