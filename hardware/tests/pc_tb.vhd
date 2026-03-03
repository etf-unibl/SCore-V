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
--   This file implements self-checking testbench for pc unit
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

library vunit_lib;
context vunit_lib.vunit_context;

library design_lib;

entity pc_tb is
  generic (
    runner_cfg : string
  );
end pc_tb;

architecture arch of pc_tb is

  -- Signals
  signal clk_i       : std_logic := '0';
  signal rst_i       : std_logic := '0';
  signal pc_out      : std_logic_vector(31 downto 0) := (others => '0');
  signal pc_next     : std_logic_vector(31 downto 0) := (others => '0');
  signal sim_stop_s  : std_logic := '0';
  signal pc_sel_s    : std_logic := '0';
  signal pc_target_s : std_logic_vector(31 downto 0) := (others => '0');

  constant c_CLK_PERIOD : time := 10 ns;

  -- Branch test types
  type branch_test_t is record
    pc_start  : std_logic_vector(31 downto 0);
    pc_target : std_logic_vector(31 downto 0);
    expected  : std_logic_vector(31 downto 0);
  end record;

  type branch_test_array_t is array (natural range <>) of branch_test_t;

  constant branch_tests : branch_test_array_t := (
    (pc_start => X"00000004", pc_target => X"00000000", expected => X"00000000"),
    (pc_start => X"FFFFFFFC", pc_target => X"00000004", expected => X"00000004"),
    (pc_start => X"00000000", pc_target => X"00000064", expected => X"00000064"),
    (pc_start => X"00001000", pc_target => X"FFFFF000", expected => X"FFFFF000")
  );

begin

  -- Instantiate PC next instruction logic
  uut_pc_next_instr : entity design_lib.pc_next_instruction
    port map (
      pc_target_i => pc_target_s,
      pc_sel_i    => pc_sel_s,
      pc_i        => pc_out,
      pc_next_o   => pc_next
    );

  -- Instantiate PC
  uut_pc : entity design_lib.pc
    port map (
      clk_i     => clk_i,
      rst_i     => rst_i,
      pc_next_i => pc_next,
      pc_o      => pc_out
    );

  -- Clock generator
  clk_process : process
  begin
    while sim_stop_s = '0' loop
      clk_i <= '0';
      wait for c_CLK_PERIOD / 2;
      clk_i <= '1';
      wait for c_CLK_PERIOD / 2;
    end loop;
    wait;
  end process clk_process;

  -- PC increment uses unsigned arithmetic (numeric_std).
  -- Since the PC is 32-bit wide, addition is performed modulo 2^32.
  -- Therefore, when PC = 0xFFFFFFFC and 4 is added,
  -- the result wraps around to 0x00000000.
  main : process
    variable expected_pc : std_logic_vector(31 downto 0);
  begin
    test_runner_setup(runner, runner_cfg);

    while test_suite loop

      -- Test reset
      if run("test_reset") then
        info("Testing reset");
        rst_i <= '1';
        wait until rising_edge(clk_i);
        wait until rising_edge(clk_i);
        expected_pc := (others => '0');
        check_equal(pc_out, expected_pc, "pc should be 0 after reset");

        wait until rising_edge(clk_i);
        check_equal(pc_out, expected_pc, "pc should still be 0");

      -- Test increment
      elsif run("test_increment") then
        info("Testing incrementing");
        rst_i <= '1';
        wait until rising_edge(clk_i);
        wait until rising_edge(clk_i);
        rst_i <= '0';
        wait until rising_edge(clk_i);

        for i in 1 to 5 loop
          wait until rising_edge(clk_i);
          expected_pc := std_logic_vector(to_unsigned(i * 4, 32));
          if pc_out /= expected_pc then
            failure("FAIL: pc should be " & to_string(expected_pc) &
                    " and not " & to_string(pc_out));
          end if;
        end loop;

      -- Test increment + reset
      elsif run("test_increment_reset") then
        rst_i <= '1';
        wait until rising_edge(clk_i);
        wait until rising_edge(clk_i);
        rst_i <= '0';
        wait until rising_edge(clk_i);

        for i in 1 to 5 loop
          wait until rising_edge(clk_i);
          expected_pc := std_logic_vector(to_unsigned(i * 4, 32));
          check_equal(pc_out, expected_pc, "pc should be " & to_string(expected_pc));
        end loop;

        rst_i <= '1';
        wait until rising_edge(clk_i);
        wait until rising_edge(clk_i);
        expected_pc := (others => '0');
        check_equal(pc_out, expected_pc, "pc should be 0 after reset");

      -- Test branch
      elsif run("test_branch") then
        info("Testing branch jump");

        rst_i <= '1';
        wait until rising_edge(clk_i);
        wait until rising_edge(clk_i);
        pc_target_s <= std_logic_vector(to_unsigned(100, 32));
        pc_sel_s    <= '1';
        rst_i <= '0';

        wait until rising_edge(clk_i);
        wait until rising_edge(clk_i);
        expected_pc := std_logic_vector(to_unsigned(100, 32));
        check_equal(pc_out, expected_pc, "pc should be " & to_string(expected_pc));

        pc_sel_s <= '0';
        wait until rising_edge(clk_i);
        wait until rising_edge(clk_i);
        expected_pc := std_logic_vector(to_unsigned(104, 32));
        check_equal(pc_out, expected_pc, "pc should be " & to_string(expected_pc));

        rst_i <= '1';
        wait until rising_edge(clk_i);
        wait until rising_edge(clk_i);
        rst_i <= '0';
        wait until rising_edge(clk_i);

        -- Branch tests loop
        for i in branch_tests'range loop

          pc_target_s <= branch_tests(i).pc_start;
          pc_sel_s    <= '1';
          wait until rising_edge(clk_i);

          pc_target_s <= branch_tests(i).pc_target;
          pc_sel_s    <= '1';
          wait until rising_edge(clk_i);
          wait until rising_edge(clk_i);

          check_equal(pc_out, branch_tests(i).expected,
            "PC branch test failed for start = " & to_string(branch_tests(i).pc_start) &
            " target = " & to_string(branch_tests(i).pc_target));

        end loop;

      end if;
    end loop;

    test_runner_cleanup(runner);
    sim_stop_s <= '1';
    wait;
  end process main;

end arch;
