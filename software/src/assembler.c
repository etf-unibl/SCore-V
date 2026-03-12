#include "../inc/assembler.h"

int main(int argc, char* argv[]) {
	FILE *fptr;
	if(argc != 2) {
		printf("Missing input file location argument");
		return 0;
	}

	fptr = fopen(argv[1], "r");
	if(fptr == NULL) {
		printf("Unable to open source file\n");
		return 0;
	}

	process_file(fptr);
	fclose(fptr);
}

void process_file(FILE* fptr) {
	char line[256];
	char line_dmem[5];
	FILE* fout;
	fout = fopen("../hardware/init_files/instruction_memory.txt", "w");
	if(fout == NULL) {
		printf("Unable to open program output file\n");
		return;
	}

	FILE *expected_out;
	expected_out = fopen("../hardware/init_files/expected.txt", "w");
	if(fptr == NULL) {
		printf("Unable to open expected output file");
		return;
	}

	// Load DMEM
	FILE *fdmem;
	fdmem = fopen("../hardware/init_files/data_memory.txt", "r");
	if(fdmem == NULL) {
		printf("Unable to load data_memory file, dmem will be empty");
		return;
	}
	else {
		int i=0;
		while(fgets(line_dmem, sizeof(line_dmem), fdmem)) {
			dmem[i++] = (uint8_t)strtol(line_dmem, NULL, 16);
		}

		fclose(fdmem);
	}

	while(fgets(line, sizeof(line), fptr)) {
		if(strcmp(line, "\n") == 0)
			continue;
		process_line(line, fout);
	}

	generate_expected(expected_out);

	fclose(fout);
	fclose(expected_out);
}

int i=0;
/**
 * Splits line by spaces, uses first argument to determine
 * the type of instruction using find_instruction.
 * Based on instruction type, gets needed registers
 * and/or immedietes using functions get_reg, get_reg_ls, get_imm and
 * get_imm_ls.
 * Load functions are of type I (meaning their machine code format is of type I),
 * but their assembly format resembles more that of a store function,
 * that is why there is distinction
 * in how those functions are handled in I_TYPE handling
 */
void process_line(char line[256], FILE* fout) {
	char pom_word[40];
	char line_copy[256];
	strcpy(line_copy, line);
	char* token = strtok(line_copy, " ");
	int i=0;
	char words[4][40];
	while(token != NULL) {
		strcpy(words[i], token);
		i++;
		token = strtok(NULL, " ");
	}

	Instruction *instr = find_instruction(words[0]);
	uint8_t reg1, reg2, regd;
	int imm;

	switch(instr->format) {
		case R_TYPE :
			regd = get_reg(words[1]);
			reg1 = get_reg(words[2]);
			reg2 = get_reg(words[3]);
			if((reg1 == 255) || (reg2 == 255) || (regd == 255)) {
				printf("Error passing args at [%s]\n", line);
				return;
			}
			handle_r_type(instr, regd, reg1, reg2, fout);
			break;
		case I_TYPE :
			memset(pom_word, 0, sizeof(pom_word));
			// Different handling of load functions because of their assembly format
			if(strcmp(instr->name, "lw")  == 0 || strcmp(instr->name, "lb") == 0 ||
			   strcmp(instr->name, "lbu") == 0 || strcmp(instr->name, "lh") == 0 ||
			   strcmp(instr->name, "lhu") == 0) {
				strcpy(pom_word, words[2]);
				regd = get_reg(words[1]);
				imm = get_imm_ls(words[2]);
				reg1 = get_reg_ls(pom_word);
				if(regd == 255 || reg1 == 255) {
					printf("Error passing args at [%s]\n", line);
					return;
				}
				handle_i_type(instr, regd, reg1, imm, fout);
				break;
			}

			regd = get_reg(words[1]);
			reg1 = get_reg(words[2]);
			imm = get_imm(words[3]);
			if(regd == 255 || reg1 == 255) {
				printf("Error passing args at [%s]\n", line);
				return;
			}
			handle_i_type(instr, regd, reg1, imm, fout);
			break;
		case S_TYPE :
			memset(pom_word, 0, sizeof(pom_word));
			strcpy(pom_word, words[2]);
			reg2 = get_reg(words[1]);
			imm = get_imm_ls(words[2]);
			reg1 = get_reg_ls(pom_word);
			if(reg2 == 255 || reg1 == 255) {
				printf("Error passing args at [%s]\n", line);
				return;
			}
			handle_s_type(instr, reg2, imm, reg1, fout);
			break;
		case B_TYPE :
			reg1 = get_reg(words[1]);
			reg2 = get_reg(words[2]);
			imm = get_imm(words[3]);
			if(reg1 == 255 || reg2 == 255) {
				printf("Error passing args at [%s]\n", line);
				return;
			}
			handle_b_type(instr, imm, reg1, reg2, fout);
			break;
		case J_TYPE :
			regd = get_reg(words[1]);
			imm = get_imm(words[2]);
			if(regd == 255) {
				printf("Error passing args at [%s]\n", line);
				return;
			}
			handle_j_type(instr, regd, imm, fout);
			break;
		case U_TYPE :
			regd = get_reg(words[1]);
			imm = get_imm(words[2]);
			if(regd == 255) {
				printf("Error passing args at [%s]\n", line);
				return;
			}
			handle_u_type(instr, regd, imm, fout);
			break;
		default :
			break;
	}
}

