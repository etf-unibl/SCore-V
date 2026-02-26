-----------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2025
-- https://github.com/etf-unibl/SCore-V/
-----------------------------------------------------------------------------
--
-- unit name: imm_gen
--
-- description:
--
--   This file implements a simple Immediate Generator unit.
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

--! @brief Immediate Generation Unit
--! @details
--!   Generates a 32-bit sign-extended immediate value.
--!   Currently supports only I-type and S-type instructions (e.g., ADDI).
--!   Other types will be added in future extensions.
entity imm_gen is
  port (
    imm_i_type_i       : in  std_logic_vector(11 downto 0); --! From instr[31:20]
    imm_s_type_h_i     : in  std_logic_vector(6 downto 0);  --! From instr[31:25]
    imm_s_type_l_i     : in  std_logic_vector(4 downto 0);  --! From instr[11:7]
    imm_sel_i          : in  std_logic_vector(2 downto 0);  --! Immediate select
    imm_o              : out std_logic_vector(31 downto 0)  --! 32-bit immediate output
  );
end entity imm_gen;

--! @brief Architecture for immediate extraction
architecture arch of imm_gen is
begin
  imm_proc : process(imm_i_type_i, imm_s_type_h_i, imm_s_type_l_i, imm_sel_i)
  begin
    case imm_sel_i is
      when "001" =>
        imm_o(11 downto 0)  <= imm_i_type_i;
        imm_o(31 downto 12) <= (others => imm_i_type_i(11));

      when "010" =>
        imm_o(11 downto 5)  <= imm_s_type_h_i;
        imm_o(4 downto 0)   <= imm_s_type_l_i;
        imm_o(31 downto 12) <= (others => imm_s_type_h_i(6));

      when others =>
        imm_o <= (others => '0');
    end case;
  end process imm_proc;
end arch;
