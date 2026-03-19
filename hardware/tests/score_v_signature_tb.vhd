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
--
--   After simulation, reads the signature region bounds from
--   hardware/conf_test_files/sig_values.txt (two hex 32-bit word addresses,
--   first = start address inclusive, second = end address inclusive) and
--   dumps that region of DMEM word-by-word into signature.txt.
--
--   DMEM is accessed via a VHDL-2008 external name alias -- no design
--   changes required. The alias is declared inside the process (not at
--   architecture level) so that NVC resolves it at simulation time, after
--   the full hierarchy has been elaborated.
--
--   NOTE: The external name path assumes the following instance label
--   hierarchy:
--     score_v_signature_tb -> uut (score_v)
--     score_v              -> u_lsu (load_store_unit)
--     load_store_unit      -> u_dmem (dmem)
--   If your labels differ, update the alias path accordingly.
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
    runner_cfg        : string;
    g_init_file       : string := "instruction_memory.txt";
    g_dmem_init_file  : string := "data_memory.txt";
    --! Path to the file containing the two hex signature-region addresses.
    --! Format: line 1 = start byte address (hex), line 2 = end byte address (hex),
    --! both inclusive and word-aligned.
    g_sig_values_file  : string := "sig_values.txt";
    --! Path where the output signature file will be written.
    g_sig_output_file  : string := "test.signature"
  );
end entity score_v_signature_tb;

