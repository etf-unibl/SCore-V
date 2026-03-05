-----------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2025
-- https://github.com/etf-unibl/SCore-V/
-----------------------------------------------------------------------------
--
-- unit name:     imm_gen_tb
--
-- description:
--
--  This file implements self-checking testbench for immediate generator unit
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

entity imm_gen_tb is
  generic (runner_cfg : string);
end imm_gen_tb;

architecture arch of imm_gen_tb is

  signal imm_i_type_i    : std_logic_vector(11 downto 0) := (others => '0');
  signal imm_s_type_h_i  : std_logic_vector(6 downto 0)  := (others => '0');
  signal imm_s_type_l_i  : std_logic_vector(4 downto 0)  := (others => '0');
  signal imm_b_type_i    : std_logic_vector(11 downto 0) := (others => '0');
  signal imm_sel_i       : std_logic_vector(2 downto 0)  := (others => '0');
  signal imm_o           : std_logic_vector(31 downto 0);
  signal imm_j_u_type_i  : std_logic_vector(19 downto 0) := (others => '0');

  constant c_SEL_I_TYPE : std_logic_vector(2 downto 0) := "001";
  constant c_SEL_S_TYPE : std_logic_vector(2 downto 0) := "010";
  constant c_SEL_B_TYPE : std_logic_vector(2 downto 0) := "011";
  constant c_SEL_U_TYPE : std_logic_vector(2 downto 0) := "100";
  constant c_SEL_J_TYPE : std_logic_vector(2 downto 0) := "101";

  constant c_EXPECTED_U : std_logic_vector(31 downto 0) := x"12345000";
begin

  uut_imm_gen : entity design_lib.imm_gen
    port map (
      imm_i_type_i   => imm_i_type_i,
      imm_s_type_h_i => imm_s_type_h_i,
      imm_s_type_l_i => imm_s_type_l_i,
      imm_b_type_i   => imm_b_type_i,
      imm_j_u_type_i => imm_j_u_type_i,
      imm_sel_i      => imm_sel_i,
      imm_o          => imm_o
    );

  -- Test process for Immediate Generator
  -- This test verifies:
  -- I-type immediates (positive and negative sign extension)
  -- S-type immediates (correct concatenation and sign extension)
  -- B-type immediates (left shift by 1, sign extension, edge values)
  -- U-type immediates (Loading into upper 20 bits, lower 12 bits zero-filled)
  -- J-type immediates (Complex bit reordering, sign extension, and implicit 1-bit left shift for jump offsets)
  -- Default case behavior (output should be zero)
  main : process
  begin
    test_runner_setup(runner, runner_cfg);

    while test_suite loop
      if run("test_imm_gen") then

        -- I-Type tests
        imm_i_type_i <= std_logic_vector(to_signed(100, 12));
        imm_sel_i    <= c_SEL_I_TYPE;
        wait for 10 ns;
        check_equal(to_integer(signed(imm_o)), 100,
                    "I-Type Positive failed");

        imm_i_type_i <= std_logic_vector(to_signed(-5, 12));
        imm_sel_i    <= c_SEL_I_TYPE;
        wait for 10 ns;
        check_equal(to_integer(signed(imm_o)), -5,
                    "I-Type Negative failed");

        -- S-Type tests
        imm_s_type_h_i <= "0111111";
        imm_s_type_l_i <= "11111";
        imm_sel_i      <= c_SEL_S_TYPE;
        wait for 10 ns;
        check_equal(to_integer(signed(imm_o)), 2047,
                    "S-Type Positive failed");

        imm_s_type_h_i <= "1111111";
        imm_s_type_l_i <= "11111";
        imm_sel_i      <= c_SEL_S_TYPE;
        wait for 10 ns;
        check_equal(to_integer(signed(imm_o)), -1,
                    "S-Type Negative failed");

        imm_sel_i <= "000";
        wait for 10 ns;
        check_equal(to_integer(signed(imm_o)), 0,
                    "Default case should output zero");

        -- B-Type tests
        -- Includes left shift by 1 and sign extension checks
        imm_b_type_i <= std_logic_vector(to_signed(2, 12));
        imm_sel_i    <= c_SEL_B_TYPE;
        wait for 10 ns;
        check_equal(to_integer(signed(imm_o)), 4,
                    "B-Type Positive (4 bytes) failed");

        imm_b_type_i <= "011111111111";
        imm_sel_i    <= c_SEL_B_TYPE;
        wait for 10 ns;
        check_equal(to_integer(signed(imm_o)), 4094,
                    "B-Type Max Positive failed");

        imm_b_type_i <= (others => '1');
        imm_sel_i    <= c_SEL_B_TYPE;
        wait for 10 ns;
        check_equal(to_integer(signed(imm_o)), -2,
                    "B-Type Small Negative (-2) failed");

        imm_b_type_i <= "100000000000";
        imm_sel_i    <= c_SEL_B_TYPE;
        wait for 10 ns;
        check_equal(to_integer(signed(imm_o)), -4096,
                    "B-Type Max Negative (-4096) failed");
        -- J and U types
        imm_j_u_type_i <= x"12345";
        imm_sel_i      <= c_SEL_U_TYPE;
        wait for 10 ns;
        check_equal(imm_o, c_EXPECTED_U, 
                   "U-Type LUI failed");

        imm_j_u_type_i <= std_logic_vector(to_signed(2, 20)); 
        imm_sel_i      <= c_SEL_J_TYPE;
        wait for 10 ns;
        check_equal(to_integer(signed(imm_o)), 4, 
                    "J-Type Positive offset failed");

        imm_j_u_type_i <= std_logic_vector(to_signed(-2, 20));
        imm_sel_i      <= c_SEL_J_TYPE;
        wait for 10 ns;
        check_equal(to_integer(signed(imm_o)), -4, 
                    "J-Type Negative offset failed");

      end if;
    end loop;

    test_runner_cleanup(runner);
  end process main;

end arch;
