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
--   Self-checking VUnit testbench for the 32-bit combinational ALU.
--   The testbench instantiates the ALU and verifies that y_o matches the
--   expected result for each selected operation.
--
--   Currently covered operations:
--     - ALU_NOP
--     - Arithmetic: ALU_ADD, ALU_SUB
--     - Logical:   ALU_AND, ALU_OR, ALU_XOR
--     - Shifts:    ALU_SLL, ALU_SRL, ALU_SRA
--     - Compare:   ALU_SLT, ALU_SLTU
--   Notes:
--     - Shift amount is taken from b_i(4 downto 0), matching RISC-V behavior
--       for both register and immediate shift instructions.
--     - SLT uses signed comparison, while SLTU uses unsigned comparison.
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

  -- expected = a and b
  function exp_and(a, b : std_logic_vector(31 downto 0)) return std_logic_vector is
    variable d : unsigned(31 downto 0);
  begin
    d := unsigned(a) and unsigned(b);
    return std_logic_vector(d);
  end function;

  -- expected = a or b
  function exp_or(a, b : std_logic_vector(31 downto 0)) return std_logic_vector is
    variable r : unsigned(31 downto 0);
  begin
    r := unsigned(a) or unsigned(b);
    return std_logic_vector(r);
  end function;

  -- expected = (signed(a) < signed(b)) ? 1 : 0
  function exp_slt(a, b : std_logic_vector(31 downto 0)) return std_logic_vector is
  begin
    if signed(a) < signed(b) then
      return x"00000001";
    else
      return x"00000000";
    end if;
  end function;

  -- expected = a xor b
  function exp_xor(a, b : std_logic_vector(31 downto 0)) return std_logic_vector is
    variable r : unsigned(31 downto 0);
  begin
    r := unsigned(a) xor unsigned(b);
    return std_logic_vector(r);
  end function;

  -- expected = logical left shift (a << shamt), shift = b(4 downto 0)
  function exp_sll(a, b : std_logic_vector(31 downto 0)) return std_logic_vector is
    variable sh : natural range 0 to 31;
  begin
    sh := to_integer(unsigned(b(4 downto 0)));
    return std_logic_vector(shift_left(unsigned(a), sh));
  end function;

  -- expected = logical right shift (a >> shift), shift = b(4 downto 0)
  function exp_srl(a, b : std_logic_vector(31 downto 0)) return std_logic_vector is
    variable sh : natural range 0 to 31;
  begin
    sh := to_integer(unsigned(b(4 downto 0)));
    return std_logic_vector(shift_right(unsigned(a), sh));
  end function;

  -- expected = (unsigned(a) < unsigned(b)) ? 1 : 0
  function exp_sltu(a, b : std_logic_vector(31 downto 0)) return std_logic_vector is
  begin
    if unsigned(a) < unsigned(b) then
      return x"00000001";
    else
      return x"00000000";
    end if;
  end function;

  -- expected = a >> b
  function exp_sra(a : std_logic_vector(31 downto 0); shamt : natural) return std_logic_vector is
  begin
    return std_logic_vector(shift_right(signed(a), shamt));
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
        alu_op_i <= ALU_XOR;

        -- 0 xor 0 = 0
        a_i <= "00000000000000000000000000000000";
        b_i <= "00000000000000000000000000000000";
        wait for 10 ns;
        exp := exp_xor(a_i, b_i);
        check_equal(y_o, exp, "XOR 0^0 failed");

        -- all1 xor 0 = all1
        a_i <= "11111111111111111111111111111111";
        b_i <= "00000000000000000000000000000000";
        wait for 10 ns;
        exp := exp_xor(a_i, b_i);
        check_equal(y_o, exp, "XOR all1^0 failed");

        -- all1 xor all1 = 0
        a_i <= "11111111111111111111111111111111";
        b_i <= "11111111111111111111111111111111";
        wait for 10 ns;
        exp := exp_xor(a_i, b_i);
        check_equal(y_o, exp, "XOR all1^all1 failed");

        -- mixed pattern
        a_i <= "00010010001101000101011001111000"; -- 0x12345678
        b_i <= "10000111011001010100001100100001"; -- 0x87654321
        wait for 10 ns;
        exp := exp_xor(a_i, b_i);
        check_equal(y_o, exp, "XOR mixed pattern failed");

        -- 0xAAAAAAAA xor 0x55555555 = 0xFFFFFFFF
        a_i <= "10101010101010101010101010101010";
        b_i <= "01010101010101010101010101010101";
        wait for 10 ns;
        exp := exp_xor(a_i, b_i);
        check_equal(y_o, exp, "XOR alternating bits failed");

      elsif run("test_or") then
        info("Testing OR operation of ALU");
        alu_op_i <= ALU_OR;

        -- 0 | 0 = 0
        a_i <= "00000000000000000000000000000000";
        b_i <= "00000000000000000000000000000000";
        wait for 10 ns;
        exp := exp_or(a_i, b_i);
        check_equal(y_o, exp, "OR 0|0 failed");

        -- all1 | 0 = all1
        a_i <= "11111111111111111111111111111111";
        b_i <= "00000000000000000000000000000000";
        wait for 10 ns;
        exp := exp_or(a_i, b_i);
        check_equal(y_o, exp, "OR all1|0 failed");

        -- mixed pattern(0x12345678 | 0x87654321)
        a_i <= "00010010001101000101011001111000";
        b_i <= "10000111011001010100001100100001";
        wait for 10 ns;
        exp := exp_or(a_i, b_i);
        check_equal(y_o, exp, "OR mixed pattern 1 failed");

        -- ORI-like case (immediate style on b_i)
        a_i <= "00000000000000001111111100000000"; -- 0x0000FF00
        b_i <= "00000000000000000000000000001111"; -- 0x0000000F
        wait for 10 ns;
        exp := exp_or(a_i, b_i);
        check_equal(y_o, exp, "OR/ORI immediate-style case failed");

        -- mixed pattern(0x00FF00FF | 0x0F0F0F0F)
        a_i <= "00000000111111110000000011111111";
        b_i <= "00001111000011110000111100001111";
        wait for 10 ns;
        exp := exp_or(a_i, b_i);
        check_equal(y_o, exp, "OR mixed pattern 2 failed");

      elsif run("test_and") then
        info("Testing AND operation of ALU");
        alu_op_i <= ALU_AND;

        a_i <= "10101010101010101010101010101010";
        b_i <= "01010101010101010101010101010101";
        wait for 10 ns;
        exp := exp_and(a_i, b_i);
        check_equal(y_o, exp, "AND fail");

        a_i <= "11111111111111111111111111111111";
        b_i <= "11111111111111111111111111111111";
        wait for 10 ns;
        exp := exp_and(a_i, b_i);
        check_equal(y_o, exp, "AND fail");

        a_i <= "00000000000000000000000000000000";
        b_i <= "11111111101111111110111111111111";
        wait for 10 ns;
        exp := exp_and(a_i, b_i);
        check_equal(y_o, exp, "AND fail");

        a_i <= "00000000000000000000000000000000";
        b_i <= "00000000000000000000000000000000";
        wait for 10 ns;
        exp := exp_and(a_i, b_i);
        check_equal(y_o, exp, "AND fail");

      elsif run("test_sll") then
        info("Testing SLL operation of ALU");
        alu_op_i <= ALU_SLL;

        -- 0 << 0 = 0
        a_i <= "00000000000000000000000000000000";
        b_i <= "00000000000000000000000000000000"; -- sh=0
        wait for 10 ns;
        exp := exp_sll(a_i, b_i);
        check_equal(y_o, exp, "SLL 0 << 0 failed");

        -- 1 << 1 = 2
        a_i <= "00000000000000000000000000000001";
        b_i <= "00000000000000000000000000000001"; -- sh=1
        wait for 10 ns;
        exp := exp_sll(a_i, b_i);
        check_equal(y_o, exp, "SLL 1 << 1 failed");

        -- LSB set shifted left by 31 -> MSB set
        a_i <= "00000000000000000000000000000001";
        b_i <= "00000000000000000000000000011111"; -- sh=31
        wait for 10 ns;
        exp := exp_sll(a_i, b_i);
        check_equal(y_o, exp, "SLL 1 << 31 failed");

        -- shift left by 4
        a_i <= "00001111000000000000000000000000"; -- 0x0F000000
        b_i <= "00000000000000000000000000000100"; -- sh=4
        wait for 10 ns;
        exp := exp_sll(a_i, b_i);
        check_equal(y_o, exp, "SLL 0x0F000000 << 4 failed");

        -- only b(4:0) matters
        a_i <= "00000000000000000000000000000001";
        b_i <= "00000000000000000000000000100001"; -- sh=1
        wait for 10 ns;
        exp := exp_sll(a_i, b_i);
        check_equal(y_o, exp, "SLL shamt from b(4:0) failed");

      elsif run("test_srl") then
        info("Testing SRL operation of ALU");
        alu_op_i <= ALU_SRL;

        -- 0 >> 0 = 0
        a_i <= "00000000000000000000000000000000";
        b_i <= "00000000000000000000000000000000"; -- sh=0
        wait for 10 ns;
        exp := exp_srl(a_i, b_i);
        check_equal(y_o, exp, "SRL 0 >> 0 failed");

       -- 1 >> 1 = 0
       a_i <= "00000000000000000000000000000001";
       b_i <= "00000000000000000000000000000001"; -- sh=1
       wait for 10 ns;
       exp := exp_srl(a_i, b_i);
       check_equal(y_o, exp, "SRL 1 >> 1 failed");

       -- Logical shift right: fills with zeros on the left
       -- 0x80000000 >> 1 = 0x40000000
       a_i <= "10000000000000000000000000000000";
       b_i <= "00000000000000000000000000000001"; -- sh=1
       wait for 10 ns;
       exp := exp_srl(a_i, b_i);
       check_equal(y_o, exp, "SRL 1000..0 >> 1 failed");

       -- 0xF0000000 >> 4 = 0x0F000000
       a_i <= "11110000000000000000000000000000";
       b_i <= "00000000000000000000000000000100"; -- sh=4
       wait for 10 ns;
       exp := exp_srl(a_i, b_i);
       check_equal(y_o, exp, "SRL 1111.... >> 4 failed");

       -- SRLI-like: only b_i(4 downto 0) is used as the shift amount
       a_i <= "10000000000000000000000000000000";
       b_i <= "00000000000000000000000000100001"; -- sh=1
       wait for 10 ns;
       exp := exp_srl(a_i, b_i);
       check_equal(y_o, exp, "SRL sh from b(4:0) failed");

      elsif run("test_sra") then
        info("Testing SRA operation of ALU");
        alu_op_i <= ALU_SRA;

        -- Arithmetic shift right behaves like logical shift for positive numbers (MSB=0)
        -- 0x00000010 >>> 2 = 0x00000004
        a_i <= x"00000010";
        b_i <= x"00000002";
        wait for 10 ns;
        exp := exp_sra(a_i, to_integer(unsigned(b_i(4 downto 0))));
        check_equal(y_o, exp, "SRA positive failed");

        -- Arithmetic shift right replicates the sign bit (MSB) on the left
        -- 0x80000000 >>> 1 = 0xC0000000
        a_i <= x"80000000";
        b_i <= x"00000001";
        wait for 10 ns;
        exp := exp_sra(a_i, to_integer(unsigned(b_i(4 downto 0))));
        check_equal(y_o, exp, "SRA sign extension failed (MSB should stay 1)");

        -- Negative value example: sign-extension fills with ones
        -- 0xF0000000 >>> 4 = 0xFF000000
        a_i <= x"F0000000";
        b_i <= x"00000004";
        wait for 10 ns;
        exp := exp_sra(a_i, to_integer(unsigned(b_i(4 downto 0))));
        check_equal(y_o, exp, "SRA shift 4 places failed");

        -- Shift by 31 keeps only the sign after extension:
        -- 0x80000000 >>> 31 = 0xFFFFFFFF (i.e. -1)
        a_i <= x"80000000";
        b_i <= x"0000001F";
        wait for 10 ns;
        exp := exp_sra(a_i, to_integer(unsigned(b_i(4 downto 0))));
        check_equal(y_o, exp, "SRA shift by 31 failed (sign extension)");

      elsif run("test_slt") then
        info("Testing SLT operation of ALU");
        alu_op_i <= ALU_SLT;

        -- 3 < 5 => 1
        a_i <= x"00000003";
        b_i <= x"00000005";
        wait for 10 ns;
        exp := exp_slt(a_i, b_i);
        check_equal(y_o, exp, "SLT 3<5 failed");

        -- 5 < 3 => 0
        a_i <= x"00000005";
        b_i <= x"00000003";
        wait for 10 ns;
        exp := exp_slt(a_i, b_i);
        check_equal(y_o, exp, "SLT 5<3 failed");

        -- -1 < 1 => 1
        a_i <= x"FFFFFFFF"; -- -1
        b_i <= x"00000001"; -- 1
        wait for 10 ns;
        exp := exp_slt(a_i, b_i);
        check_equal(y_o, exp, "SLT -1<1 failed");

        -- 1 < -1 => 0
        a_i <= x"00000001"; -- 1
        b_i <= x"FFFFFFFF"; -- -1
        wait for 10 ns;
        exp := exp_slt(a_i, b_i);
        check_equal(y_o, exp, "SLT 1<-1 failed");

        -- -10 < -5 => 1  (0xFFFFFFF6 < 0xFFFFFFFB signed)
        a_i <= x"FFFFFFF6"; -- -10
        b_i <= x"FFFFFFFB"; -- -5
        wait for 10 ns;
        exp := exp_slt(a_i, b_i);
        check_equal(y_o, exp, "SLT -10<-5 failed");

        -- most negative < 0 => 1
        a_i <= x"80000000"; -- -2147483648
        b_i <= x"00000000"; -- 0
        wait for 10 ns;
        exp := exp_slt(a_i, b_i);
        check_equal(y_o, exp, "SLT 0x80000000<0 failed");

      elsif run("test_sltu") then
        info("Testing SLTU operation of ALU");
        alu_op_i <= ALU_SLTU;

        -- 3 < 5 => 1
        a_i <= x"00000003";
        b_i <= x"00000005";
        wait for 10 ns;
        exp := exp_sltu(a_i, b_i);
        check_equal(y_o, exp, "SLTU 3<5 failed");

        -- 5 < 3 => 0
        a_i <= x"00000005";
        b_i <= x"00000003";
        wait for 10 ns;
        exp := exp_sltu(a_i, b_i);
        check_equal(y_o, exp, "SLTU 5<3 failed");

        -- 0xFFFFFFFF < 1 => 0
        a_i <= x"FFFFFFFF";
        b_i <= x"00000001";
        wait for 10 ns;
        exp := exp_sltu(a_i, b_i);
        check_equal(y_o, exp, "SLTU 0xFFFFFFFF<1 failed");

        -- 1 < 0xFFFFFFFF => 1
        a_i <= x"00000001";
        b_i <= x"FFFFFFFF";
        wait for 10 ns;
        exp := exp_sltu(a_i, b_i);
        check_equal(y_o, exp, "SLTU 1<0xFFFFFFFF failed");

        -- 0 < 0xFFFFFFFF => 1
        a_i <= x"00000000";
        b_i <= x"FFFFFFFF";
        wait for 10 ns;
        exp := exp_sltu(a_i, b_i);
        check_equal(y_o, exp, "SLTU 0x00000000<0xFFFFFFFF failed");

      end if;
    end loop;

    test_runner_cleanup(runner);
  end process;

end architecture arch;
