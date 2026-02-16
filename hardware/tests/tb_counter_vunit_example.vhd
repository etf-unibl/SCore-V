-----------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2025
-- https://github.com/etf-unibl/SCore-V/
-----------------------------------------------------------------------------
--
-- unit name:     tb_counter_vunit_example
--
-- description:
--
--   This file implements a testbench for counter, showcasing VUnit tests
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

library vunit_lib;
context vunit_lib.vunit_context;

library design_lib;

entity tb_counter_vunit_example is
  generic (runner_cfg : string);
end entity tb_counter_vunit_example;

architecture arch of tb_counter_vunit_example is

  constant c_CLK_PERIOD : time := 10 ns;

  signal clk    : std_logic := '0';
  signal rst    : std_logic := '0';
  signal enable : std_logic := '0';
  signal count  : std_logic_vector(3 downto 0);

  signal test_running : boolean := true;

begin

  -- Instantiate the counter
  uut : entity design_lib.counter_vunit_example
    port map (
      clk_i    => clk,
      rst_i    => rst,
      enable_i => enable,
      count_o  => count
    );

  -- Clock generation
  clk <= not clk after c_CLK_PERIOD/2 when test_running else '0';

  -- Main test process
  main : process
  begin
    test_runner_setup(runner, runner_cfg);

    while test_suite loop

      -- Test 1: Reset functionality
      if run("test_reset") then
        info("Testing reset functionality");

        -- Apply reset
        rst <= '1';
        wait for c_CLK_PERIOD * 2;
        rst <= '0';
        wait for c_CLK_PERIOD;

        -- Check that counter is zero after reset
        check_equal(count, std_logic_vector(to_unsigned(0, 4)),
                    "Counter should be 0 after reset");
        info("Reset test passed");

      -- Test 2: Count up from 0 to 5
      elsif run("test_count_up") then
        info("Testing count up from 0 to 5");

        -- Reset first
        rst <= '1';
        wait for c_CLK_PERIOD;
        rst <= '0';
        wait for c_CLK_PERIOD;

        -- Enable counting
        enable <= '1';

        -- Check counting from 0 to 5
        for i in 0 to 5 loop
          check_equal(count, std_logic_vector(to_unsigned(i, 4)),
                      "Counter should be " & to_string(i));
          wait for c_CLK_PERIOD;
        end loop;

        enable <= '0';
        info("Count up test passed");

      -- Test 3: Enable control
      elsif run("test_enable_disable") then
        info("Testing enable/disable functionality");

        -- Reset
        rst <= '1';
        wait for c_CLK_PERIOD;
        rst <= '0';
        wait for c_CLK_PERIOD;

        -- Count to 3
        enable <= '1';
        wait for c_CLK_PERIOD * 3;
        check_equal(count, std_logic_vector(to_unsigned(3, 4)),
                    "Counter should be 3 after 3 clocks");

        -- Disable and verify it stops counting
        enable <= '0';
        wait for c_CLK_PERIOD * 3;
        check_equal(count, std_logic_vector(to_unsigned(3, 4)),
                    "Counter should remain at 3 when disabled");

        -- Re-enable and continue counting
        enable <= '1';
        wait for c_CLK_PERIOD * 2;
        check_equal(count, std_logic_vector(to_unsigned(5, 4)),
                    "Counter should be 5 after re-enabling");

        enable <= '0';
        info("Enable/disable test passed");

      -- Test 4: Overflow behavior
      elsif run("test_overflow") then
        info("Testing overflow behavior (wraps at 16)");

        -- Reset
        rst <= '1';
        wait for c_CLK_PERIOD;
        rst <= '0';
        wait for c_CLK_PERIOD;

        -- Enable counting
        enable <= '1';

        -- Count through overflow (0 to 15, then wraps to 0)
        wait for c_CLK_PERIOD * 16;

        -- After 16 counts, should wrap back to 0
        check_equal(count, std_logic_vector(to_unsigned(0, 4)),
                    "Counter should wrap to 0 after overflow");

        enable <= '0';
        info("Overflow test passed");

      -- Test 5: Reset during counting
      elsif run("test_reset_while_counting") then
        info("Testing reset during active counting");

        -- Start counting from reset
        rst <= '1';
        wait for c_CLK_PERIOD;
        rst <= '0';
        wait for c_CLK_PERIOD;
        enable <= '1';

        -- Count to 5
        wait for c_CLK_PERIOD * 5;
        check_equal(count, std_logic_vector(to_unsigned(5, 4)),
                    "Counter should be 5");

        -- Reset while counting
        rst <= '1';
        wait for c_CLK_PERIOD;
        check_equal(count, std_logic_vector(to_unsigned(0, 4)),
                    "Counter should be 0 immediately after reset");
        rst <= '0';

        -- Should stay at 0 then continue counting
        wait for c_CLK_PERIOD;
        check_equal(count, std_logic_vector(to_unsigned(1, 4)),
                    "Counter should be 1 after reset released");

        enable <= '0';
        info("Reset while counting test passed");

      -- Test 6: Full sequence test
      elsif run("test_full_sequence") then
        info("Testing complete 0-15 sequence");

        -- Reset
        rst <= '1';
        wait for c_CLK_PERIOD;
        rst <= '0';
        wait for c_CLK_PERIOD;

        -- Enable and count through entire range
        enable <= '1';
        for i in 0 to 15 loop
          check_equal(count, std_logic_vector(to_unsigned(i, 4)),
                      "Counter should be " & to_string(i));
          wait for c_CLK_PERIOD;
        end loop;

        -- Check it wraps to 0
        check_equal(count, std_logic_vector(to_unsigned(0, 4)),
                    "Counter should wrap to 0");

        enable <= '0';
        info("Full sequence test passed");

      end if;
    end loop;

    test_runner_cleanup(runner);
    test_running <= false;
  end process main;

end architecture arch;
