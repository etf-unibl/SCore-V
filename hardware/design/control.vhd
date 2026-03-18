-----------------------------------------------------------------------------
-- Faculty of Electrical Engineering
-- PDS 2025
-- https://github.com/etf-unibl/SCore-V
-----------------------------------------------------------------------------
--
-- unit name:     control
--
-- description:
--
--   This file implements a combinational control unit for the RISC-V core.
--   The control unit performs instruction decoding based on the opcode,
--   funct3, and funct7 fields and generates the appropriate control signals
--   for the datapath.
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

--! @file control.vhd
--! @brief Combinational control unit for the RISC-V core
--! @details
--! This module decodes the instruction fields provided by the instruction decoder
--! (opcode/funct3/funct7) and generates datapath control signals.
--!
--! Generated control signals:
--!
--! - reg_write_enable_o:
--!     Enables writeback into register file (rd).
--!
--! - imm_sel_o:
--!     Immediate format selector for ImmGen.
--!     "001" = I-type immediate
--!     "010" = S-type immediate
--!     "011" = B-type immediate
--!     "100" = U-type immediate
--!     "101" = J-type immediate
--!
--! - b_sel_o:
--!     Selects ALU operand B source.
--!     '0' = rs2_data
--!     '1' = imm32
--!
--! - a_sel_o:
--!     Selects ALU operand A source.
--!     '0' = rs1_data
--!     '1' = PC (Program Counter)
--!
--! - alu_op_o:
--!     Selects ALU operation (e.g. ALU_ADD, ALU_NOP).
--!
--! - mem_size_o:
--!     Specifies the data access width for memory load and store operations.
--!     "00" = Byte
--!     "01" = Halfword
--!     "10" = Word
--!
--! - mem_unsigned_o:
--!     Determines if the data from memory should be sign-extended or zero-extended.
--!     '0' = Signed (sign-extended, e.g., LB, LH)
--!     '1' = Unsigned (zero-extended, e.g., LBU, LHU)
--!
--! - mem_rw_o:
--!     Data memory control.
--!     '0' = Read
--!     '1' = Write
--!
--! - wb_select_o:
--!     Write-back multiplexer select.
--!     "00" = Data memory output (DataR)
--!     "01" = ALU result
--!     "10" = PC+4
--!     "11" = Imm from LUI instruction
--!
--! - pc_sel_o:
--!     Next PC value selector.
--!     '0' = PC + 4
--!     '1' = ALU result (Target branch address)
--!
--! - br_un_o:
--!     Selects branch comparison signedness.
--!     '0' = Signed comparison
--!     '1' = Unsigned comparison

library ieee;
use ieee.std_logic_1164.all;
use work.alu_pkg.all;

--! @brief Entity definition of control unit
entity control is
  port (
    opcode_i           : in  std_logic_vector(6 downto 0);  --! Instruction opcode
    funct3_i           : in  std_logic_vector(2 downto 0);  --! Instruction funct3 field
    funct7_i           : in  std_logic_vector(6 downto 0);  --! Instruction funct7 field
    imm_i_type_i       : in  std_logic_vector(11 downto 0); --! I-type immediate (instr[31:20])
    br_eq_i            : in  std_logic;                     --! Equality indicator from Branch Comparator
    br_lt_i            : in  std_logic;                     --! Less-than indicator from Branch Comparator
    halt_i             : in  std_logic;                     --! HALT state indicator (disables instruction decoding when the CPU enters HALT state)
    out_of_bound_i     : in  std_logic;                     --! Exception flag from imem module
    misaligned_i       : in  std_logic;                     --! Exception flag from imem module
    reg_write_enable_o : out std_logic;                     --! Register write enable signal
    imm_sel_o          : out std_logic_vector(2 downto 0);  --! Immediate select/qualifier
    b_sel_o            : out std_logic;                     --! ALU operand B select (0=rs2_data, 1=immediate)
    a_sel_o            : out std_logic;                     --! ALU operand A select (0=rs1_data, 1=PC)
    alu_op_o           : out t_alu_op;                      --! ALU operation select
    mem_rw_o           : out std_logic;                     --! Data memory control
    mem_size_o         : out std_logic_vector(1 downto 0);  --! 00=Byte, 01=Half, 10=Word
    mem_unsigned_o     : out std_logic;                     --! 1=Unsigned (LBU/LHU), 0=Signed
    wb_select_o        : out std_logic_vector(1 downto 0);  --! Write-back multiplexer select
    pc_sel_o           : out std_logic;                     --! Next PC select (0=PC+4, 1=Branch target)
    br_un_o            : out std_logic;                     --! Unsigned branch comparison enable
    invalid_instr_o    : out std_logic                      --! Illegal instruction detection used to trigger an exception and enter HALT state
  );
end entity control;

--! @brief Architecture implementation of control logic
--! @details
--! Provides safe defaults first, then overrides them when a supported
--! instruction encoding is detected.
architecture arch of control is
begin