Instruction* find_instruction(const char *name) {
    int count = sizeof(instr_table) / sizeof(Instruction);

    for (int i = 0; i < count; i++) {
        if (strcmp(name, instr_table[i].name) == 0)
            return &instr_table[i];
    }
    return NULL;
}

/**
 * Returns only register number, excluding ','
 */
uint8_t get_reg(char reg_word[40]) {
	char* token = strtok(reg_word, ",");
	if (token[0] != 'x') return -1;
    return atoi(token + 1);
}

/**
 * Returns only imm number, excluding ','
 */
int get_imm(char word[40]) {
	char* token = strtok(word, ",");
    return atoi(token);
}

/**
 * With load sotre functions, syntax is different
 * because of brackets around second register.
 */
int get_imm_ls(char word[40]) {
	char* token = strtok(word, "(");
    return atoi(token);
}

/**
 * With load sotre functions, syntax is different
 * because of brackets around second register.
 */
uint8_t get_reg_ls(char word[40]) {
	char* token = strtok(word, "(),");
	token = strtok(NULL, "(),");
	if (token[0] != 'x') return -1;
    return atoi(token + 1);
}

/**
 * Compresses all bits that make an R_TYPE instruction,
 * stores it in a variable result, writes that result
 * to a file in a single line using function output_result.
 * Then writes expected result to other output file using
 * function output_expected.
 */
void handle_r_type(Instruction* instr, uint8_t regd, uint8_t reg1, uint8_t reg2, FILE* output) {
	uint32_t result;

	result = ((instr->funct7 & 0x7F) << 25) |
             ((reg2          & 0x1F) << 20) |
             ((reg1          & 0x1F) << 15) |
             ((instr->funct3 & 0x07) << 12) |
             ((regd          & 0x1F) << 7)  |
             (instr->opcode  & 0x7F);

	output_result(result, output);
	store_instruction(instr, regd, reg1, reg2, 0);
}

/**
 * Compresses all bits that make an I_TYPE instruction,
 * stores it in a variable result, writes that result
 * to a file in a single line using function output_result.
 * Then writes expected result to other output file using
 * function output_expected.
 */
void handle_i_type(Instruction* instr, uint8_t regd, uint8_t reg1, int imm, FILE* output) {
	uint32_t result;

	result = ((imm           & 0xFFF) << 20) |
             ((reg1          & 0x1F)  << 15) |
             ((instr->funct3 & 0x07)  << 12) |
             ((regd          & 0x1F)  << 7)  |
             (instr->opcode  & 0x7F);

	output_result(result, output);
	store_instruction(instr, regd, reg1, 0, imm);
}