architecture sim of score_v_signature_tb is

  constant CLK_PERIOD : time := 10 ns;

  signal clk_s        : std_logic := '0';
  signal rst_s        : std_logic := '1';
  signal sim_done_s   : std_logic := '0';

  signal instr_addr_s : std_logic_vector(31 downto 0);
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

  -- -------------------------------------------------------------------------
  -- Count non-blank lines in the IMEM init file (one hex byte per line).
  -- N instructions = line_count / 4.
  -- -------------------------------------------------------------------------
  impure function count_imem_lines(file_name : in string) return integer is
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
      g_dmem_init_file => g_dmem_init_file,
      g_IMEM_INIT_FILE => g_init_file
    )
    port map (
      clk_i        => clk_s,
      rst_i        => rst_s,
      instr_addr_o => instr_addr_s
    );

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
    -- -----------------------------------------------------------------------
    -- External name alias declared here (inside the process) so that NVC
    -- resolves it at simulation time, after the full hierarchy is elaborated.
    -- Declaring it at the architecture level causes NVC to fail because child
    -- instances have not yet been elaborated at that point.
    --
    -- Path: this TB -> uut (score_v) -> u_lsu (load_store_unit) -> u_dmem (dmem) -> mem
    -- -----------------------------------------------------------------------
    alias dmem_mem is
      <<signal .score_v_signature_tb.uut.u_lsu.u_dmem.mem : t_bytes>>;

    -- Signature region bounds read from sig_values.txt
    file     sig_val_file : text;
    variable l_val        : line;
    variable sig_start    : std_logic_vector(31 downto 0);
    variable sig_end      : std_logic_vector(31 downto 0);

    -- The signature addresses may be >= 0x80000000, which overflows VHDL's
    -- signed 32-bit INTEGER / NATURAL when passed to to_integer().
    -- Solution: compute a word offset from the start address (which is always
    -- a small non-negative integer representing how many words into the region
    -- we are), and add that to the DMEM array base index derived once from
    -- sig_start alone.
    --
    -- dmem_mem is indexed from 0, so the array index for byte address A equals
    -- A itself (byte-addressed).  We split this into:
    --   base_idx  = to_integer(unsigned(sig_start(30 downto 0)))
    --               -- drops bit 31, safe for addresses in upper 2 GB
    --               -- only valid because DMEM is sized from the init file and
    --               -- the signature region must lie within DMEM
    --   word_off  = 0, 1, 2, ... (word count from start, always small)
    --   byte_idx  = base_idx + word_off * 4
    variable base_idx     : natural;  -- byte index of sig_start within dmem_mem
    variable region_words : natural;  -- total words in the signature region
    variable word_off     : natural;  -- current word offset from base

    -- Output signature file
    file     sig_out_file : text;
    variable l_out        : line;
    variable word_bits    : std_logic_vector(31 downto 0);
    variable byte_idx     : natural;
  begin
    test_runner_setup(runner, runner_cfg);

    while test_suite loop
      if run("test_signature") then

        -- -----------------------------------------------------------------
        -- 1. Reset and run for exactly c_NUM_INSTRUCTIONS cycles
        -- -----------------------------------------------------------------
        rst_s <= '1';
        wait until rising_edge(clk_s);
        rst_s <= '0';

        for i in 0 to c_NUM_INSTRUCTIONS - 1 loop
          wait until rising_edge(clk_s);
        end loop;

        info("Signature run complete: " &
             integer'image(c_NUM_INSTRUCTIONS) & " cycles executed.");

        -- -----------------------------------------------------------------
        -- 2. Read signature region bounds from sig_values.txt
        --    Line 1: start byte address (8 hex chars, e.g. 80201110)
        --    Line 2: end   byte address (8 hex chars, e.g. 80201A50)
        --    Both addresses are inclusive and word-aligned (multiple of 4).
        -- -----------------------------------------------------------------
        file_open(sig_val_file, g_sig_values_file, read_mode);

        readline(sig_val_file, l_val);
        hread(l_val, sig_start);

        readline(sig_val_file, l_val);
        hread(l_val, sig_end);

        file_close(sig_val_file);

        info("Dumping DMEM signature region: 0x" &
             to_hstring(sig_start) & " .. 0x" & to_hstring(sig_end));

        -- -----------------------------------------------------------------
        -- Compute base_idx and region_words without ever calling to_integer
        -- on a value >= 0x80000000.
        --
        -- The DMEM array is always allocated starting at index 0, so byte
        -- address A maps to dmem_mem(A).  For addresses in the upper half of
        -- the 32-bit space bit 31 = '1', which makes to_integer(unsigned)
        -- overflow the signed INTEGER type in NVC.
        --
        -- Workaround: strip bit 31 from sig_start to get base_idx, then
        -- compute region size as (sig_end - sig_start + 4) / 4 words using
        -- 32-bit unsigned subtraction (result is always small and positive).
        -- -----------------------------------------------------------------
        base_idx     := to_integer(unsigned('0' & sig_start(30 downto 0)));
        region_words := to_integer(
                          unsigned(sig_end) - unsigned(sig_start) + 4
                        ) / 4;

        -- -----------------------------------------------------------------
        -- 3. Dump region_words words starting at dmem_mem(base_idx).
        --
        --    DMEM is little-endian byte-addressed:
        --      byte addr N+0 = bits  7:0  of the stored word
        --      byte addr N+1 = bits 15:8
        --      byte addr N+2 = bits 23:16
        --      byte addr N+3 = bits 31:24
        --
        --    Reassembled as big-endian hex so the output matches the
        --    original data_memory.txt word format.
        -- -----------------------------------------------------------------
        file_open(sig_out_file, g_sig_output_file, write_mode);

        for word_off in 0 to region_words - 1 loop
          byte_idx  := base_idx + word_off * 4;
          word_bits := dmem_mem(byte_idx + 3) &
                       dmem_mem(byte_idx + 2) &
                       dmem_mem(byte_idx + 1) &
                       dmem_mem(byte_idx);

          hwrite(l_out, word_bits);
          writeline(sig_out_file, l_out);
        end loop;

        file_close(sig_out_file);

        info("Signature dump complete -> signature.txt");

      end if;
    end loop;

    sim_done_s <= '1';
    test_runner_cleanup(runner);
    wait;
  end process;

end architecture sim;
