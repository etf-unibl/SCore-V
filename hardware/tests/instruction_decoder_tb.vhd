-----------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2025
-- https://github.com/etf-unibl/SCore-V
-----------------------------------------------------------------------------
--
-- unit name: instruction_decoder_tb
--
-- description:
--
--   Self-checking testbench for instruction_decoder.
--   Uses a directed test-vector table that contains 32-bit instructions and
--   expected extracted fields to verify the decoder logic.
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
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
-- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
-- DEALINGS IN THE SOFTWARE.
-----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.mem_pkg.all;

entity instruction_decoder_tb is
end instruction_decoder_tb;

architecture arch of instruction_decoder_tb
is

  component instruction_decoder is
    port (
      instr_i        : in  t_instruction_rec;
      opcode_o       : out std_logic_vector(6 downto 0);
      rs1_o          : out std_logic_vector(4 downto 0);
      rs2_o          : out std_logic_vector(4 downto 0);
      rd_o           : out std_logic_vector(4 downto 0);
      funct3_o       : out std_logic_vector(2 downto 0);
      funct7_o       : out std_logic_vector(6 downto 0);
      imm_i_type_o   : out std_logic_vector(11 downto 0);
      imm_s_type_h_o : out std_logic_vector(6 downto 0);
      imm_s_type_l_o : out std_logic_vector(4 downto 0)
    );
  end component instruction_decoder;

  signal instr_rec_s    : t_instruction_rec;
  signal opcode_s       : std_logic_vector(6 downto 0);
  signal rs1_s          : std_logic_vector(4 downto 0);
  signal rs2_s          : std_logic_vector(4 downto 0);
  signal rd_s           : std_logic_vector(4 downto 0);
  signal funct3_s       : std_logic_vector(2 downto 0);
  signal funct7_s       : std_logic_vector(6 downto 0);
  signal imm_i_type_s   : std_logic_vector(11 downto 0);
  signal imm_s_type_h_s : std_logic_vector(6 downto 0);
  signal imm_s_type_l_s : std_logic_vector(4 downto 0);

  constant c_CLK_PERIOD : time := 20 ns;

  type t_test_vector is record
    instr_32    : std_logic_vector(31 downto 0);
    exp_opcode  : std_logic_vector(6 downto 0);
    exp_rs1     : std_logic_vector(4 downto 0);
    exp_rs2     : std_logic_vector(4 downto 0);
    exp_rd      : std_logic_vector(4 downto 0);
    exp_f3      : std_logic_vector(2 downto 0);
    exp_f7      : std_logic_vector(6 downto 0);
    exp_imm_i   : std_logic_vector(11 downto 0);
    exp_imm_s_h : std_logic_vector(6 downto 0);
    exp_imm_s_l : std_logic_vector(4 downto 0);
  end record t_test_vector;

  type t_test_vector_array is array(natural range <>) of t_test_vector;

  constant c_TEST_VECTORS : t_test_vector_array := (
    -- R-type: add x3, x1, x2
    (x"002081B3", "0110011", "00001", "00010", "00011", "000", "0000000",
     x"000",      "0000000", "00000"),

    -- I-type: addi x5, x1, 10
    (x"00A08293", "0010011", "00001", "00000", "00101", "000", "0000000",
     x"00A",      "0000000", "00000"),

    -- S-type: sw x2, 4(x1)
    (x"0020A223", "0100011", "00001", "00010", "00000", "010", "0000000",
     x"000",      "0000000", "00100")
  );

begin

  uut : instruction_decoder
    port map (
      instr_i        => instr_rec_s,
      opcode_o       => opcode_s,
      rs1_o          => rs1_s,
      rs2_o          => rs2_s,
      rd_o           => rd_s,
      funct3_o       => funct3_s,
      funct7_o       => funct7_s,
      imm_i_type_o   => imm_i_type_s,
      imm_s_type_h_o => imm_s_type_h_s,
      imm_s_type_l_o => imm_s_type_l_s
    );

  stimulus_check : process
  begin
    for i in c_TEST_VECTORS'range loop
      instr_rec_s.opcode <= c_TEST_VECTORS(i).instr_32(6 downto 0);
      instr_rec_s.other_instruction_bits <= c_TEST_VECTORS(i).instr_32(31 downto 7);

      wait for c_CLK_PERIOD;

      assert opcode_s = c_TEST_VECTORS(i).exp_opcode
        report "Opcode mismatch at index " & integer'image(i)
        severity error;

      assert rs1_s = c_TEST_VECTORS(i).exp_rs1
        report "RS1 mismatch at index " & integer'image(i)
        severity error;

      assert rs2_s = c_TEST_VECTORS(i).exp_rs2
        report "RS2 mismatch at index " & integer'image(i)
        severity error;

      assert rd_s = c_TEST_VECTORS(i).exp_rd
        report "RD mismatch at index " & integer'image(i)
        severity error;

      assert funct3_s = c_TEST_VECTORS(i).exp_f3
        report "Funct3 mismatch at index " & integer'image(i)
        severity error;

      assert funct7_s = c_TEST_VECTORS(i).exp_f7
        report "Funct7 mismatch at index " & integer'image(i)
        severity error;

      assert imm_i_type_s = c_TEST_VECTORS(i).exp_imm_i
        report "Imm_I mismatch at index " & integer'image(i)
        severity error;

      report "Test " & integer'image(i) & " completed successfully."
        severity note;
    end loop;

    assert false
      report "Simulation successfully completed."
      severity note;

    wait;
  end process stimulus_check;

end architecture arch;