/**
 * Compresses all bits that make an S_TYPE instruction,
 * stores it in a variable result, writes that result
 * to a file in a single line using function output_result.
 * Then writes expected result to other output file using
 * function output_expected.
 */
void handle_s_type(Instruction* instr, uint8_t reg2, int imm, uint8_t reg1, FILE* output) {
	uint32_t result;

	result = ((imm           & 0xFE0) << 20) |
             ((reg2          & 0x1F)  << 20) |
             ((reg1          & 0x1F)  << 15) |
             ((instr->funct3 & 0x07)  << 12) |
	         ((imm           & 0x1F)  << 7) |
             (instr->opcode  & 0x7F);

	output_result(result, output);
	store_instruction(instr, 0, reg1, reg2, imm);
}

void handle_b_type(Instruction* instr, int imm, uint8_t reg1, uint8_t reg2, FILE* output) {
	uint32_t result;

	result = ((imm           & 0x1000) << 19)  |
			 ((imm           & 0x7E0)  << 20)  |
             ((reg2          & 0x1F)   << 20)  |
             ((reg1          & 0x1F)   << 15)  |
			 ((instr->funct3 & 0x07)   << 12)  |
			 ((imm           & 0x1E)   << 7)   |
			 ((imm           & 0x800)  >> 4)   |
			 (instr->opcode & 0x7F);

	output_result(result, output);
	store_instruction(instr, 0, reg1, reg2, imm);
}

void handle_j_type(Instruction* instr, uint8_t regd, int imm, FILE* output) {
	uint32_t result;

	result = ((imm & 0x100000) << 11) |
			 ((imm & 0x7FE)    << 20) |
			 ((imm & 0x800)    << 9) |
			 ((imm & 0xFF000)  << 0) |
			 ((regd & 0x1F)    << 7) |
			 (instr->opcode & 0x7F);

	output_result(result, output);
	store_instruction(instr, regd, 0, 0, imm);
}

void handle_u_type(Instruction* instr, uint8_t regd, int imm, FILE* output) {
	uint32_t result;

	result = ((imm & 0xFFFFF ) << 12) |
			 ((regd & 0x1F)    << 7)  |
			 (instr->opcode & 0x7F);

	output_result(result, output);
	store_instruction(instr, regd, 0, 0, imm);
}

/* Format of the expected result:
 * pc, opcode, f3, f7, rd, rs1, rs2, alu_out, wb_out, we
 */
