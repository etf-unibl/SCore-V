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

library vunit_lib;
context vunit_lib.vunit_context;

library design_lib;
use design_lib.mem_pkg.all;

entity instruction_decoder_tb is
  generic (runner_cfg : string);
end instruction_decoder_tb;

architecture arch of instruction_decoder_tb
is

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

  uut : entity design_lib.instruction_decoder
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
    test_runner_setup(runner, runner_cfg);

    while test_suite loop

      if run("test_instructions") then
        info("Testing instructions");
        for i in c_TEST_VECTORS'range loop
          instr_rec_s.opcode <= c_TEST_VECTORS(i).instr_32(6 downto 0);
          instr_rec_s.other_instruction_bits <= c_TEST_VECTORS(i).instr_32(31 downto 7);

          wait for c_CLK_PERIOD;

          if opcode_s /= c_TEST_VECTORS(i).exp_opcode then
            failure("Opcode mismatch at index " & integer'image(i));
          end if;

          if rs1_s /= c_TEST_VECTORS(i).exp_rs1 then
            failure("RS1 mismatch at index " & integer'image(i));
          end if;

          if rs2_s /= c_TEST_VECTORS(i).exp_rs2 then
            failure("RS2 mismatch at index " & integer'image(i));
          end if;

          if rd_s /= c_TEST_VECTORS(i).exp_rd then
            failure("RD mismatch at index " & integer'image(i));
          end if;

          if funct3_s /= c_TEST_VECTORS(i).exp_f3 then
            failure("Funct3 mismatch at index " & integer'image(i));
          end if;

          if funct7_s /= c_TEST_VECTORS(i).exp_f7 then
            failure("Funct7 mismatch at index " & integer'image(i));
          end if;

          if imm_i_type_s /= c_TEST_VECTORS(i).exp_imm_i then
            failure("Imm_I mismatch at index" & integer'image(i));
          end if;

        end loop;
      end if;
    end loop;

    test_runner_cleanup(runner);
    wait;
  end process stimulus_check;
end architecture arch;
