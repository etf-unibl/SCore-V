-----------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2025
-- https://github.com/etf-unibl/SCore-V/
-----------------------------------------------------------------------------
--
-- unit name: score_v_tb
--
-- description:
--
--   Testbench for the top-level SCore-V integration unit (score_v).
--   It instantiates the full datapath and provides: clock generation,
--   reset sequencing, basic simulation control, monitoring of PC,
--   instruction fields, ALU result and write back to registers.
--
--   The monitor process reconstructs the 32-bit instruction from the
--   instruction record and reports decoded fields and execution results.
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
-- OTHER DEALINGS IN THE SOFTWARE.
-----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;  
context vunit_lib.vunit_context;
library design_lib;

library design_lib;
use design_lib.mem_pkg.all;

entity score_v_tb is
  generic (runner_cfg : string);
end entity score_v_tb;

architecture sim of score_v_tb is

  signal clk_s        : std_logic := '0';
  signal rst_s        : std_logic := '1';
  signal sim_done_s   : std_logic := '0';

  signal pc_s         : std_logic_vector(31 downto 0);
  signal instr_addr_s : std_logic_vector(31 downto 0);
  signal instr_mem_s  : t_instruction_rec;
  signal opcode_s     : std_logic_vector(6 downto 0);
  signal rd_addr_s    : std_logic_vector(4 downto 0);
  signal rs1_addr_s   : std_logic_vector(4 downto 0);
  signal rs2_addr_s   : std_logic_vector(4 downto 0);
  signal rs1_data_s   : std_logic_vector(31 downto 0);
  signal rs2_data_s   : std_logic_vector(31 downto 0);
  signal alu_result_s : std_logic_vector(31 downto 0);
  signal reg_we_s     : std_logic;
  signal mem_data_s   : std_logic_vector(31 downto 0);
  signal wb_data_s    : std_logic_vector(31 downto 0);

  constant CLK_PERIOD : time := 10 ns;

  signal fetch_instr_s : t_instruction_rec;

  type expected_rec is record
    pc      : integer;
    opcode  : std_logic_vector(6 downto 0);
    funct3  : std_logic_vector(2 downto 0);
    funct7  : std_logic_vector(6 downto 0);
    rd      : integer;
    rs1     : integer;
    rs2     : integer;
    alu_out : integer;
    we      : std_logic;
  end record;

  type expected_array is array (natural range <>) of expected_rec;

  -- res reference values correspond to the instruction sequence
  -- currently stored in IMEM. The expected PC, decode fields, ALU result
  -- and write-enable behavior are verified according to the program
  -- preloaded in instruction memory.
  -- IMPORTANT:
  -- If the content of c_IMEM changes, this table must be updated
  -- accordingly, since verification is strictly bound to that program.
  constant res : expected_array := (
    0  => (0,  "0110011", "000", "0000000", 15, 1, 1, 6, '1'),
    1  => (4,  "0110011", "000", "0000000", 7,  3, 1, 3, '1'),
    2  => (8,  "0110011", "000", "0000000", 15, 7, 1, 6, '1'),
    3  => (12, "0110011", "000", "0000000", 15, 15,1, 9, '1'),
    4  => (16, "0110011", "000", "0000000", 15, 31,1, 3, '1'),
    5  => (20, "0010011", "000", "0000000", 1, 0, 0, 10, '1'),
    6  => (24, "0010011", "000", "0000000", 2, 0, 0, -5, '1'),
    7  => (28, "0010011", "000", "0000000", 3, 1, 0, 12, '1'),
    8  => (32, "0000011", "010", "0000000", 2, 0, 0,  0, '1'),
    9  => (36, "0000011", "010", "0000000", 1, 0, 0,  8, '1'),
    10 => (40, "0100011", "010", "0000000", 0, 0, 1, 25, '0'),
    11 => (44, "0110011", "000", "0100000", 16, 4, 5, -2, '1')
  );

begin

  uut : entity design_lib.score_v
    port map (
      clk_i        => clk_s,
      rst_i        => rst_s,
      instr_addr_o => instr_addr_s,
      instr_data_i => instr_mem_s,
      pc_o         => pc_s,
      opcode_o     => opcode_s,
      rd_o         => rd_addr_s,
      rs1_o        => rs1_addr_s,
      rs2_o        => rs2_addr_s,
      rs1_data_o   => rs1_data_s,
      rs2_data_o   => rs2_data_s,
      alu_result_o => alu_result_s,
      reg_we_o     => reg_we_s,
      mem_data_o   => mem_data_s,
      wb_data_o    => wb_data_s
    );

  u_fetch : entity design_lib.fetch_instruction
    port map(
      instruction_count_i => instr_addr_s,
      instruction_bits_o  => fetch_instr_s
    );

  instr_mem_s <= fetch_instr_s;

  clk_process : process
  begin
    while sim_done_s = '0' loop
      clk_s <= '0';
      wait for CLK_PERIOD / 2;
      clk_s <= '1';
      wait for CLK_PERIOD / 2;
    end loop;
    wait;
  end process;

  monitor_proc : process
    variable full_instr : std_logic_vector(31 downto 0);
    variable step       : integer := 0;
  begin
    test_runner_setup(runner, runner_cfg);

    while test_suite loop
      if run("test_reset") then
        info("Testing reset function of score_v");
        rst_s <= '1';
        wait until rising_edge(clk_s);

      elsif run("test_score_v") then
        rst_s <= '1';
        wait until rising_edge(clk_s);
        rst_s <= '0';

        for i in 0 to 12 loop
          wait until rising_edge(clk_s);
          full_instr := instr_mem_s.other_instruction_bits & instr_mem_s.opcode;

          if step <= res'high then
            check_equal(to_integer(unsigned(pc_s)), res(step).pc, "PC Error at step " & integer'image(step));

            check_equal(opcode_s, res(step).opcode, "OPCODE Error at step " & integer'image(step));

            check_equal(full_instr(14 downto 12), res(step).funct3, "FUNCT3 Error at step " & integer'image(step));

            if opcode_s = "0110011" then 
              check_equal(full_instr(31 downto 25), res(step).funct7, "FUNCT7 Error at step " & integer'image(step));
            end if;

            check_equal(to_integer(unsigned(rd_addr_s)), res(step).rd, "RD Error at step " & integer'image(step));

            check_equal(to_integer(unsigned(rs1_addr_s)), res(step).rs1, "RS1 Error at step " & integer'image(step));

            check_equal(to_integer(unsigned(rs2_addr_s)), res(step).rs2, "RS2 Error at step " & integer'image(step) &
                                                                        " | RS2_ADDR_s = " & integer'image(to_integer(unsigned(rs2_addr_s))) &
                                                                        " | expected = " & integer'image(res(step).rs2));
            check_equal(to_integer(signed(alu_result_s)), res(step).alu_out, "ALU Error at step " & integer'image(step));

            check_equal(reg_we_s, res(step).we, "WE Error at step " & integer'image(step));
            step := step + 1;
          else
            test_runner_cleanup(runner);
            sim_done_s <= '1';
          end if;
        end loop;
      end if;
    end loop;

    test_runner_cleanup(runner);
    wait;
  end process;

end architecture sim;
