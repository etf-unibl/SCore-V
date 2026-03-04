-----------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2025
-- https://github.com/etf-unibl/SCore-V/
-----------------------------------------------------------------------------
--
-- unit name:     branch_comparator_tb
--
-- description:
--
--   This file implements self-checking testbench for branch_comparator.
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

entity branch_comparator_tb is
  generic (runner_cfg : string);
end branch_comparator_tb;

architecture arch of branch_comparator_tb is

  signal a_i : std_logic_vector(31 downto 0) := (others => '0');
  signal b_i : std_logic_vector(31 downto 0) := (others => '0');
  signal br_un_i : std_logic := '0';
  signal br_eq_o : std_logic;
  signal br_lt_o : std_logic;

begin

  uut : entity design_lib.branch_comparator
  port map (
    a_i     => a_i,
    b_i     => b_i,
    br_un_i => br_un_i,
    br_eq_o => br_eq_o,
    br_lt_o => br_lt_o
  );

  main : process
  begin
    test_runner_setup(runner, runner_cfg);

    while test_suite loop

      -------------------------------------------------------------------------
      -- Equality tests
      -------------------------------------------------------------------------
      if run("test_equality") then

        -- EQ: 0 == 0 (signed)
        a_i     <= x"00000000";
        b_i     <= x"00000000";
        br_un_i <= '0';
        wait for 5 ns;
        check_equal(br_eq_o, '1', "EQ: 0 == 0 (br_eq)");
        check_equal(br_lt_o, '0', "EQ: 0 == 0 (br_lt)");

        -- EQ: 0 == 0 (unsigned)
        a_i     <= x"00000000";
        b_i     <= x"00000000";
        br_un_i <= '1';
        wait for 5 ns;
        check_equal(br_eq_o, '1', "EQ: 0 == 0 unsigned (br_eq)");
        check_equal(br_lt_o, '0', "EQ: 0 == 0 unsigned (br_lt)");

        -- EQ: pattern == pattern
        a_i     <= x"12345678";
        b_i     <= x"12345678";
        br_un_i <= '0';
        wait for 5 ns;
        check_equal(br_eq_o, '1', "EQ: 12345678 == 12345678 (br_eq)");
        check_equal(br_lt_o, '0', "EQ: 12345678 == 12345678 (br_lt)");

        -- NE: 1 != 2 (signed) and 1 < 2
        a_i     <= x"00000001";
        b_i     <= x"00000002";
        br_un_i <= '0';
        wait for 5 ns;
        check_equal(br_eq_o, '0', "NE: 1 != 2 (br_eq)");
        check_equal(br_lt_o, '1', "NE: 1 < 2 signed (br_lt)");

        -- NE: 2 != 1 (unsigned) and 2 !< 1
        a_i     <= x"00000002";
        b_i     <= x"00000001";
        br_un_i <= '1';
        wait for 5 ns;
        check_equal(br_eq_o, '0', "NE: 2 != 1 (br_eq)");
        check_equal(br_lt_o, '0', "NE: 2 !< 1 unsigned (br_lt)");

      -------------------------------------------------------------------------
      -- Signed less-than tests (br_un_i = 0)
      -------------------------------------------------------------------------
      elsif run("test_signed_less_than") then

        -- Signed LT: 1 < 2
        a_i     <= x"00000001";
        b_i     <= x"00000002";
        br_un_i <= '0';
        wait for 5 ns;
        check_equal(br_eq_o, '0', "Signed LT: 1 vs 2 (br_eq)");
        check_equal(br_lt_o, '1', "Signed LT: 1 < 2 (br_lt)");

        -- Signed LT: 2 !< 1
        a_i     <= x"00000002";
        b_i     <= x"00000001";
        br_un_i <= '0';
        wait for 5 ns;
        check_equal(br_eq_o, '0', "Signed LT: 2 vs 1 (br_eq)");
        check_equal(br_lt_o, '0', "Signed LT: 2 !< 1 (br_lt)");

        -- Signed boundary: 0x80000000 < 0x7FFFFFFF
        a_i     <= x"80000000";
        b_i     <= x"7FFFFFFF";
        br_un_i <= '0';
        wait for 5 ns;
        check_equal(br_eq_o, '0', "Signed boundary (br_eq)");
        check_equal(br_lt_o, '1', "Signed boundary: 0x80000000 < 0x7FFFFFFF (br_lt)");

        -- Signed: -1 < 0
        a_i     <= x"FFFFFFFF";
        b_i     <= x"00000000";
        br_un_i <= '0';
        wait for 5 ns;
        check_equal(br_eq_o, '0', "Signed -1 vs 0 (br_eq)");
        check_equal(br_lt_o, '1', "Signed: -1 < 0 (br_lt)");

      -------------------------------------------------------------------------
      -- Unsigned less-than tests (br_un_i = 1)
      -------------------------------------------------------------------------
      elsif run("test_unsigned_less_than") then

        -- Unsigned LT: 1 < 2
        a_i     <= x"00000001";
        b_i     <= x"00000002";
        br_un_i <= '1';
        wait for 5 ns;
        check_equal(br_eq_o, '0', "Unsigned LT: 1 vs 2 (br_eq)");
        check_equal(br_lt_o, '1', "Unsigned LT: 1 < 2 (br_lt)");

        -- Unsigned LT: 2 !< 1
        a_i     <= x"00000002";
        b_i     <= x"00000001";
        br_un_i <= '1';
        wait for 5 ns;
        check_equal(br_eq_o, '0', "Unsigned LT: 2 vs 1 (br_eq)");
        check_equal(br_lt_o, '0', "Unsigned LT: 2 !< 1 (br_lt)");

        -- Unsigned boundary: 0 < 0xFFFFFFFF
        a_i     <= x"00000000";
        b_i     <= x"FFFFFFFF";
        br_un_i <= '1';
        wait for 5 ns;
        check_equal(br_eq_o, '0', "Unsigned boundary 0 vs FFFFFFFF (br_eq)");
        check_equal(br_lt_o, '1', "Unsigned: 0 < 0xFFFFFFFF (br_lt)");

        -- Unsigned: 0xFFFFFFFF !< 0
        a_i     <= x"FFFFFFFF";
        b_i     <= x"00000000";
        br_un_i <= '1';
        wait for 5 ns;
        check_equal(br_eq_o, '0', "Unsigned FFFFFFFF vs 0 (br_eq)");
        check_equal(br_lt_o, '0', "Unsigned: 0xFFFFFFFF !< 0 (br_lt)");

      -------------------------------------------------------------------------
      -- Signed/Unsigned divergence cases (must-have)
      -------------------------------------------------------------------------
      elsif run("test_signed_unsigned_divergence") then

        -- A=0x80000000, B=0x00000001
        -- signed: true
        a_i     <= x"80000000";
        b_i     <= x"00000001";
        br_un_i <= '0';
        wait for 5 ns;
        check_equal(br_eq_o, '0', "Divergence 0x80000000 vs 1 signed (br_eq)");
        check_equal(br_lt_o, '1', "Divergence signed: 0x80000000 < 1 (br_lt)");

        -- unsigned: false
        a_i     <= x"80000000";
        b_i     <= x"00000001";
        br_un_i <= '1';
        wait for 5 ns;
        check_equal(br_eq_o, '0', "Divergence 0x80000000 vs 1 unsigned (br_eq)");
        check_equal(br_lt_o, '0', "Divergence unsigned: 0x80000000 !< 1 (br_lt)");

        -- A=0xFFFFFFFF, B=0x00000000
        -- signed: true (-1 < 0)
        a_i     <= x"FFFFFFFF";
        b_i     <= x"00000000";
        br_un_i <= '0';
        wait for 5 ns;
        check_equal(br_eq_o, '0', "Divergence FFFFFFFF vs 0 signed (br_eq)");
        check_equal(br_lt_o, '1', "Divergence signed: -1 < 0 (br_lt)");

        -- unsigned: false (0xFFFFFFFF is max unsigned)
        a_i     <= x"FFFFFFFF";
        b_i     <= x"00000000";
        br_un_i <= '1';
        wait for 5 ns;
        check_equal(br_eq_o, '0', "Divergence FFFFFFFF vs 0 unsigned (br_eq)");
        check_equal(br_lt_o, '0', "Divergence unsigned: 0xFFFFFFFF !< 0 (br_lt)");

      end if;
      end loop;

    test_runner_cleanup(runner);
  end process main;
end arch;
