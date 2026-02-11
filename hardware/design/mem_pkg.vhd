library ieee;
use ieee.std_logic_1164.all;


package mem_pkg is

  type t_instruction_rec is record
		  
    opcode                      : std_logic_vector(6 downto 0);
    other_instruction_bits      : std_logic_vector(24 downto 0);
	 
  end record;

  -- different formats based on the opcode  
  type t_instruction_R is record
    
    func7 : std_logic_vector(6 downto 0);
	 rs2   : std_logic_vector(4 downto 0);
	 rs1   : std_logic_vector(4 downto 0);
	 func3 : std_logic_vector(2 downto 0);
	 rd    : std_logic_vector(4 downto 0);    
	 
  end record;
  
  type t_instruction_I is record
		  
    resid : std_logic;
	 imm   : std_logic_vector(10 downto 0);
	 rs1   : std_logic_vector(4 downto 0);
	 func3 : std_logic_vector(2 downto 0);
	 rd    : std_logic_vector(4 downto 0);
	 
  end record;
  
  type t_instruction_S is record

    imm2  : std_logic_vector(5 downto 0);
    rs2   : std_logic_vector(4 downto 0);
    rs1   : std_logic_vector(4 downto 0);
    func3 : std_logic_vector(2 downto 0);
    imm1  : std_logic_vector(4 downto 0);    
	 
  end record;

  -- 2. Define the array as a collection of those records
  type t_instr_array is array (0 to 3) of t_instruction_rec;
    
  constant IMEM : t_instr_array := (
    0 => (opcode => "0110011", other_instruction_bits => "0000000000010000100001111"),
    1 => (opcode => "0110011", other_instruction_bits => "0000000000010001100000111"),
    2 => (opcode => "0110011", other_instruction_bits => "0000000000010011100000011"),
	 3 => (opcode => "0110011", other_instruction_bits => "0000000000010011100000011")
  );

end mem_pkg;
