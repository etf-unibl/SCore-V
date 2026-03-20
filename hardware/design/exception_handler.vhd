-----------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2025
-- https://github.com/etf-unibl/SCore-V
-----------------------------------------------------------------------------
--
-- unit name:     exception_handler
--
-- description:
--
--   Exception handling unit for the processor. This module monitors
--   exception signals generated during instruction execution.
--   If any of the following conditions occur:
--     - misaligned memory access
--     - invalid memory address access
--     - invalid or unsupported instruction
--   the module asserts the halt signal which forces the processor
--   to enter the HALT state.
--
--   The halt signal is registered on the rising edge of the clock
--   and remains active until the processor is reset.
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

--! @file exception_handler.vhd
--! @brief Processor exception detection and handling unit

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity exception_handler is
  port (
  clk_i                  : in  std_logic; --! Clock input
  rst_i                  : in  std_logic; --! Reset input
  misaligned_access_i    : in  std_logic; --! Incorrect address alignment
  invalid_address_i      : in  std_logic; --! Address out of allowed range
  invalid_instruction_i  : in  std_logic; --! Unsupported opcode or invalid format
  halt_processor_o       : out std_logic  --! Processor goes to HALT state when exception occurs
);
end exception_handler;

architecture arch of exception_handler is
    signal int_halt : std_logic := '0';
  begin
    process(clk_i, rst_i)
    begin
      if rst_i = '1' then
        int_halt <= '0';
      elsif rising_edge(clk_i) then
        if (misaligned_access_i = '1' or invalid_address_i = '1' or invalid_instruction_i = '1') then
		  int_halt <= '1';
		  if invalid_instruction_i = '1' then report "DEBUG: Invalid Instruction detected!"; end if;
		  if invalid_address_i = '1' then report "DEBUG: Out of Bounds detected!"; end if;
		  if misaligned_access_i = '1' then report "DEBUG: Misalignment detected!"; end if;
		end if;
      end if;
    end process;

    halt_processor_o <= int_halt;
end arch;