--! @brief Illegal instruction detection and HALT interaction
--! @details
--! The control unit determines whether the currently decoded instruction
--! is a valid RV32I instruction supported by the core.
--!
--! A local variable `valid_instruction_v` is used during decoding to track
--! whether any legal opcode/funct combination has been detected.
--!
--! Decoding flow:
--! - `valid_instruction_v` is initialized to '0'
--! - Each supported instruction pattern sets `valid_instruction_v := '1'`
--! - If no pattern matches, the instruction is considered illegal
--!
--! The output signal `invalid_instr_o` is generated as:
--!
--!   invalid_instr_o = not valid_instruction_v
--!
--! This signal indicates that the instruction encoding is not supported
--! by the implemented subset of the RISC-V ISA.

  comb_proc : process (opcode_i, funct3_i, funct7_i, imm_i_type_i, br_eq_i, br_lt_i, halt_i, out_of_bound_i, misaligned_i)
    variable valid_instruction_v : std_logic; --! Internal flag indicating successful instruction decode
  begin
    reg_write_enable_o <= '0';
    b_sel_o            <= '0';
    a_sel_o            <= '0';
    alu_op_o           <= ALU_NOP;
    imm_sel_o          <= "000";
    mem_rw_o           <= '0';
    wb_select_o        <= "00";
    mem_size_o         <= "10"; -- Default Word
    mem_unsigned_o     <= '0';
    pc_sel_o           <= '0';
    br_un_o            <= '0';
    invalid_instr_o    <= '0';

    valid_instruction_v := '0';

    if halt_i = '0' and out_of_bound_i = '0' and misaligned_i = '0' then
-- =========================================================
--                 R-type ALU instructions
-- =========================================================
      if opcode_i = "0110011" then

        if funct3_i = "000" then
          if funct7_i = "0000000" then
            reg_write_enable_o <= '1';
            wb_select_o        <= "01";
            alu_op_o           <= ALU_ADD;
            valid_instruction_v := '1';
          elsif funct7_i = "0100000" then
            reg_write_enable_o <= '1';
            wb_select_o        <= "01";
            alu_op_o           <= ALU_SUB;
            valid_instruction_v := '1';
          end if;

        elsif (funct3_i = "001") and (funct7_i = "0000000") then
          reg_write_enable_o <= '1';
          wb_select_o        <= "01";
          alu_op_o           <= ALU_SLL;
          valid_instruction_v := '1';

        elsif (funct3_i = "010") and (funct7_i = "0000000") then
          reg_write_enable_o <= '1';
          wb_select_o        <= "01";
          alu_op_o           <= ALU_SLT;
          valid_instruction_v := '1';

        elsif (funct3_i = "011") and (funct7_i = "0000000") then
          reg_write_enable_o <= '1';
          wb_select_o        <= "01";
          alu_op_o           <= ALU_SLTU;
          valid_instruction_v := '1';

        elsif (funct3_i = "100") and (funct7_i = "0000000") then
          reg_write_enable_o <= '1';
          wb_select_o        <= "01";
          alu_op_o           <= ALU_XOR;
          valid_instruction_v := '1';

        elsif funct3_i = "101" then
          if funct7_i = "0000000" then
            reg_write_enable_o <= '1';
            wb_select_o        <= "01";
            alu_op_o           <= ALU_SRL;
            valid_instruction_v := '1';
          elsif funct7_i = "0100000" then
            reg_write_enable_o <= '1';
            wb_select_o        <= "01";
            alu_op_o           <= ALU_SRA;
            valid_instruction_v := '1';
          end if;

        elsif (funct3_i = "110") and (funct7_i = "0000000") then
          reg_write_enable_o <= '1';
          wb_select_o        <= "01";
          alu_op_o           <= ALU_OR;
          valid_instruction_v := '1';

        elsif (funct3_i = "111") and (funct7_i = "0000000") then
          reg_write_enable_o <= '1';
          wb_select_o        <= "01";
          alu_op_o           <= ALU_AND;
          valid_instruction_v := '1';
        end if;

