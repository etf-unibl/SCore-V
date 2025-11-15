-----------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2025
-- https://github.com/etf-unibl/pds-2025/
-----------------------------------------------------------------------------
--
-- unit name:     alu_tb
--
-- description:   Self-checking testbench for alu
--   
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

entity alu_tb is
end alu_tb;

architecture arch of alu_tb is

  component alu is
    port (
      a_i : in  std_logic_vector(31 downto 0);
      b_i : in  std_logic_vector(31 downto 0);
      y_o : out std_logic_vector(31 downto 0)
    );
  end component;

  signal a_i : std_logic_vector(31 downto 0) := (others => '0');
  signal b_i : std_logic_vector(31 downto 0) := (others => '0');
  signal y_o : std_logic_vector(31 downto 0);

  -- expected = (a + b) mod 2^32
  function exp_add(a, b : std_logic_vector(31 downto 0)) return std_logic_vector is
    variable s : unsigned(31 downto 0);
  begin
    s := unsigned(a) + unsigned(b);
    return std_logic_vector(s);
  end function;

  -- VHDL-93 HEX helpers (zamjena za to_hstring)
  function hex_char(n : std_logic_vector(3 downto 0)) return character is
  begin
    case n is
      when "0000" => return '0';
      when "0001" => return '1';
      when "0010" => return '2';
      when "0011" => return '3';
      when "0100" => return '4';
      when "0101" => return '5';
      when "0110" => return '6';
      when "0111" => return '7';
      when "1000" => return '8';
      when "1001" => return '9';
      when "1010" => return 'A';
      when "1011" => return 'B';
      when "1100" => return 'C';
      when "1101" => return 'D';
      when "1110" => return 'E';
      when others => return 'F';
    end case;
  end function;

  function slv_to_hex(v : std_logic_vector(31 downto 0)) return string is
    variable s : string(1 to 8);
    variable nib : std_logic_vector(3 downto 0);
  begin
    for i in 0 to 7 loop
      nib := v(31 - 4*i downto 28 - 4*i);
      s(i+1) := hex_char(nib);
    end loop;
    return s;
  end function;

begin

  uut : alu
    port map (
      a_i => a_i,
      b_i => b_i,
      y_o => y_o
    );

  stim_proc : process
    procedure apply_and_check(
      constant a : std_logic_vector(31 downto 0);
      constant b : std_logic_vector(31 downto 0)
    ) is
      variable exp : std_logic_vector(31 downto 0);
    begin
      a_i <= a;
      b_i <= b;
      wait for 1 ns;

      exp := exp_add(a, b);

      assert y_o = exp
        report "ALU ADD mismatch: a=" & slv_to_hex(a) &
               " b=" & slv_to_hex(b) &
               " y=" & slv_to_hex(y_o) &
               " exp=" & slv_to_hex(exp)
        severity error;
    end procedure;
  begin

    apply_and_check(x"00000000", x"00000000");
    apply_and_check(x"00000001", x"00000001");
    apply_and_check(x"00000002", x"00000003");

    apply_and_check(x"FFFFFFFF", x"00000001");
    apply_and_check(x"7FFFFFFF", x"00000001");
    apply_and_check(x"80000000", x"80000000");
    apply_and_check(x"55555555", x"AAAAAAAA");
	 apply_and_check(x"FFFFFFFF", x"00000002");

    wait for 5 ns;
    assert false report "ALU TB finished." severity failure;
  end process;

end architecture arch;



	 