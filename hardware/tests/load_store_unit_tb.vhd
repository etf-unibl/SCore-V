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

library vunit_lib;
context vunit_lib.vunit_context;

library design_lib;
use design_lib.mem_pkg.all;

entity load_store_unit_tb is
  generic (runner_cfg : string);
end load_store_unit_tb;

architecture arch of load_store_unit_tb is
  signal clk_s        : std_logic := '0';
  signal rst_s        : std_logic := '0';
  signal addr_s       : std_logic_vector(31 downto 0) := (others => '0');
  signal mem_RW_s     : std_logic := '0';
  signal data_write_s : std_logic_vector(31 downto 0) := (others => '0');
  signal data_read_s  : std_logic_vector(31 downto 0) := (others => '0');
  signal sim_stop_s : std_logic := '0';

  signal word_to_write : std_logic_vector(31 downto 0) := (others => '0');
  constant c_CLK_PERIOD : time := 10 ns;

begin

  uut : entity design_lib.load_store_unit
    port map (
      clk_i        => clk_s,
      rst_i        => rst_s,
      addr_i       => addr_s,
      mem_RW_i     => mem_RW_s,
      data_write_i => data_write_s,
      data_read_o  => data_read_s
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
    variable expected : std_logic_vector(31 downto 0);
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

      elsif run("test_load") then
        info("Testing load function of load_store unit");

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

        info("Load test passed");

      elsif run("test_store") then
        info("Testing store function of load_store unit");

        -- Test storing word on byte 8
        addr_s <= std_logic_vector(to_unsigned(8, 32));
        data_write_s <= std_logic_vector(to_unsigned(64, 32));
        mem_RW_s <= '1';

        wait until clk_s;
        wait until clk_s;
        expected := DMEM(to_integer(unsigned(addr_s)) + 3) &
                    DMEM(to_integer(unsigned(addr_s)) + 2) &
                    DMEM(to_integer(unsigned(addr_s)) + 1) &
                    DMEM(to_integer(unsigned(addr_s)));

        if expected /= data_write_s then
          error("Expected " & to_string(data_write_s) & ", got " & to_string(expected));
        end if;

        -- Test storing word on byte 4
        addr_s <= std_logic_vector(to_unsigned(4, 32));
        data_write_s <= std_logic_vector(to_unsigned(64, 32));
        mem_RW_s <= '1';

        wait until clk_s;
        wait until clk_s;
        expected := DMEM(to_integer(unsigned(addr_s)) + 3) &
                    DMEM(to_integer(unsigned(addr_s)) + 2) &
                    DMEM(to_integer(unsigned(addr_s)) + 1) &
                    DMEM(to_integer(unsigned(addr_s)));

        if expected /= data_write_s then
          error("Expected " & to_string(data_write_s) & ", got " & to_string(expected));
        end if;

        -- Test storing word on byte 1000 that is out of bounds of DMEM
        addr_s <= std_logic_vector(to_unsigned(1000, 32));
        data_write_s <= std_logic_vector(to_unsigned(64, 32));
        mem_RW_s <= '1';

        wait until clk_s;
        wait until clk_s;
        expected := DMEM(to_integer(unsigned(addr_s)) + 3) &
                    DMEM(to_integer(unsigned(addr_s)) + 2) &
                    DMEM(to_integer(unsigned(addr_s)) + 1) &
                    DMEM(to_integer(unsigned(addr_s)));

        if expected /= data_write_s then
          error("Expected " & to_string(data_write_s) & ", got " & to_string(expected));
        end if;

        info("Store test passed");
        
      end if;
    end loop;

    test_runner_cleanup(runner);
  end process main;
end architecture arch;