-- =========================================================
--            I-type ALU immediate instructions
-- =========================================================
      elsif opcode_i = "0010011" then
        if funct3_i = "000" then
          imm_sel_o          <= "001";
          b_sel_o            <= '1';
          reg_write_enable_o <= '1';
          wb_select_o        <= "01";
          alu_op_o           <= ALU_ADD;
          valid_instruction_v := '1';

        elsif funct3_i = "010" then
          imm_sel_o          <= "001";
          b_sel_o            <= '1';
          reg_write_enable_o <= '1';
          wb_select_o        <= "01";
          alu_op_o           <= ALU_SLT;
          valid_instruction_v := '1';

        elsif funct3_i = "011" then
          imm_sel_o          <= "001";
          b_sel_o            <= '1';
          reg_write_enable_o <= '1';
          wb_select_o        <= "01";
          alu_op_o           <= ALU_SLTU;
          valid_instruction_v := '1';

        elsif funct3_i = "100" then
          imm_sel_o          <= "001";
          b_sel_o            <= '1';
          reg_write_enable_o <= '1';
          wb_select_o        <= "01";
          alu_op_o           <= ALU_XOR;
          valid_instruction_v := '1';

        elsif funct3_i = "110" then
          imm_sel_o          <= "001";
          b_sel_o            <= '1';
          reg_write_enable_o <= '1';
          wb_select_o        <= "01";
          alu_op_o           <= ALU_OR;
          valid_instruction_v := '1';

        elsif funct3_i = "111" then
          imm_sel_o          <= "001";
          b_sel_o            <= '1';
          reg_write_enable_o <= '1';
          wb_select_o        <= "01";
          alu_op_o           <= ALU_AND;
          valid_instruction_v := '1';

        elsif funct3_i = "001" then
          if imm_i_type_i(11 downto 5) = "0000000" then
            imm_sel_o          <= "001";
            b_sel_o            <= '1';
            reg_write_enable_o <= '1';
            wb_select_o        <= "01";
            alu_op_o           <= ALU_SLL;
            valid_instruction_v := '1';
          end if;

        elsif funct3_i = "101" then
          if imm_i_type_i(11 downto 5) = "0000000" then
            imm_sel_o          <= "001";
            b_sel_o            <= '1';
            reg_write_enable_o <= '1';
            wb_select_o        <= "01";
            alu_op_o           <= ALU_SRL;
            valid_instruction_v := '1';
          elsif imm_i_type_i(11 downto 5) = "0100000" then
            imm_sel_o          <= "001";
            b_sel_o            <= '1';
            reg_write_enable_o <= '1';
            wb_select_o        <= "01";
            alu_op_o           <= ALU_SRA;
            valid_instruction_v := '1';
          end if;
        end if;

-- =========================================================
--               LOAD and STORE instructions
-- =========================================================
      elsif opcode_i = "0000011" then

        if funct3_i = "000" or funct3_i = "001" or funct3_i = "010" or funct3_i = "100" or funct3_i = "101" then

          imm_sel_o   <= "001";
          b_sel_o     <= '1';
          alu_op_o    <= ALU_ADD;
          wb_select_o <= "00";
          reg_write_enable_o <= '1';
          mem_size_o         <= funct3_i(1 downto 0);
          mem_unsigned_o     <= funct3_i(2);
          valid_instruction_v := '1';

        end if;

      elsif opcode_i = "0100011" then
        if funct3_i = "000" or funct3_i = "001" or funct3_i = "010" then

          imm_sel_o <= "010";
          b_sel_o   <= '1';
          alu_op_o  <= ALU_ADD;
          mem_rw_o   <= '1';
          mem_size_o <= funct3_i(1 downto 0);
          valid_instruction_v := '1';

        end if;


-- =========================================================
--               BRANCH TYPE INSTRUCTIONS
-- =========================================================

      elsif opcode_i = "1100011" then
        if funct3_i = "000" or funct3_i = "001" or funct3_i = "100" or funct3_i = "101" or funct3_i = "110" or funct3_i = "111" then

          imm_sel_o <= "011";
          b_sel_o   <= '1';
          a_sel_o   <= '1';
          alu_op_o  <= ALU_ADD;
          reg_write_enable_o <= '0';
          valid_instruction_v := '1';

          case funct3_i is
            when "000" =>
              pc_sel_o <= br_eq_i;
            when "001" =>
              pc_sel_o <= not br_eq_i;
            when "100" =>
              pc_sel_o <= br_lt_i;
            when "101" =>
              pc_sel_o <= not br_lt_i;
            when "110" =>
              br_un_o  <= '1';
              pc_sel_o <= br_lt_i;
            when "111" =>
              br_un_o  <= '1';
              pc_sel_o <= not br_lt_i;
            when others =>
              pc_sel_o <= '0';
          end case;

        end if;

-- =========================================================
--               U-type (LUI, AUIPC)
-- =========================================================

      elsif opcode_i = "0110111" then
        reg_write_enable_o <= '1';
        imm_sel_o          <= "100";
        b_sel_o            <= '1';
        a_sel_o            <= '0';
        wb_select_o        <= "11";
        valid_instruction_v := '1';

      elsif opcode_i = "0010111" then
        reg_write_enable_o <= '1';
        imm_sel_o          <= "100";
        b_sel_o            <= '1';
        a_sel_o            <= '1';
        alu_op_o           <= ALU_ADD;
        wb_select_o        <= "01";
        valid_instruction_v := '1';

-- =========================================================
--               JAL and JALR
-- =========================================================

      elsif opcode_i = "1101111" then
        reg_write_enable_o <= '1';
        imm_sel_o          <= "101";
        a_sel_o            <= '1';
        b_sel_o            <= '1';
        alu_op_o           <= ALU_ADD;
        pc_sel_o           <= '1';
        wb_select_o        <= "10";
        valid_instruction_v := '1';

      elsif opcode_i = "1100111" and funct3_i = "000" then
        reg_write_enable_o <= '1';
        imm_sel_o          <= "001";
        a_sel_o            <= '0';
        b_sel_o            <= '1';
        alu_op_o           <= ALU_ADD;
        pc_sel_o           <= '1';
        wb_select_o        <= "10";
        valid_instruction_v := '1';

      end if;
      invalid_instr_o <= not valid_instruction_v;
    end if;
  end process comb_proc;

end architecture arch;