void output_expected(Instruction *instr, uint8_t regd, uint8_t reg1, uint8_t reg2, int imm, FILE* expected_out, int pc) {
	char exp_line[400];
	char we;
	int wb_out;
	int alu_out;
	uint32_t pc_old = pc;

	// Mask registers because of potential overflow
	reg1 &= 0x1F;
	reg2 &= 0x1F;
	regd &= 0x1F;

	if(instr->format == S_TYPE)
		we = '0';
	else
		we = '1';

	// If it's an R_TYPE instruction just calculate output using registers and signess of instruction
	if(instr->format == R_TYPE) {
		if(instr->signess == 0) {
			alu_out = instr->signed_operation(registers[reg1], registers[reg2]);
			registers[regd] = alu_out;
		}
		else {
			alu_out = instr->unsigned_operation(registers[reg1], registers[reg2]);
			registers[regd] = alu_out;
		}
		wb_out = alu_out;
	}
	// If the instruction is of I_TYPE, but NOT a LOAD instruction, do the same as for R_TYPE, except imm instead of reg2
	else if(instr->format == I_TYPE && strstr(instr->name, "lb") == NULL
									&& strstr(instr->name, "lh") == NULL
									&& strstr(instr->name, "lw") == NULL
									&& strstr(instr->name, "lbu") == NULL
									&& strstr(instr->name, "lhu") == NULL) {
		imm = (imm << 20) >> 20;

		if(strcmp(instr->name, "jalr") == 0) {
			registers[regd] = pc + 4;
			alu_out = pc;
		}
		else if(instr->signess == 0) {
			alu_out = instr->signed_operation(registers[reg1], imm);
			registers[regd] = alu_out;
		}
		else {
			alu_out = instr->unsigned_operation(registers[reg1], imm);
			registers[regd] = alu_out;
		}
		wb_out = alu_out;
	}
	// If it's Load or Store instruction
	else if(instr->format == S_TYPE || strcmp(instr->name, "lb") == 0 
                                    || strcmp(instr->name, "lh") == 0
                                    || strcmp(instr->name, "lw") == 0
                                    || strcmp(instr->name, "lbu") == 0
                                    || strcmp(instr->name, "lhu") == 0)  {
		imm = (imm << 20) >> 20;

		alu_out = imm + registers[reg1];
		if(instr->format == S_TYPE) {
			// Store value of register reg2 to 4 bytes of dmem (because of word)
			if(strcmp(instr->name, "sw") == 0) {
				dmem[alu_out + 3] = ((registers[reg2] & 0xFF000000) >> 24);
				dmem[alu_out + 2] = ((registers[reg2] & 0xFF0000) >> 16);
				dmem[alu_out + 1] = ((registers[reg2] & 0xFF00) >> 8);
				dmem[alu_out] = registers[reg2] & 0xFF;
				wb_out = (((uint32_t)dmem[alu_out+3]) << 24) |
         				 (((uint32_t)dmem[alu_out+2]) << 16) |
         				 (((uint32_t)dmem[alu_out+1]) << 8)  |
         				 (((uint32_t)dmem[alu_out]));
			}
			// Store value of register reg2 to 2 bytes of dmem (because of half)
			else if(strcmp(instr->name, "sh") == 0) {
				dmem[alu_out + 1] = ((registers[reg2] & 0xFF00) >> 8);
				dmem[alu_out] = registers[reg2] & 0xFF;
				wb_out = ((0x00001111 & (((uint32_t)(dmem[alu_out+1] << 8)) | dmem[alu_out])));
			}
			// Store value of register reg2 to a byte of dmem (because of byte)
			else if(strcmp(instr->name, "sb") == 0) {
				dmem[alu_out] = registers[reg2] & 0xFF;
				wb_out = (0x00000011 & dmem[alu_out]);
			}
		}
		else {
			int sign_pom;
			// Load value from 4 bytes of dmem, signed.
			if(strcmp(instr->name, "lw") == 0) {
				registers[regd] = (((uint32_t)dmem[alu_out + 3]) << 24) |
								  (((uint32_t)dmem[alu_out + 2]) << 16) |
								  (((uint32_t)dmem[alu_out + 1]) << 8)  |
								  (dmem[alu_out]);
				wb_out = registers[regd];
			}
			// Load value from 2 bytes of dmem, signed.
			else if(strcmp(instr->name, "lh") == 0) {
				if((dmem[alu_out + 1] & 0x80) != 0)
					sign_pom = 0xFFFFFFFF;
				else
					sign_pom = 0x0000FFFF;

				registers[regd] = sign_pom & 
					              	(((uint32_t)dmem[alu_out + 1] << 8)  |
								  	(dmem[alu_out]));
				wb_out = registers[regd];
			}
			// Load value from a byte of dmem, signed.
			else if(strcmp(instr->name, "lb") == 0) {
				if((dmem[alu_out] & 0x80) != 0)
					sign_pom = 0xFFFFFFFF;
				else
					sign_pom = 0x000000FF;

				registers[regd] = 0x000000FF & (dmem[alu_out]);
				wb_out = registers[regd];
			}
			// Load value from 2 bytes of dmem, signed.
			else if(strcmp(instr->name, "lhu") == 0) {
				registers[regd] = (0x0000FFFF) & 
									((dmem[alu_out + 1] << 8)  |
								  	(dmem[alu_out]));
				wb_out = registers[regd];
			}
			// Load value from a byte of dmem, unsigned.
			else if(strcmp(instr->name, "lbu") == 0) {
				registers[regd] = 0x000000FF & (dmem[alu_out]);
				wb_out = registers[regd];
			}
		}
	}
	else if(instr->format == J_TYPE) {
		uint32_t return_addr = pc + 4;
		registers[regd] = return_addr;
		alu_out = pc+imm;
		wb_out = pc+imm;
		we = '1';
	}
	else if(instr->format == B_TYPE) {
		imm = (imm << 19) >> 19;
		unsigned int branch_target = pc + imm;
		alu_out = branch_target;
		wb_out = 0;
		we = '0';
	}
	else if(instr->format == U_TYPE) {
		if(strcmp(instr->name, "lui") == 0) {
			wb_out = instr->signed_operation(0, imm);
			alu_out = 0;
			registers[regd] = alu_out;
		}
		else {
			wb_out = instr->signed_operation(pc, imm);
			alu_out = wb_out;
			registers[regd] = alu_out;
		}
		we = '1';
	}

	char funct3[4] = "";
	char funct7[8] = "";
	char opcode[8] = "";

	bits_to_str(instr->opcode, 7, opcode);
	bits_to_str(instr->funct3, 3, funct3);
	bits_to_str(instr->funct7, 7, funct7);

	registers[0] = 0;

	if(regd == 0 && we == 1) {
		registers[regd] = 0;
		alu_out = 0;
		we = 0;
	}

	// Combine all arguments to a single string
	sprintf(exp_line, "%u, \"%s\", \"%s\", \"%s\", %u, %u, %u, %d, %d, '%c'\n",
			pc_old, opcode, funct3, funct7, regd, reg1, reg2, alu_out, wb_out, we);

	fputs(exp_line, expected_out);
}

