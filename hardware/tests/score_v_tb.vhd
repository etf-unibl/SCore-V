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
use work.mem_pkg.all;

entity score_v_tb is
end entity score_v_tb;

architecture sim of score_v_tb is

  component score_v is
    port (
      clk_i        : in  std_logic;
      rst_i        : in  std_logic;

      instr_addr_o : out std_logic_vector(31 downto 0);
      instr_data_i : in  t_instruction_rec;

      pc_o         : out std_logic_vector(31 downto 0);
      opcode_o     : out std_logic_vector(6 downto 0);
      rd_o         : out std_logic_vector(4 downto 0);
      rs1_o        : out std_logic_vector(4 downto 0);
      rs2_o        : out std_logic_vector(4 downto 0);
      rs1_data_o   : out std_logic_vector(31 downto 0);
      rs2_data_o   : out std_logic_vector(31 downto 0);
      alu_result_o : out std_logic_vector(31 downto 0);
      reg_we_o     : out std_logic
    );
  end component;

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

  constant CLK_PERIOD : time := 10 ns;

  component fetch_instruction is
    port (
      instruction_count_i : in  std_logic_vector(31 downto 0);
      instruction_bits_o  : out t_instruction_rec
    );
  end component;

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
    0 => (0,  "0110011", "000", "0000000", 15, 1, 1, 6, '1'),
    1 => (4,  "0110011", "000", "0000000", 7,  3, 1, 3, '1'),
    2 => (8,  "0110011", "000", "0000000", 15, 7, 1, 6, '1'),
    3 => (12, "0110011", "000", "0000000", 15, 15,1, 9, '1'),
    4 => (16, "0110011", "000", "0000000", 15, 31,1, 3, '1'),
    5 => (20, "0000000", "000", "1011001", 0,  0, 0, 0, '0'),
    6 => (24, "0000000", "000", "1011001", 0,  0, 0, 0, '0'),
    7 => (28, "0000000", "000", "1011001", 0,  0, 0, 0, '0')
  );

begin

  uut : score_v
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
      reg_we_o     => reg_we_s
    );

  u_fetch : fetch_instruction
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

  stim_proc : process
  begin
    rst_s <= '1';
    wait for CLK_PERIOD;
    rst_s <= '0';
    wait;
  end process;

  monitor_proc : process
    variable full_instr : std_logic_vector(31 downto 0);
    variable step       : integer := 0;
  begin
    while sim_done_s = '0' loop
      wait until rising_edge(clk_s);

      if rst_s = '0' then
        full_instr := instr_mem_s.other_instruction_bits & instr_mem_s.opcode;

        if step <= res'high then
          assert to_integer(unsigned(pc_s)) = res(step).pc
            report "PC ERROR at step " & integer'image(step)
            severity failure;

          assert opcode_s = res(step).opcode
            report "OPCODE ERROR at step " & integer'image(step)
            severity failure;

          assert full_instr(14 downto 12) = res(step).funct3
            report "FUNCT3 ERROR at step " & integer'image(step)
            severity failure;

          assert full_instr(31 downto 25) = res(step).funct7
            report "FUNCT7 ERROR at step " & integer'image(step)
            severity failure;

          assert to_integer(unsigned(rd_addr_s)) = res(step).rd
            report "RD ERROR at step " & integer'image(step)
            severity failure;

          assert to_integer(unsigned(rs1_addr_s)) = res(step).rs1
            report "RS1 ERROR at step " & integer'image(step)
            severity failure;

          assert to_integer(unsigned(rs2_addr_s)) = res(step).rs2
            report "RS2 ERROR at step " & integer'image(step) &
                   " | RS2_ADDR_s = " & integer'image(to_integer(unsigned(rs2_addr_s))) &
                   " | expected = " & integer'image(res(step).rs2)
            severity failure;

          assert to_integer(unsigned(alu_result_s)) = res(step).alu_out
            report "ALU ERROR at step " & integer'image(step)
            severity failure;

          assert reg_we_s = res(step).we
            report "WE ERROR at step " & integer'image(step)
            severity failure;

          step := step + 1;
        else
          assert false report "All tests passed!" severity note;
          sim_done_s <= '1';
        end if;
      end if;
    end loop;

    wait;
  end process;

end architecture sim;
