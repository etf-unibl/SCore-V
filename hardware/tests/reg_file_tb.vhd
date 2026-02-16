-----------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2025
-- https://github.com/etf-unibl/SCore-V.git
-----------------------------------------------------------------------------
--
-- unit name:     reg_file_tb
--
-- description:
--
--   Testbench for verifying the Standard RISC-V register file.
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

--! @brief Testbench for the Register File module.
--! @details Verifies synchronous write and dual-port asynchronous read operations.
entity reg_file_tb is
end entity;

--! @brief RTL Architecture of the Register File Testbench.
architecture arch of reg_file_tb is

    -- Test Signals
    signal clk        : std_logic := '0';                                 --! System clock signal
    signal reg_write  : std_logic := '0';                                 --! Register write enable control
    signal rs1_addr   : std_logic_vector(4 downto 0) := (others => '0');  --! Source register 1 address
    signal rs2_addr   : std_logic_vector(4 downto 0) := (others => '0');  --! Source register 2 address
    signal rd_addr    : std_logic_vector(4 downto 0) := (others => '0');  --! Destination register address
    signal rd_data    : std_logic_vector(31 downto 0) := (others => '0'); --! Data to be written to RD
    signal rs1_data   : std_logic_vector(31 downto 0);                    --! Data output from rs1 port
    signal rs2_data   : std_logic_vector(31 downto 0);                    --! Data output from rs2 port

    --! Clock period constant (100 MHz)
    constant clk_period : time := 10 ns;

    --! @brief Component declaration for the Register File module.
    component reg_file
        port (
            clk_i       : in  std_logic;
            reg_write_i : in  std_logic;
            rs1_addr_i  : in  std_logic_vector(4 downto 0);
            rs2_addr_i  : in  std_logic_vector(4 downto 0);
            rd_addr_i   : in  std_logic_vector(4 downto 0);
            rd_data_i   : in  std_logic_vector(31 downto 0);
            rs1_data_o  : out std_logic_vector(31 downto 0);
            rs2_data_o  : out std_logic_vector(31 downto 0)
        );
    end component;

begin

    --! @brief Instance of the Unit Under Test (UUT).
    DUT: reg_file
        port map(
            clk_i       => clk,
            reg_write_i => reg_write,
            rs1_addr_i  => rs1_addr,
            rs2_addr_i  => rs2_addr,
            rd_addr_i   => rd_addr,
            rd_data_i   => rd_data,
            rs1_data_o  => rs1_data,
            rs2_data_o  => rs2_data
        );

    --! @brief Clock generation process.
    clk_process : process
    begin
        while now < 500 ns loop
            clk <= '0';
            wait for clk_period/2;
            clk <= '1';
            wait for clk_period/2;
        end loop;
        wait;
    end process;

    --! @brief Main test stimulus process.
    stim_proc: process
    begin
        -- Initial stabilization
        wait for 20 ns;

        --! TEST 1: Basic write operation to register x5
        rd_addr   <= "00101";
        rd_data   <= x"ABCDE123";
        reg_write <= '1';
        wait for clk_period;
        reg_write <= '0';

        --! TEST 2: Asynchronous read verification (rs1)
        rs1_addr <= "00101";
        wait for 10 ns;

        --! TEST 3: Hardwired zero check - attempt write to x0
        rd_addr   <= "00000";
        rd_data   <= x"FFFFFFFF";
        reg_write <= '1';
        wait for clk_period;
        reg_write <= '0';

        --! TEST 4: Verify x0 content (should be all zeros)
        rs2_addr <= "00000";
        wait for 10 ns;

        --! TEST 5: Write to register x10
        rd_addr   <= "01010";
        rd_data   <= x"5555AAAA";
        reg_write <= '1';
        wait for clk_period;
        reg_write <= '0';
        rs1_addr  <= "01010";
          
        --! TEST 6: Read-After-Write (RAW) in the same cycle check
        rd_addr   <= "01100"; 
        rd_data   <= x"DEADC0DE";
        reg_write <= '1';
        rs1_addr  <= "01100"; 
        wait for clk_period;
        reg_write <= '0';
        
        --! TEST 7: Verify write disable (reg_write = '0')
        rd_addr   <= "00101"; 
        rd_data   <= x"00000000";
        reg_write <= '0'; 
        wait for clk_period;

        --! TEST 8: Dual-port simultaneous read (x5 and x10)
        rs1_addr <= "00101"; -- x5: ABCDE123
        rs2_addr <= "01010"; -- x10: 5555AAAA
        wait for 10 ns;

        wait;
    end process;

end arch;