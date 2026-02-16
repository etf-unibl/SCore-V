library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity control_tb is

end control_tb;

architecture arch of control_tb is

    -- Component Declaration for the Unit Under Test (UUT)
    component control
    port(
        opcode_i           : in  std_logic_vector(6 downto 0);
        funct3_i           : in  std_logic_vector(2 downto 0);
        funct7_i           : in  std_logic_vector(6 downto 0);
        reg_write_enable_o : out std_logic
    );
    end component;

    -- Signals to connect to UUT
    signal s_opcode           : std_logic_vector(6 downto 0) := (others => '0');
    signal s_funct3           : std_logic_vector(2 downto 0) := (others => '0');
    signal s_funct7           : std_logic_vector(6 downto 0) := (others => '0');
    signal s_reg_write_enable : std_logic;

begin

    -- Instantiate the Unit Under Test (UUT)
    uut: control port map (
        opcode_i           => s_opcode,
        funct3_i           => s_funct3,
        funct7_i           => s_funct7,
        reg_write_enable_o => s_reg_write_enable
    );

    -- Stimulus process
    stim_proc: process
    begin
        -- wait for global reset if needed
        wait for 100 ns;

        ------------------------------------------------------------
        -- TEST CASE 1: Valid ADD Instruction
        -- Opcode = 0110011
        -- funct3 = 0x0 (000)
        -- funct7 = 0x00 (0000000)
        ------------------------------------------------------------
        report "Test Case 1: Testing ADD instruction...";
        s_opcode <= "0110011";
        s_funct3 <= "000";
        s_funct7 <= "0000000";
        wait for 10 ns;
        
        assert s_reg_write_enable = '1'
        report "FAILURE: ADD instruction did not assert reg_write_enable!"
        severity error;

        ------------------------------------------------------------
        -- TEST CASE 2: SUB Instruction (Negative Test)
        -- Same Opcode, Same Funct3, but different Funct7 (0x20)
        ------------------------------------------------------------
        report "Test Case 2: Testing SUB instruction (should differ by funct7)...";
        s_opcode <= "0110011";
        s_funct3 <= "000";
        s_funct7 <= "0100000"; 
        wait for 10 ns;

        assert s_reg_write_enable = '0'
        report "FAILURE: SUB instruction asserted reg_write_enable incorrectly (Check Funct7 logic)!"
        severity error;

        ------------------------------------------------------------
        -- TEST CASE 3: ADDI Instruction (Negative Test)
        -- Different Opcode (I-type), should not trigger logic targeted at R-type ADD
        -- Opcode = 0010011 
        ------------------------------------------------------------
        report "Test Case 3: Testing ADDI instruction (different opcode)...";
        s_opcode <= "0010011";
        s_funct3 <= "000";
        s_funct7 <= "0000000";
        wait for 10 ns;

        assert s_reg_write_enable = '0'
        report "FAILURE: ADDI instruction asserted reg_write_enable incorrectly (Check Opcode logic)!"
        severity error;

        ------------------------------------------------------------
        -- TEST CASE 4: SLL Instruction (Negative Test)
        -- Same Opcode (R-type), Same Funct7, but different Funct3
        -- Funct3 = 0x1 (001) 
        ------------------------------------------------------------
        report "Test Case 4: Testing SLL instruction (different funct3)...";
        s_opcode <= "0110011";
        s_funct3 <= "001";
        s_funct7 <= "0000000";
        wait for 10 ns;

        assert s_reg_write_enable = '0'
        report "FAILURE: SLL instruction asserted reg_write_enable incorrectly (Check Funct3 logic)!"
        severity error;

        ------------------------------------------------------------
        -- End of simulation
        ------------------------------------------------------------
        report "Simulation Completed Successfully. If no failures reported above, design is correct.";
        wait;
    end process;

end arch;