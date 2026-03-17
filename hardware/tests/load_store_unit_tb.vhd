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

  -- ----------------------------------------------------------------
  --  Local initialize_dmem and DMEM signal - mirrors what
  --  load_store_unit does internally. Used by the store tests to
  --  verify memory contents directly after a write operation.
  -- ----------------------------------------------------------------
  impure function initialize_dmem(file_name : in string) return t_bytes is
    file     f_ptr  : text;
    variable l      : line;
    variable result : t_bytes := (others => (others => '0'));
    variable temp   : std_logic_vector(7 downto 0);
  begin
    file_open(f_ptr, file_name, read_mode);
    for i in 0 to c_TOTAL_BYTES - 1 loop
      exit when endfile(f_ptr);
      readline(f_ptr, l);
      hread(l, temp);
      result(i) := temp;
    end loop;
    file_close(f_ptr);
    return result;
  end function initialize_dmem;

  --! @brief Local DMEM mirror - initialised from same file as UUT.
  --! @details Store tests read this to verify what was written.
  --!          This signal reflects the UUT's internal DMEM state
  --!          only indirectly - store tests write via the UUT and
  --!          then read back through the UUT's data_read_o port.
  signal DMEM : t_bytes := initialize_dmem(g_init_file);

  signal clk_s        : std_logic := '0';
  signal rst_s        : std_logic := '0';
  signal addr_s       : std_logic_vector(31 downto 0) := (others => '0');
  signal mem_RW_s     : std_logic := '0';
  signal data_write_s : std_logic_vector(31 downto 0) := (others => '0');
  signal data_read_s  : std_logic_vector(31 downto 0) := (others => '0');
  signal sim_stop_s   : std_logic := '0';
  signal sign_s       : std_logic;
  signal width_s      : std_logic_vector(1 downto 0);

  signal word_to_write : std_logic_vector(31 downto 0) := (others => '0');
  constant c_CLK_PERIOD : time := 10 ns;

begin

  uut : entity design_lib.load_store_unit
    generic map (
      g_init_file => g_init_file
    )
    port map (
      clk_i               => clk_s,
      rst_i               => rst_s,
      sign_i              => sign_s,
      width_i             => width_s,
      addr_i              => addr_s,
      mem_RW_i            => mem_RW_s,
      data_write_i        => data_write_s,
      data_read_o         => data_read_s,
      invalid_addr_o      => invalid_addr_s,
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
      --! Default values
      mem_RW_s <= '0';
      width_s  <= "10"; -- Word
      sign_s   <= '1';  -- Unsigned
      addr_s   <= (others => '0');

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

        -- Out-of-bounds and negative address writes (no verification)
        addr_s       <= std_logic_vector(to_unsigned(1000, 32));
        data_write_s <= std_logic_vector(to_unsigned(63, 32));
        mem_RW_s     <= '1';
        wait until rising_edge(clk_s);

        addr_s       <= std_logic_vector(to_signed(-10, 32));
        data_write_s <= std_logic_vector(to_unsigned(63, 32));
        mem_RW_s     <= '1';
        wait until rising_edge(clk_s);

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

        -- Write halfword to addr 9, read back lower 16 bits to verify
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

        -- Out-of-bounds and negative address writes (no verification)
        width_s                   <= "01";
        addr_s                    <= std_logic_vector(to_unsigned(50000, 32));
        data_write_s(15 downto 0) <= "1100110011001100";
        mem_RW_s                  <= '1';
        wait until rising_edge(clk_s);

        width_s                   <= "01";
        addr_s                    <= std_logic_vector(to_signed(-5, 32));
        data_write_s(15 downto 0) <= "1100110011001100";
        mem_RW_s                  <= '1';
        wait until rising_edge(clk_s);

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

        -- Out-of-bounds and negative address writes (no verification)
        width_s                  <= "00";
        addr_s                   <= std_logic_vector(to_unsigned(258, 32));
        data_write_s(7 downto 0) <= "11001100";
        mem_RW_s                 <= '1';
        wait until rising_edge(clk_s);

        width_s                  <= "00";
        addr_s                   <= std_logic_vector(to_signed(-5, 32));
        data_write_s(7 downto 0) <= "11001100";
        mem_RW_s                 <= '1';
        wait until rising_edge(clk_s);

      elsif run("test_load_word") then
        info("Testing load word (lw) function of load_store unit");

        -- First store values that will be loaded
        width_s <= "01";
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

        -- Test reading a word out of bounds for DMEM
        addr_s <= std_logic_vector(to_unsigned(1000, 32));
        expected := (others => '0');
        wait for c_CLK_PERIOD;
        if data_read_s /= expected then
          error("Expected " & to_string(expected) & ", got " & to_string(data_read_s));
        end if;

        -- Test reading a word out of negative address of DMEM
        addr_s <= std_logic_vector(to_signed(-199, 32));
        expected := (others => '0');
        wait for c_CLK_PERIOD;
        if data_read_s /= expected then
          error("Expected " & to_string(expected) & ", got " & to_string(data_read_s));
        end if;

        info("Load word test passed");

      elsif run("test_load_half") then
        info("Testing load half word (lh) function of load_store_unit");

        -- First store values that will be loaded
        width_s <= "01";
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

        -- Read 2 bytes of unreachable memory unsigned
        addr_s <= std_logic_vector(to_unsigned(257, 32));
        width_s <= "01";
        sign_s <= '1';
        expected := (others => '0');
        
        wait for c_CLK_PERIOD;
        if data_read_s /= expected then
          error("Expected " & to_string(expected) & ", got " & to_string(data_read_s));
        end if;

        -- Read 2 bytes from address 4 memory unsigned
        addr_s <= std_logic_vector(to_unsigned(4, 32));
        width_s <= "01";
        sign_s <= '1';
        expected := "00000000000000001010101010101010";

        wait for c_CLK_PERIOD;
        if data_read_s /= expected then
          error("Expected " & to_string(expected) & ", got " & to_string(data_read_s));
        end if;

        -- Read 2 bytes of unreachable memory unsigned
        addr_s <= std_logic_vector(to_signed(-4, 32));
        width_s <= "01";
        sign_s <= '1';
        expected := (others => '0');
        
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
        width_s <= "01";
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

        -- Read byte of unreachable memory unsigned
        addr_s <= std_logic_vector(to_unsigned(257, 32));
        width_s <= "00";
        sign_s <= '1';
        expected := (others => '0');
        
        wait for c_CLK_PERIOD;
        if data_read_s /= expected then
          error("Expected " & to_string(expected) & ", got " & to_string(data_read_s));
        end if;

        -- Read byte of unreachable memory unsigned
        addr_s <= std_logic_vector(to_signed(-4, 32));
        width_s <= "00";
        sign_s <= '1';
        expected := (others => '0');
        
        wait for c_CLK_PERIOD;
        if data_read_s /= expected then
          error("Expected " & to_string(expected) & ", got " & to_string(data_read_s));
        end if;

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

      end if;
    end loop;

    test_runner_cleanup(runner);
  end process main;
end architecture arch;
