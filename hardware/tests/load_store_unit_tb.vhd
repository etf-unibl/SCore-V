-----------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2025
-- https://github.com/etf-unibl/SCore-V/
-----------------------------------------------------------------------------
--
-- unit name: load store unit testbench
--
-- description:
--
--   This file implements testbench for load and store operations on DMEM.
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
use std.textio.all;

library vunit_lib;
context vunit_lib.vunit_context;

library design_lib;
use design_lib.mem_pkg.all;

entity load_store_unit_tb is
  generic (
    runner_cfg  : string;
    --! @brief Absolute path to data_memory.txt, set by run.py.
    g_init_file : string := "data_memory.txt"
  );
end load_store_unit_tb;

architecture arch of load_store_unit_tb is

  signal clk_s        : std_logic := '0';
  signal rst_s        : std_logic := '0';
  signal addr_s       : std_logic_vector(31 downto 0) := (others => '0');
  signal mem_RW_s     : std_logic := '0';
  signal data_write_s : std_logic_vector(31 downto 0) := (others => '0');
  signal data_read_s  : std_logic_vector(31 downto 0) := (others => '0');
  signal sim_stop_s   : std_logic := '0';
  signal sign_s       : std_logic;
  signal width_s      : std_logic_vector(1 downto 0);
  signal invalid_addr_s      : std_logic;
  signal misaligned_access_s : std_logic;
  signal mem_en_s     : std_logic;

  signal word_to_write : std_logic_vector(31 downto 0) := (others => '0');
  constant c_CLK_PERIOD : time := 10 ns;

