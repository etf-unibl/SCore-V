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
--   Expected results are loaded at elaboration time from a comma-separated
--   file whose path is passed via the g_expected_file generic. The file
--   format per line is:
--     pc, "opcode", "funct3", "funct7", rd, rs1, rs2, alu_out, wb_out, 'we'
--   Blank lines are ignored. Integer fields may be negative.
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
use std.textio.all;

library vunit_lib;
context vunit_lib.vunit_context;

library design_lib;
use design_lib.mem_pkg.all;

entity score_v_tb is
  generic (
    runner_cfg       : string;
    g_init_file      : string := "instruction_memory.txt";
    g_dmem_init_file : string := "data_memory.txt";
    g_expected_file  : string := "expected.txt"
  );
end entity score_v_tb;

architecture sim of score_v_tb is

  signal clk_s        : std_logic := '0';
  signal rst_s        : std_logic := '1';
  signal sim_done_s   : std_logic := '0';

  signal instr_addr_s : std_logic_vector(31 downto 0);
  signal instr_mem_s  : t_instruction_rec;

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
    wb_out  : integer;
    we      : std_logic;
  end record;

  type expected_array is array (natural range <>) of expected_rec;

  --! @brief Maximum number of expected entries the file can contain.
  constant c_MAX_EXPECTED : integer := 2048;

  --! @brief Empty record used to pad unused slots in the result array.
  constant c_EMPTY_REC : expected_rec := (
    pc      => 0,
    opcode  => "0000000",
    funct3  => "000",
    funct7  => "0000000",
    rd      => 0,
    rs1     => 0,
    rs2     => 0,
    alu_out => 0,
    wb_out  => 0,
    we      => '0'
  );

  --! @brief Counts the number of non-blank lines in the expected file.
  --! @param file_name Absolute path to the expected values file.
  --! @return Number of non-blank lines found.
  impure function count_expected_rows(file_name : in string) return integer
  is
    file     f_ptr : text;
    variable l     : line;
    variable n     : integer := 0;
  begin
    file_open(f_ptr, file_name, read_mode);
    while not endfile(f_ptr) loop
      readline(f_ptr, l);
      if l'length > 0 then
        n := n + 1;
      end if;
    end loop;
    file_close(f_ptr);
    return n;
  end function count_expected_rows;

  --! @brief Parses a comma-separated expected-results file into an expected_array.
  --! @details Each line format:
  --!   pc, "opcode", "funct3", "funct7", rd, rs1, rs2, alu_out, wb_out, 'we'
  --!   Binary fields are double-quoted, we is single-quoted.
  --!   Integer fields may be negative. Blank lines are skipped.
  --! @param file_name Absolute path to the expected values file.
  --! @return Populated expected_array padded with c_EMPTY_REC up to c_MAX_EXPECTED.
  impure function parse_expected_file(file_name : in string) return expected_array is
    file     f_ptr  : text;
    variable l      : line;
    variable result : expected_array(0 to c_MAX_EXPECTED - 1) := (others => c_EMPTY_REC);
    variable row    : integer := 0;
    variable ch     : character;
    variable good   : boolean;
    variable slv7   : std_logic_vector(6 downto 0);
    variable slv3   : std_logic_vector(2 downto 0);

    --! @brief Read one integer (possibly negative) stopping at the next non-digit.
    procedure get_int(variable li : inout line; variable val : out integer) is
      variable ci   : character;
      variable gi   : boolean;
      variable acc  : integer := 0;
      variable neg  : boolean := false;
    begin
      while li'length > 0 loop read(li, ci); exit when ci /= ' ' and ci /= ','; end loop;
      if ci = '-' then neg := true; read(li, ci, gi); end if;
      while ci >= '0' and ci <= '9' loop
        acc := acc * 10 + (character'pos(ci) - character'pos('0'));
        exit when li'length = 0;
        read(li, ci, gi);
      end loop;
      if neg then val := -acc; else val := acc; end if;
    end procedure;

  begin
    file_open(f_ptr, file_name, read_mode);
    while not endfile(f_ptr) and row < c_MAX_EXPECTED loop
      readline(f_ptr, l);
      next when l'length = 0;

      -- pc
      get_int(l, result(row).pc);

      -- opcode (7-bit binary, double-quoted)
      while l'length > 0 loop read(l, ch); exit when ch = '"'; end loop;
      for i in 6 downto 0 loop
        read(l, ch, good);
        slv7(i) := '1' when ch = '1' else '0';
      end loop;
      read(l, ch, good);
      result(row).opcode := slv7;

      -- funct3 (3-bit binary, double-quoted)
      while l'length > 0 loop read(l, ch); exit when ch = '"'; end loop;
      for i in 2 downto 0 loop
        read(l, ch, good);
        slv3(i) := '1' when ch = '1' else '0';
      end loop;
      read(l, ch, good);
      result(row).funct3 := slv3;

      -- funct7 (7-bit binary, double-quoted)
      while l'length > 0 loop read(l, ch); exit when ch = '"'; end loop;
      for i in 6 downto 0 loop
        read(l, ch, good);
        slv7(i) := '1' when ch = '1' else '0';
      end loop;
      read(l, ch, good);
      result(row).funct7 := slv7;

      -- rd, rs1, rs2, alu_out, wb_out
      get_int(l, result(row).rd);
      get_int(l, result(row).rs1);
      get_int(l, result(row).rs2);
      get_int(l, result(row).alu_out);
      get_int(l, result(row).wb_out);

      -- we (std_logic, single-quoted)
      while l'length > 0 loop read(l, ch); exit when ch = '''; end loop;
      read(l, ch, good);
      result(row).we := '1' when ch = '1' else '0';

      row := row + 1;
    end loop;
    file_close(f_ptr);
    return result;
  end function parse_expected_file;

  --! @brief Number of valid entries in res, counted from g_expected_file.
  constant c_VALID_COUNT : integer := count_expected_rows(g_expected_file);

  --! @brief Expected results loaded from g_expected_file at elaboration time.
  constant res : expected_array(0 to c_MAX_EXPECTED - 1) :=
    parse_expected_file(g_expected_file);

