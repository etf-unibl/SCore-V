-----------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2025
-- https://github.com/etf-unibl/SCore-V/
-----------------------------------------------------------------------------
--
-- unit name: score_v_signature_tb
--
-- description:
--
--   Signature testbench for the top-level SCore-V processor.
--   Derives the number of instructions N automatically from the IMEM init
--   file (one hex byte per line, so N = line_count / 4) and runs the
--   processor for exactly N clock cycles after reset.
--   No result checking is performed.
--
-----------------------------------------------------------------------------
-- Copyright (c) 2025 Faculty of Electrical Engineering
-----------------------------------------------------------------------------
-- The MIT License
-----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

library vunit_lib;
context vunit_lib.vunit_context;

library design_lib;
use design_lib.mem_pkg.all;

entity score_v_signature_tb is
  generic (
    runner_cfg       : string;
    g_init_file      : string := "instruction_memory.txt";
    g_dmem_init_file : string := "data_memory.txt"
  );
end entity score_v_signature_tb;

architecture sim of score_v_signature_tb is

  constant CLK_PERIOD : time := 10 ns;

  signal clk_s        : std_logic := '0';
  signal rst_s        : std_logic := '1';
  signal sim_done_s   : std_logic := '0';

  signal instr_addr_s : std_logic_vector(31 downto 0);
  signal instr_mem_s  : t_instruction_rec;
  signal fetch_instr_s: t_instruction_rec;
  signal pc_s         : std_logic_vector(31 downto 0);
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

  -- Derive N from IMEM init file at elaboration time.
  -- The file has one hex byte per line, so N = line_count / 4.
  impure function count_imem_lines(file_name : in string) return integer
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
  end function count_imem_lines;

  constant c_NUM_INSTRUCTIONS : integer := count_imem_lines(g_init_file) / 4;

begin

  uut : entity design_lib.score_v
    generic map (
      g_dmem_init_file => g_dmem_init_file
    )
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
    generic map (
      g_INIT_FILE => g_init_file
    )
    port map (
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

  main_proc : process
  begin
    test_runner_setup(runner, runner_cfg);

    while test_suite loop
      if run("test_signature") then
        rst_s <= '1';
        wait until rising_edge(clk_s);
        rst_s <= '0';

        for i in 0 to c_NUM_INSTRUCTIONS - 1 loop
          wait until rising_edge(clk_s);
        end loop;

        info("Signature run complete: " &
             integer'image(c_NUM_INSTRUCTIONS) & " cycles executed.");
      end if;
    end loop;

    sim_done_s <= '1';
    test_runner_cleanup(runner);
    wait;
  end process;

end architecture sim;