begin

  uut : entity design_lib.load_store_unit
    generic map (
      g_init_file => g_init_file
    )
    port map (
	  mem_en_i     => mem_en_s,
      clk_i        => clk_s,
      rst_i        => rst_s,
      addr_i       => addr_s,
      mem_RW_i     => mem_RW_s,
      data_write_i => data_write_s,
      data_read_o  => data_read_s,
      sign_i       => sign_s,
      width_i      => width_s,
      invalid_addr_o => invalid_addr_s,
      misaligned_access_o => misaligned_access_s
    );

  clk_process : process
  begin
    while sim_stop_s = '0' loop
      clk_s <= '0';
      wait for c_CLK_PERIOD/2;
      clk_s <= '1';
      wait for c_CLK_PERIOD/2;
    end loop;
    wait;
  end process clk_process;

  main : process
    variable expected  : std_logic_vector(31 downto 0);
    variable written32 : std_logic_vector(31 downto 0);
    variable written16 : std_logic_vector(15 downto 0);
    variable written8  : std_logic_vector(7 downto 0);
  begin
    test_runner_setup(runner, runner_cfg);

    while test_suite loop
      if run("test_reset") then
        info("Testing reset function of load_store unit");
        expected := (others => '0');
        rst_s <= '1';
        wait until clk_s;
        if data_read_s /= expected then
          error("Reset not functioning on load store unit");
        end if;

      elsif run("test_store_word") then
        info("Testing store word (sw) function of load_store unit");

        -- Write 64 to addr 8, then read back to verify
        addr_s       <= std_logic_vector(to_unsigned(8, 32));
        data_write_s <= std_logic_vector(to_unsigned(64, 32));
        width_s      <= "10";
        sign_s       <= '1';
        mem_RW_s     <= '1';
        wait until rising_edge(clk_s);
        wait for 1 ns;
        mem_RW_s <= '0';
        wait for c_CLK_PERIOD;
        if data_read_s /= data_write_s then
          error("Expected " & to_string(data_write_s) & ", got " & to_string(data_read_s));
        end if;

        -- Write 64 to addr 4, then read back to verify
        addr_s       <= std_logic_vector(to_unsigned(4, 32));
        data_write_s <= std_logic_vector(to_unsigned(64, 32));
        mem_RW_s     <= '1';
        wait until rising_edge(clk_s);
        wait for 1 ns;
        mem_RW_s <= '0';
        wait for c_CLK_PERIOD;
        if data_read_s /= data_write_s then
          error("Expected " & to_string(data_write_s) & ", got " & to_string(data_read_s));
        end if;

        -- Out-of-bounds word write: expect invalid_addr_s = '1'
        addr_s       <= std_logic_vector(to_unsigned(1000, 32));
        data_write_s <= std_logic_vector(to_unsigned(63, 32));
        width_s      <= "10";
        mem_RW_s     <= '1';
        wait until rising_edge(clk_s);
        wait for 1 ns;
        check_equal(invalid_addr_s,      '1', "SW oob: invalid_addr should be '1'");
        check_equal(misaligned_access_s, '0', "SW oob: misaligned should be '0'");

        -- Check flags clear when write is de-asserted
        mem_RW_s <= '0';
        addr_s   <= std_logic_vector(to_unsigned(0, 32));
        wait until rising_edge(clk_s);
        wait until rising_edge(clk_s);
        wait for 1 ns;
        check_equal(invalid_addr_s,      '0', "SW oob: invalid_addr should clear");
        check_equal(misaligned_access_s, '0', "SW oob: misaligned should stay '0'");

        -- Negative address word write: expect invalid_addr_s = '1'
        addr_s       <= std_logic_vector(to_signed(-10, 32));
        data_write_s <= std_logic_vector(to_unsigned(63, 32));
        mem_RW_s     <= '1';
        wait until rising_edge(clk_s);
        wait for 1 ns;
        check_equal(invalid_addr_s,      '1', "SW neg: invalid_addr should be '1'");
        check_equal(misaligned_access_s, '0', "SW neg: misaligned should be '0'");
        mem_RW_s <= '0';
        addr_s   <= std_logic_vector(to_unsigned(0, 32));
        wait until rising_edge(clk_s);
        wait until rising_edge(clk_s);
        wait for 1 ns;
        check_equal(invalid_addr_s, '0', "SW neg: invalid_addr should clear");

        -- Misaligned word write (addr not 4-byte aligned): expect misaligned_access_s = '1'
        addr_s   <= std_logic_vector(to_unsigned(2, 32));
        mem_RW_s <= '1';
        wait until rising_edge(clk_s);
        wait for 1 ns;
        check_equal(misaligned_access_s, '1', "SW misaligned: misaligned should be '1'");
        check_equal(invalid_addr_s,      '0', "SW misaligned: invalid_addr should be '0'");
        mem_RW_s <= '0';
        addr_s   <= std_logic_vector(to_unsigned(0, 32));
        wait until rising_edge(clk_s);
        wait until rising_edge(clk_s);
        wait for 1 ns;
        check_equal(misaligned_access_s, '0', "SW misaligned: misaligned should clear");

        -- Verify recovery: valid write after exceptions should succeed cleanly
        addr_s       <= std_logic_vector(to_unsigned(4, 32));
        data_write_s <= std_logic_vector(to_unsigned(99, 32));
        mem_RW_s     <= '1';
        wait until rising_edge(clk_s);
        wait for 1 ns;
        check_equal(invalid_addr_s,      '0', "SW recovery: invalid_addr should be '0'");
        check_equal(misaligned_access_s, '0', "SW recovery: misaligned should be '0'");
        mem_RW_s <= '0';
        wait for c_CLK_PERIOD;
        check_equal(data_read_s, std_logic_vector(to_unsigned(99, 32)), "SW recovery: readback mismatch");

        info("Store word test passed");

      elsif run("test_store_half") then
        info("Testing store half word (sh) function of lsu");

        -- Write halfword to addr 4, read back lower 16 bits to verify
        width_s                   <= "01";
        sign_s                    <= '1';
        addr_s                    <= std_logic_vector(to_unsigned(4, 32));
        data_write_s(15 downto 0) <= "1111000011110000";
        mem_RW_s                  <= '1';
        wait until rising_edge(clk_s);
        wait for 1 ns;
        mem_RW_s <= '0';
        wait for c_CLK_PERIOD;
        written16 := data_read_s(15 downto 0);
        if written16 /= data_write_s(15 downto 0) then
          error("Expected " & to_string(data_write_s(15 downto 0)) & ", got " & to_string(written16));
        end if;

        -- Write halfword to addr 10, read back lower 16 bits to verify
        width_s                   <= "01";
        sign_s                    <= '1';
        addr_s                    <= std_logic_vector(to_unsigned(10, 32));
        data_write_s(15 downto 0) <= "1100110011001100";
        mem_RW_s                  <= '1';
        wait until rising_edge(clk_s);
        wait for 1 ns;
        mem_RW_s <= '0';
        wait for c_CLK_PERIOD;
        written16 := data_read_s(15 downto 0);
        if written16 /= data_write_s(15 downto 0) then
          error("Expected " & to_string(data_write_s(15 downto 0)) & ", got " & to_string(written16));
        end if;

        -- Out-of-bounds halfword write: expect invalid_addr_s = '1'
        width_s                   <= "01";
        addr_s                    <= std_logic_vector(to_unsigned(258, 32));
        data_write_s(15 downto 0) <= "1100110011001100";
        mem_RW_s                  <= '1';
        wait until rising_edge(clk_s);
        wait for 1 ns;
        check_equal(invalid_addr_s,      '1', "SH oob: invalid_addr should be '1'");
        check_equal(misaligned_access_s, '0', "SH oob: misaligned should be '0'");
        mem_RW_s <= '0';
        addr_s   <= std_logic_vector(to_unsigned(0, 32));
        wait until rising_edge(clk_s);
        wait until rising_edge(clk_s);
        wait for 1 ns;
        check_equal(invalid_addr_s, '0', "SH oob: invalid_addr should clear");

        -- Negative address halfword write: expect invalid_addr_s = '1'
        width_s                   <= "01";
        addr_s                    <= std_logic_vector(to_signed(-5, 32));
        data_write_s(15 downto 0) <= "1100110011001100";
        mem_RW_s                  <= '1';
        wait until rising_edge(clk_s);
        wait for 1 ns;
        check_equal(invalid_addr_s,      '1', "SH neg: invalid_addr should be '1'");
        check_equal(misaligned_access_s, '0', "SH neg: misaligned should be '0'");
        mem_RW_s <= '0';
        addr_s   <= std_logic_vector(to_unsigned(0, 32));
        wait until rising_edge(clk_s);
        wait until rising_edge(clk_s);
        wait for 1 ns;
        check_equal(invalid_addr_s, '0', "SH neg: invalid_addr should clear");

        -- Misaligned halfword write (odd address): expect misaligned_access_s = '1'
        width_s  <= "01";
        addr_s   <= std_logic_vector(to_unsigned(3, 32));
        mem_RW_s <= '1';
        wait until rising_edge(clk_s);
        wait for 1 ns;
        check_equal(misaligned_access_s, '1', "SH misaligned: misaligned should be '1'");
        check_equal(invalid_addr_s,      '0', "SH misaligned: invalid_addr should be '0'");
        mem_RW_s <= '0';
        addr_s   <= std_logic_vector(to_unsigned(0, 32));
        wait until rising_edge(clk_s);
        wait until rising_edge(clk_s);
        wait for 1 ns;
        check_equal(misaligned_access_s, '0', "SH misaligned: misaligned should clear");

      elsif run("test_store_byte") then
        info("Testing store byte (sb) function of lsu");

        -- Write byte to addr 4, read back lowest byte to verify
        width_s                  <= "00";
        sign_s                   <= '1';
        addr_s                   <= std_logic_vector(to_unsigned(4, 32));
        data_write_s(7 downto 0) <= "11110000";
        mem_RW_s                 <= '1';
        wait until rising_edge(clk_s);
        wait for 1 ns;
        mem_RW_s <= '0';
        wait for c_CLK_PERIOD;
        written8 := data_read_s(7 downto 0);
        if written8 /= data_write_s(7 downto 0) then
          error("Expected " & to_string(data_write_s(7 downto 0)) & ", got " & to_string(written8));
        end if;

        -- Write byte to addr 9, read back lowest byte to verify
        width_s                  <= "00";
        sign_s                   <= '1';
        addr_s                   <= std_logic_vector(to_unsigned(9, 32));
        data_write_s(7 downto 0) <= "11001100";
        mem_RW_s                 <= '1';
        wait until rising_edge(clk_s);
        wait for 1 ns;
        mem_RW_s <= '0';
        wait for c_CLK_PERIOD;
        written8 := data_read_s(7 downto 0);
        if written8 /= data_write_s(7 downto 0) then
          error("Expected " & to_string(data_write_s(7 downto 0)) & ", got " & to_string(written8));
        end if;

        -- Out-of-bounds byte write: expect invalid_addr_s = '1'
        width_s                  <= "00";
        addr_s                   <= std_logic_vector(to_unsigned(258, 32));
        data_write_s(7 downto 0) <= "11001100";
        mem_RW_s                 <= '1';
        wait until rising_edge(clk_s);
        wait for 1 ns;
        check_equal(invalid_addr_s,      '1', "SB oob: invalid_addr should be '1'");
        check_equal(misaligned_access_s, '0', "SB oob: misaligned should be '0'");
        mem_RW_s <= '0';
        addr_s   <= std_logic_vector(to_unsigned(0, 32));
        wait until rising_edge(clk_s);
        wait until rising_edge(clk_s);
        wait for 1 ns;
        check_equal(invalid_addr_s, '0', "SB oob: invalid_addr should clear");

        -- Negative address byte write: expect invalid_addr_s = '1'
        width_s                  <= "00";
        addr_s                   <= std_logic_vector(to_signed(-5, 32));
        data_write_s(7 downto 0) <= "11001100";
        mem_RW_s                 <= '1';
        wait until rising_edge(clk_s);
        wait for 1 ns;
        check_equal(invalid_addr_s,      '1', "SB neg: invalid_addr should be '1'");
        check_equal(misaligned_access_s, '0', "SB neg: misaligned should be '0'");
        mem_RW_s <= '0';
        addr_s   <= std_logic_vector(to_unsigned(0, 32));
        wait until rising_edge(clk_s);
        wait until rising_edge(clk_s);
        wait for 1 ns;
        check_equal(invalid_addr_s, '0', "SB neg: invalid_addr should clear");

      elsif run("test_load_word") then
        info("Testing load word (lw) function of load_store unit");

        -- First store values that will be loaded
        width_s <= "00";
        mem_RW_s <= '1';
        addr_s <= std_logic_vector(to_unsigned(0, 32));
        data_write_s(7 downto 0) <= "11111111";
        wait until clk_s;
        addr_s <= std_logic_vector(to_unsigned(1, 32));
        data_write_s(7 downto 0) <= "00000000";
        wait until clk_s;
        addr_s <= std_logic_vector(to_unsigned(2, 32));
        data_write_s(7 downto 0) <= "11001100";
        wait until clk_s;
        addr_s <= std_logic_vector(to_unsigned(3, 32));
        data_write_s(7 downto 0) <= "00110011";
        wait until clk_s;
        addr_s <= std_logic_vector(to_unsigned(4, 32));
        data_write_s(7 downto 0) <= "10101010";
        wait until clk_s;
        addr_s <= std_logic_vector(to_unsigned(5, 32));
        data_write_s(7 downto 0) <= "10101010";
        wait until clk_s;
        addr_s <= std_logic_vector(to_unsigned(6, 32));
        data_write_s(7 downto 0) <= "11110000";
        wait until clk_s;
        addr_s <= std_logic_vector(to_unsigned(7, 32));
        data_write_s(7 downto 0) <= "00001111";
        wait until clk_s;
        addr_s <= std_logic_vector(to_unsigned(30, 32));
        data_write_s(7 downto 0) <= "00000000";
        wait until clk_s;
        addr_s <= std_logic_vector(to_unsigned(31, 32));
        data_write_s(7 downto 0) <= "00000000";
        wait until clk_s;
        addr_s <= std_logic_vector(to_unsigned(32, 32));
        data_write_s(7 downto 0) <= "00000000";
        wait until clk_s;
        addr_s <= std_logic_vector(to_unsigned(33, 32));
        data_write_s(7 downto 0) <= "00000000";
        wait until clk_s;

        width_s <= "11";
        -- Test reading first word from DMEM
        expected := "00110011110011000000000011111111";

        addr_s <= std_logic_vector(to_unsigned(0, 32));
        mem_RW_s <= '0';
        wait for c_CLK_PERIOD;
        if data_read_s /= expected then
          error("Expected " & to_string(expected) & ", got " & to_string(data_read_s));
        end if;

        -- Test reading second word from DMEM
        addr_s <= std_logic_vector(to_unsigned(4, 32));
        expected := "00001111111100001010101010101010";
        wait for c_CLK_PERIOD;
        if data_read_s /= expected then
          error("Expected " & to_string(expected) & ", got " & to_string(data_read_s));
        end if;
        
        -- Test reading a word from DMEM that hasn't been defined in DMEM of mem_pkg
        addr_s <= std_logic_vector(to_unsigned(30, 32));
        expected := (others => '0');
        wait for c_CLK_PERIOD;
        if data_read_s /= expected then
          error("Expected " & to_string(expected) & ", got " & to_string(data_read_s));
        end if;

        -- Out-of-bounds word read: expect invalid_addr_s = '1'
        addr_s   <= std_logic_vector(to_unsigned(1000, 32));
        mem_RW_s <= '0';
        wait for 1 ns;
        check_equal(invalid_addr_s,      '1', "LW oob: invalid_addr should be '1'");
        check_equal(misaligned_access_s, '0', "LW oob: misaligned should be '0'");
        check_equal(data_read_s, std_logic_vector(to_unsigned(0, 32)), "LW oob: data_read should be zero");

        -- Negative address word read: expect invalid_addr_s = '1'
        addr_s <= std_logic_vector(to_signed(-199, 32));
        wait for 1 ns;
        check_equal(invalid_addr_s,      '1', "LW neg: invalid_addr should be '1'");
        check_equal(misaligned_access_s, '0', "LW neg: misaligned should be '0'");
        check_equal(data_read_s, std_logic_vector(to_unsigned(0, 32)), "LW neg: data_read should be zero");

        -- Misaligned word read (addr not 4-byte aligned): expect misaligned_access_s = '1'
        addr_s <= std_logic_vector(to_unsigned(2, 32));
        wait for 1 ns;
        check_equal(misaligned_access_s, '1', "LW misaligned: misaligned should be '1'");
        check_equal(invalid_addr_s,      '0', "LW misaligned: invalid_addr should be '0'");
        check_equal(data_read_s, std_logic_vector(to_unsigned(0, 32)), "LW misaligned: data_read should be zero");

        -- Verify flags clear on valid read (recovery)
        addr_s <= std_logic_vector(to_unsigned(0, 32));
        wait for 1 ns;
        check_equal(invalid_addr_s,      '0', "LW recovery: invalid_addr should be '0'");
        check_equal(misaligned_access_s, '0', "LW recovery: misaligned should be '0'");

        info("Load word test passed");

      elsif run("test_load_half") then
        info("Testing load half word (lh) function of load_store_unit");

        -- First store values that will be loaded
        width_s <= "00";
        mem_RW_s <= '1';
        addr_s <= std_logic_vector(to_unsigned(0, 32));
        data_write_s(7 downto 0) <= "11111111";
        wait until clk_s;
        addr_s <= std_logic_vector(to_unsigned(1, 32));
        data_write_s(7 downto 0) <= "00000000";
        wait until clk_s;
        addr_s <= std_logic_vector(to_unsigned(2, 32));
        data_write_s(7 downto 0) <= "11001100";
        wait until clk_s;
        addr_s <= std_logic_vector(to_unsigned(3, 32));
        data_write_s(7 downto 0) <= "00110011";
        wait until clk_s;
        addr_s <= std_logic_vector(to_unsigned(4, 32));
        data_write_s(7 downto 0) <= "10101010";
        wait until clk_s;
        addr_s <= std_logic_vector(to_unsigned(5, 32));
        data_write_s(7 downto 0) <= "10101010";
        wait until clk_s;
        addr_s <= std_logic_vector(to_unsigned(6, 32));
        data_write_s(7 downto 0) <= "11110000";
        wait until clk_s;
        addr_s <= std_logic_vector(to_unsigned(7, 32));
        data_write_s(7 downto 0) <= "00001111";
        wait until clk_s;
        addr_s <= std_logic_vector(to_unsigned(30, 32));
        data_write_s(7 downto 0) <= "00000000";
        wait until clk_s;
        addr_s <= std_logic_vector(to_unsigned(31, 32));
        data_write_s(7 downto 0) <= "00000000";
        wait until clk_s;
        addr_s <= std_logic_vector(to_unsigned(32, 32));
        data_write_s(7 downto 0) <= "00000000";
        wait until clk_s;
        addr_s <= std_logic_vector(to_unsigned(33, 32));
        data_write_s(7 downto 0) <= "00000000";
        wait until clk_s;

        -- Read first 2 bytes of memory unsigned
        mem_RW_s <= '0';
        addr_s <= std_logic_vector(to_unsigned(0, 32));
        width_s <= "01";
        sign_s <= '1';
        expected := "00000000000000000000000011111111";
        
        wait for c_CLK_PERIOD;
        if data_read_s /= expected then
          error("Expected " & to_string(expected) & ", got " & to_string(data_read_s));
        end if;

        -- Read second 2 bytes of memory unsigned
        addr_s <= std_logic_vector(to_unsigned(2, 32));
        width_s <= "01";
        sign_s <= '1';
        expected := "00000000000000000011001111001100";
        
        wait for c_CLK_PERIOD;
        if data_read_s /= expected then
          error("Expected " & to_string(expected) & ", got " & to_string(data_read_s));
        end if;

        -- Out-of-bounds halfword read: expect invalid_addr_s = '1'
        addr_s   <= std_logic_vector(to_unsigned(257, 32));
        width_s  <= "01";
        sign_s   <= '1';
        mem_RW_s <= '0';
        wait for 1 ns;
        check_equal(invalid_addr_s,      '1', "LH oob: invalid_addr should be '1'");
        check_equal(misaligned_access_s, '0', "LH oob: misaligned should be '0'");
        check_equal(data_read_s, std_logic_vector(to_unsigned(0, 32)), "LH oob: data_read should be zero");

        -- Negative address halfword read: expect invalid_addr_s = '1'
        addr_s <= std_logic_vector(to_signed(-4, 32));
        wait for 1 ns;
        check_equal(invalid_addr_s,      '1', "LH neg: invalid_addr should be '1'");
        check_equal(misaligned_access_s, '0', "LH neg: misaligned should be '0'");
        check_equal(data_read_s, std_logic_vector(to_unsigned(0, 32)), "LH neg: data_read should be zero");

        -- Misaligned halfword read (odd address): expect misaligned_access_s = '1'
        addr_s <= std_logic_vector(to_unsigned(3, 32));
        wait for 1 ns;
        check_equal(misaligned_access_s, '1', "LH misaligned: misaligned should be '1'");
        check_equal(invalid_addr_s,      '0', "LH misaligned: invalid_addr should be '0'");
        check_equal(data_read_s, std_logic_vector(to_unsigned(0, 32)), "LH misaligned: data_read should be zero");

        -- Verify flags clear on valid read (recovery)
        addr_s <= std_logic_vector(to_unsigned(0, 32));
        wait for 1 ns;
        check_equal(invalid_addr_s,      '0', "LH recovery: invalid_addr should be '0'");
        check_equal(misaligned_access_s, '0', "LH recovery: misaligned should be '0'");

        -- Read 2 bytes from address 4 memory unsigned
        width_s <= "01";
        sign_s <= '1';
        addr_s <= std_logic_vector(to_unsigned(4, 32));
        expected := "00000000000000001010101010101010";

        wait for c_CLK_PERIOD;
        if data_read_s /= expected then
          error("Expected " & to_string(expected) & ", got " & to_string(data_read_s));
        end if;

        -- Read first 2 bytes of memory signed
        addr_s <= std_logic_vector(to_unsigned(0, 32));
        width_s <= "01";
        sign_s <= '0';
        expected := "00000000000000000000000011111111";
        
        wait for c_CLK_PERIOD;
        if data_read_s /= expected then
          error("Expected " & to_string(expected) & ", got " & to_string(data_read_s));
        end if;

        -- Read 2 bytes from address 4 signed
        addr_s <= std_logic_vector(to_unsigned(4, 32));
        width_s <= "01";
        sign_s <= '0';
        expected := "11111111111111111010101010101010";
        
        wait for c_CLK_PERIOD;
        if data_read_s /= expected then
          error("Expected " & to_string(expected) & ", got " & to_string(data_read_s));
        end if;

      elsif run("test_load_byte") then
        info("Testing load byte(lb) function of load_store_unit");

        -- First store values that will be loaded
        width_s <= "00";
        mem_RW_s <= '1';
        addr_s <= std_logic_vector(to_unsigned(0, 32));
        data_write_s(7 downto 0) <= "11111111";
        wait until clk_s;
        addr_s <= std_logic_vector(to_unsigned(1, 32));
        data_write_s(7 downto 0) <= "00000000";
        wait until clk_s;
        addr_s <= std_logic_vector(to_unsigned(2, 32));
        data_write_s(7 downto 0) <= "11001100";
        wait until clk_s;
        addr_s <= std_logic_vector(to_unsigned(3, 32));
        data_write_s(7 downto 0) <= "00110011";
        wait until clk_s;
        addr_s <= std_logic_vector(to_unsigned(4, 32));
        data_write_s(7 downto 0) <= "10101010";
        wait until clk_s;
        addr_s <= std_logic_vector(to_unsigned(5, 32));
        data_write_s(7 downto 0) <= "10101010";
        wait until clk_s;
        addr_s <= std_logic_vector(to_unsigned(6, 32));
        data_write_s(7 downto 0) <= "11110000";
        wait until clk_s;
        addr_s <= std_logic_vector(to_unsigned(7, 32));
        data_write_s(7 downto 0) <= "00001111";
        wait until clk_s;
        addr_s <= std_logic_vector(to_unsigned(30, 32));
        data_write_s(7 downto 0) <= "00000000";
        wait until clk_s;
        addr_s <= std_logic_vector(to_unsigned(31, 32));
        data_write_s(7 downto 0) <= "00000000";
        wait until clk_s;
        addr_s <= std_logic_vector(to_unsigned(32, 32));
        data_write_s(7 downto 0) <= "00000000";
        wait until clk_s;
        addr_s <= std_logic_vector(to_unsigned(33, 32));
        data_write_s(7 downto 0) <= "00000000";
        wait until clk_s;

        mem_RW_s <= '0';
        -- Read first byte of memory unsigned
        addr_s <= std_logic_vector(to_unsigned(0, 32));
        width_s <= "00";
        sign_s <= '1';
        expected := "00000000000000000000000011111111";
        
        wait for c_CLK_PERIOD;
        if data_read_s /= expected then
          error("Expected " & to_string(expected) & ", got " & to_string(data_read_s));
        end if;

        -- Read byte 2 of memory unsigned
        addr_s <= std_logic_vector(to_unsigned(2, 32));
        width_s <= "00";
        sign_s <= '1';
        expected := "00000000000000000000000011001100";
        
        wait for c_CLK_PERIOD;
        if data_read_s /= expected then
          error("Expected " & to_string(expected) & ", got " & to_string(data_read_s));
        end if;

        -- Out-of-bounds byte read: expect invalid_addr_s = '1'
        addr_s   <= std_logic_vector(to_unsigned(257, 32));
        width_s  <= "00";
        sign_s   <= '1';
        mem_RW_s <= '0';
        wait for 1 ns;
        check_equal(invalid_addr_s,      '1', "LB oob: invalid_addr should be '1'");
        check_equal(misaligned_access_s, '0', "LB oob: misaligned should be '0'");
        check_equal(data_read_s, std_logic_vector(to_unsigned(0, 32)), "LB oob: data_read should be zero");

        -- Negative address byte read: expect invalid_addr_s = '1'
        addr_s <= std_logic_vector(to_signed(-4, 32));
        wait for 1 ns;
        check_equal(invalid_addr_s,      '1', "LB neg: invalid_addr should be '1'");
        check_equal(misaligned_access_s, '0', "LB neg: misaligned should be '0'");
        check_equal(data_read_s, std_logic_vector(to_unsigned(0, 32)), "LB neg: data_read should be zero");

        -- Verify flags clear on valid read (recovery)
        addr_s <= std_logic_vector(to_unsigned(0, 32));
        wait for 1 ns;
        check_equal(invalid_addr_s,      '0', "LB recovery: invalid_addr should be '0'");
        check_equal(misaligned_access_s, '0', "LB recovery: misaligned should be '0'");

        -- Read byte of memory signed
        addr_s <= std_logic_vector(to_unsigned(0, 32));
        width_s <= "00";
        sign_s <= '0';
        expected := "11111111111111111111111111111111";
        
        wait for c_CLK_PERIOD;
        if data_read_s /= expected then
          error("Expected " & to_string(expected) & ", got " & to_string(data_read_s));
        end if;

        -- Read bytes from address 4 signed
        addr_s <= std_logic_vector(to_unsigned(4, 32));
        width_s <= "00";
        sign_s <= '0';
        expected := "11111111111111111111111110101010";
        
        wait for c_CLK_PERIOD;
        if data_read_s /= expected then
          error("Expected " & to_string(expected) & ", got " & to_string(data_read_s));
        end if;

        -- Read byte from address 7 signed
        addr_s <= std_logic_vector(to_unsigned(7, 32));
        width_s <= "00";
        sign_s <= '0';
        expected := "00000000000000000000000000001111";
        
        wait for c_CLK_PERIOD;
        if data_read_s /= expected then
          error("Expected " & to_string(expected) & ", got " & to_string(data_read_s));
        end if;

      elsif run("test_exceptions") then
        info("Testing exception signals of load_store_unit");

        -- ----------------------------------------------------------------
        -- WRITE EXCEPTIONS
        -- ----------------------------------------------------------------

        -- SW: out-of-bounds
        width_s  <= "10";
        addr_s   <= std_logic_vector(to_unsigned(1000, 32));
        mem_RW_s <= '1';
        wait until rising_edge(clk_s);
        wait for 1 ns;
        check_equal(invalid_addr_s,      '1', "EXC SW oob: invalid_addr should be '1'");
        check_equal(misaligned_access_s, '0', "EXC SW oob: misaligned should be '0'");
        mem_RW_s <= '0';
        addr_s   <= std_logic_vector(to_unsigned(0, 32));
        wait until rising_edge(clk_s);
        wait until rising_edge(clk_s);
        wait for 1 ns;
        check_equal(invalid_addr_s,      '0', "EXC SW oob: invalid_addr should clear");
        check_equal(misaligned_access_s, '0', "EXC SW oob: misaligned should stay '0'");

        -- SW: misaligned (addr not 4-byte aligned)
        width_s  <= "10";
        addr_s   <= std_logic_vector(to_unsigned(2, 32));
        mem_RW_s <= '1';
        wait until rising_edge(clk_s);
        wait for 1 ns;
        check_equal(misaligned_access_s, '1', "EXC SW misaligned: misaligned should be '1'");
        check_equal(invalid_addr_s,      '0', "EXC SW misaligned: invalid_addr should be '0'");
        mem_RW_s <= '0';
        addr_s   <= std_logic_vector(to_unsigned(0, 32));
        wait until rising_edge(clk_s);
        wait until rising_edge(clk_s);
        wait for 1 ns;
        check_equal(misaligned_access_s, '0', "EXC SW misaligned: misaligned should clear");

        -- SH: out-of-bounds
        width_s  <= "01";
        addr_s   <= std_logic_vector(to_unsigned(300, 32));
        mem_RW_s <= '1';
        wait until rising_edge(clk_s);
        wait for 1 ns;
        check_equal(invalid_addr_s,      '1', "EXC SH oob: invalid_addr should be '1'");
        check_equal(misaligned_access_s, '0', "EXC SH oob: misaligned should be '0'");
        mem_RW_s <= '0';
        addr_s   <= std_logic_vector(to_unsigned(0, 32));
        wait until rising_edge(clk_s);
        wait until rising_edge(clk_s);
        wait for 1 ns;
        check_equal(invalid_addr_s, '0', "EXC SH oob: invalid_addr should clear");

        -- SH: misaligned (odd address)
        width_s  <= "01";
        addr_s   <= std_logic_vector(to_unsigned(3, 32));
        mem_RW_s <= '1';
        wait until rising_edge(clk_s);
        wait for 1 ns;
        check_equal(misaligned_access_s, '1', "EXC SH misaligned: misaligned should be '1'");
        check_equal(invalid_addr_s,      '0', "EXC SH misaligned: invalid_addr should be '0'");
        mem_RW_s <= '0';
        addr_s   <= std_logic_vector(to_unsigned(0, 32));
        wait until rising_edge(clk_s);
        wait until rising_edge(clk_s);
        wait for 1 ns;
        check_equal(misaligned_access_s, '0', "EXC SH misaligned: misaligned should clear");

        -- SB: out-of-bounds
        width_s  <= "00";
        addr_s   <= std_logic_vector(to_unsigned(300, 32));
        mem_RW_s <= '1';
        wait until rising_edge(clk_s);
        wait for 1 ns;
        check_equal(invalid_addr_s,      '1', "EXC SB oob: invalid_addr should be '1'");
        check_equal(misaligned_access_s, '0', "EXC SB oob: misaligned should be '0'");
        mem_RW_s <= '0';
        addr_s   <= std_logic_vector(to_unsigned(0, 32));
        wait until rising_edge(clk_s);
        wait until rising_edge(clk_s);
        wait for 1 ns;
        check_equal(invalid_addr_s, '0', "EXC SB oob: invalid_addr should clear");

        -- ----------------------------------------------------------------
        -- READ EXCEPTIONS (combinational — check after 1 ns delta)
        -- ----------------------------------------------------------------

        mem_RW_s <= '0';

        -- LW: out-of-bounds
        width_s <= "10";
        addr_s  <= std_logic_vector(to_unsigned(1000, 32));
        wait for 1 ns;
        check_equal(invalid_addr_s,      '1', "EXC LW oob: invalid_addr should be '1'");
        check_equal(misaligned_access_s, '0', "EXC LW oob: misaligned should be '0'");
        check_equal(data_read_s, std_logic_vector(to_unsigned(0, 32)), "EXC LW oob: data should be zero");

        -- LW: misaligned
        addr_s <= std_logic_vector(to_unsigned(2, 32));
        wait for 1 ns;
        check_equal(misaligned_access_s, '1', "EXC LW misaligned: misaligned should be '1'");
        check_equal(invalid_addr_s,      '0', "EXC LW misaligned: invalid_addr should be '0'");
        check_equal(data_read_s, std_logic_vector(to_unsigned(0, 32)), "EXC LW misaligned: data should be zero");

        -- LH: out-of-bounds
        width_s <= "01";
        addr_s  <= std_logic_vector(to_unsigned(300, 32));
        wait for 1 ns;
        check_equal(invalid_addr_s,      '1', "EXC LH oob: invalid_addr should be '1'");
        check_equal(misaligned_access_s, '0', "EXC LH oob: misaligned should be '0'");

        -- LH: misaligned
        addr_s <= std_logic_vector(to_unsigned(3, 32));
        wait for 1 ns;
        check_equal(misaligned_access_s, '1', "EXC LH misaligned: misaligned should be '1'");
        check_equal(invalid_addr_s,      '0', "EXC LH misaligned: invalid_addr should be '0'");

        -- LB: out-of-bounds (bytes have no alignment requirement, only bounds)
        width_s <= "00";
        addr_s  <= std_logic_vector(to_unsigned(300, 32));
        wait for 1 ns;
        check_equal(invalid_addr_s,      '1', "EXC LB oob: invalid_addr should be '1'");
        check_equal(misaligned_access_s, '0', "EXC LB oob: misaligned should be '0'");

        -- ----------------------------------------------------------------
        -- RECOVERY: valid access after exceptions — both flags must be '0'
        -- ----------------------------------------------------------------
        width_s <= "10";
        addr_s  <= std_logic_vector(to_unsigned(0, 32));
        wait for 1 ns;
        check_equal(invalid_addr_s,      '0', "EXC recovery: invalid_addr should be '0'");
        check_equal(misaligned_access_s, '0', "EXC recovery: misaligned should be '0'");

        -- ----------------------------------------------------------------
        -- RESET: verify rst_i clears write exception flags
        -- ----------------------------------------------------------------
        width_s  <= "10";
        addr_s   <= std_logic_vector(to_unsigned(1000, 32));
        mem_RW_s <= '1';
        wait until rising_edge(clk_s);
        wait for 1 ns;
        check_equal(invalid_addr_s, '1', "EXC rst: flag should be raised before reset");

        rst_s    <= '1';
        mem_RW_s <= '0';
        addr_s   <= std_logic_vector(to_unsigned(0, 32));
        wait until rising_edge(clk_s);
        wait until rising_edge(clk_s);
        wait for 1 ns;
        check_equal(invalid_addr_s,      '0', "EXC rst: invalid_addr should clear on reset");
        check_equal(misaligned_access_s, '0', "EXC rst: misaligned should clear on reset");
        rst_s <= '0';

        info("Exception test passed");

      end if;
    end loop;

    test_runner_cleanup(runner);
  end process main;
end architecture arch;