begin

  uut : entity design_lib.score_v
    generic map (
      g_dmem_init_file => g_dmem_init_file,
	  g_IMEM_INIT_FILE => g_init_file
    )
    port map (
      clk_i        => clk_s,
      rst_i        => rst_s,
      instr_addr_o => instr_addr_s
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
  
    alias dbg_pc         is << signal .score_v_tb.uut.pc_sig : std_logic_vector(31 downto 0) >>;
    alias dbg_opcode     is << signal .score_v_tb.uut.opcode_sig : std_logic_vector(6 downto 0) >>;
    alias dbg_rd_addr    is << signal .score_v_tb.uut.rd_sig : std_logic_vector(4 downto 0) >>;
    alias dbg_rs1_addr   is << signal .score_v_tb.uut.rs1_sig : std_logic_vector(4 downto 0) >>;
    alias dbg_rs2_addr   is << signal .score_v_tb.uut.rs2_sig : std_logic_vector(4 downto 0) >>;
    alias dbg_alu_result is << signal .score_v_tb.uut.alu_result_sig : std_logic_vector(31 downto 0) >>;
    alias dbg_reg_we     is << signal .score_v_tb.uut.reg_we_sig : std_logic >>;
    alias dbg_wb_data    is << signal .score_v_tb.uut.final_wb_sig : std_logic_vector(31 downto 0) >>;
    alias dbg_instr      is << signal .score_v_tb.uut.instr_sig : t_instruction_rec >>;
    
    variable full_instr : std_logic_vector(31 downto 0);
    variable step       : integer := 0;
  begin
    test_runner_setup(runner, runner_cfg);

    while test_suite loop
      if run("test_reset") then
        rst_s <= '1';
        wait until rising_edge(clk_s);

      elsif run("test_score_v") then
        rst_s <= '1';
        wait until rising_edge(clk_s);
        rst_s <= '0';

        for i in 0 to c_VALID_COUNT - 1 loop
          wait until rising_edge(clk_s);

          full_instr := dbg_instr.other_instruction_bits & dbg_instr.opcode;

          if step <= c_VALID_COUNT - 1 then
            check_equal(to_integer(unsigned(dbg_pc)), res(step).pc, "PC Error at step " & integer'image(step));

            if dbg_opcode = "0110111" or dbg_opcode = "0010111" then
              check_equal(0, res(step).funct3, "FUNCT3 Error at step " & integer'image(step));
            else
              check_equal(full_instr(14 downto 12), res(step).funct3, "FUNCT3 Error at step " & integer'image(step));
            end if;

            if dbg_opcode = "0110011" then
              check_equal(full_instr(31 downto 25), res(step).funct7, "FUNCT7 Error at step " & integer'image(step));
            end if;

            check_equal(to_integer(unsigned(dbg_rd_addr)), res(step).rd, "RD Error at step " & integer'image(step));
            check_equal(to_integer(unsigned(dbg_rs1_addr)), res(step).rs1, "RS1 Error at step " & integer'image(step));
            check_equal(to_integer(unsigned(dbg_rs2_addr)), res(step).rs2,
              "RS2 Error at step " & integer'image(step) &
              " | RS2_ADDR_s = " & integer'image(to_integer(unsigned(dbg_rs2_addr))) &
              " | expected = " & integer'image(res(step).rs2));
            check_equal(to_integer(signed(dbg_alu_result)), res(step).alu_out, "ALU Error at step " & integer'image(step));

            if dbg_reg_we = '1' then
              check_equal(to_integer(signed(dbg_wb_data)), res(step).wb_out, "WB Error at step " & integer'image(step));
            end if;

            check_equal(dbg_reg_we, res(step).we, "WE Error at step " & integer'image(step));
			
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