void bits_to_str(unsigned int value, int bits, char *out)
{
    for (int i = bits - 1; i >= 0; i--) {
        *out++ = ((value >> i) & 1) ? '1' : '0';
    }
    *out = '\0';
}

/**
 * Writes instruction machine code to output file
 */
void output_result(uint32_t result, FILE* output) {
	char instruction[35];
	bits_to_str(result, 32, instruction);
	instruction[32] = '\n';
	instruction[33] = '\0';
	fputs(instruction, output);
}

void store_instruction(Instruction* instr, uint8_t regd, uint8_t reg1, uint8_t reg2, int imm) {
    stored_instructions[total_instructions++] = (StoredInstruction){instr, regd, reg1, reg2, imm};
}

void generate_expected(FILE* expected_out) {
    int pc = 0;
    while(pc < total_instructions * 4) {
        StoredInstruction* s = &stored_instructions[pc / 4];

        output_expected(s->instr, s->regd, s->reg1, s->reg2, s->imm, expected_out, pc);

        if(s->instr->format == J_TYPE) {
            pc += s->imm;
		}
        else if(s->instr->format == B_TYPE && branch_taken(s)) {
            pc += s->imm;
		}
		else if(s->instr->opcode == 0x67) {
            pc = (registers[s->reg1] + s->imm) & ~1;
		}
        else {
            pc += 4;
		}
    }
}

int branch_taken(StoredInstruction* s) {
    uint32_t rs1 = registers[s->reg1];
    uint32_t rs2 = registers[s->reg2];

    switch(s->instr->funct3) {
        case 0x0: return rs1 == rs2;
        case 0x1: return rs1 != rs2;
		case 0x4: return (int32_t)rs1 <  (int32_t)rs2;
        case 0x5: return (int32_t)rs1 >= (int32_t)rs2;
        case 0x6: return rs1 <  rs2;
        case 0x7: return rs1 >= rs2;
        default:  return 0;
    }
}
