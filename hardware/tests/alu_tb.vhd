-----------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2025
-- https://github.com/etf-unibl/SCore-V
-----------------------------------------------------------------------------
--
-- unit name:     alu_tb
--
-- description:
--
--   Self-checking testbench for ALU.
--   Verifies ALU_NOP, ALU_ADD and ALU_SUB operations.
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
library vunit_lib;
context vunit_lib.vunit_context;
library design_lib;
use design_lib.alu_pkg.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu_tb is
  generic (runner_cfg : string);
end alu_tb;

architecture arch of alu_tb is

  constant C_ZERO32 : std_logic_vector(31 downto 0) := (others => '0');

  signal a_i : std_logic_vector(31 downto 0) := (others => '0');
  signal b_i : std_logic_vector(31 downto 0) := (others => '0');
  signal alu_op_i : t_alu_op := ALU_NOP;
  signal y_o : std_logic_vector(31 downto 0);

  -- expected = (a + b) mod 2^32
  function exp_add(a, b : std_logic_vector(31 downto 0)) return std_logic_vector is
    variable s : unsigned(31 downto 0);
  begin
    s := unsigned(a) + unsigned(b);
    return std_logic_vector(s);
  end function;

  -- expected = (a - b) mod 2^32
  function exp_sub(a, b : std_logic_vector(31 downto 0)) return std_logic_vector is
    variable d : unsigned(31 downto 0);
  begin
    d := unsigned(a) - unsigned(b);
    return std_logic_vector(d);
  end function;

begin

  uut_alu : entity design_lib.alu
    port map (
      a_i      => a_i,
      b_i      => b_i,
      alu_op_i => alu_op_i,
      y_o      => y_o
    );

  main : process
    variable exp : std_logic_vector(31 downto 0);
  begin
    test_runner_setup(runner, runner_cfg);

    while test_suite loop

      if run("test_nop") then
        info("Testing NOP operation of ALU");

        alu_op_i <= ALU_NOP;
        a_i <= x"FFFFFFFF";
        b_i <= x"12345678";
        wait for 10 ns;
        check_equal(y_o, C_ZERO32, "ALU_NOP should output zero");

      elsif run("test_add") then
        info("Testing ADD operation of ALU");

        alu_op_i <= ALU_ADD;

        for i in 0 to 100 loop
          for j in 0 to 100 loop
            a_i <= std_logic_vector(to_unsigned(i, 32));
            b_i <= std_logic_vector(to_unsigned(j, 32));
            wait for 10 ns;
            exp := exp_add(a_i, b_i);
            check_equal(y_o, exp, "Loop ADD failed!");
          end loop;
        end loop;
        a_i <= x"FFFFFFFF";
        b_i <= x"FFFFFFFF";
        wait for 10 ns;
        exp := exp_add(a_i, b_i);
        check_equal(y_o, exp, "ADD overflow wrap-around failed!");

      elsif run("test_sub") then
        info("Testing SUB operation of ALU");

        alu_op_i <= ALU_SUB;

        -- Basic cases
        a_i <= std_logic_vector(to_unsigned(10, 32));
        b_i <= std_logic_vector(to_unsigned(5, 32));
        wait for 10 ns;
        exp := exp_sub(a_i, b_i);
        check_equal(y_o, exp, "SUB 10-5 failed");

        -- Wrap-around cases
        a_i <= x"00000000";
        b_i <= x"00000001";
        wait for 10 ns;
        exp := exp_sub(a_i, b_i);
        check_equal(y_o, exp, "SUB 0-1 wrap-around failed");

        a_i <= x"FFFFFFFF";
        b_i <= x"FFFFFFFF";
        wait for 10 ns;
        exp := exp_sub(a_i, b_i);
        check_equal(y_o, exp, "SUB FFFFFFFF-FFFFFFFF failed");

        a_i <= x"80000000";
        b_i <= x"00000001";
        wait for 10 ns;
        exp := exp_sub(a_i, b_i);
        check_equal(y_o, exp, "SUB 80000000-1 failed");

      elsif run("test_xor") then
        info("Testing XOR operation of ALU");
        -- Tests for xor operation here

      elsif run("test_or") then
        info("Testing OR operation of ALU");
        -- Tests for or operation here

      elsif run("test_and") then
        info("Testing AND operation of ALU");
        -- Tests for and operation here

      elsif run("test_sll") then
        info("Testing SLL operation of ALU");
        -- Tests for logic shift left operation here

      elsif run("test_srl") then
        info("Testing SRL operation of ALU");
        -- Tests for logic shift right operation here

      elsif run("test_sra") then
        info("Testing SRA operation of ALU");
        -- Tests for arithmetic shift right operation here

      elsif run("test_slt") then
        info("Testing SLT operation of ALU");
        -- Tests for set less then instruction here

      elsif run("test_sltu") then
        info("Testing SLTU operation of ALU");
        -- Tests for set less then (unsigned) operation here

      end if;
    end loop;

    test_runner_cleanup(runner);
  end process;

end architecture arch;
