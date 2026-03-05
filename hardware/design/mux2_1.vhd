-----------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2025
-- https://github.com/etf-unibl/SCore-V
-----------------------------------------------------------------------------
--
-- unit name:     mux2_1
--
-- description:
--
--   This file implements a generic 2-to-1 multiplexer.
--   The multiplexer selects one of two input vectors and forwards
--   the selected value to the output.
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

--! @file mux2_1.vhd
--! @brief Generic 2-to-1 multiplexer
--! @details
--! This module implements a parameterizable-width 2:1 multiplexer.
--! The data width is defined by the generic parameter g_WIDTH.
--!
--! Inputs:
--!   - in0_i : First input vector
--!   - in1_i : Second input vector
--!
--! Selection:
--!   - sel_i = '0' -> out_o = in0_i
--!   - sel_i = '1' -> out_o = in1_i

library ieee;
use ieee.std_logic_1164.all;

entity mux2_1 is
  port (
    in0_i : in  std_logic_vector(31 downto 0); --! First input
    in1_i : in  std_logic_vector(31 downto 0); --! Second input
    sel_i : in  std_logic;                            --! Select signal
    out_o : out std_logic_vector(31 downto 0)  --! Selected output
  );
end entity mux2_1;

architecture arch of mux2_1 is
begin
  out_o <= in0_i when sel_i = '0' else in1_i;
end architecture arch;
