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
	FILE* fout;
	fout = fopen("../hardware/tests/program.txt", "w");
	if(fout == NULL) {
		printf("Unable to open program output file\n");
		return;
	}

	FILE *expected_out;
	expected_out = fopen("../hardware/tests/expected.txt", "w");
	if(fptr == NULL) {
		printf("Unable to open expected output file");
		return;
	}


	while(fgets(line, sizeof(line), fptr)) {
		process_line(line, fout, expected_out);
	}

	fclose(fout);
	fclose(expected_out);
}

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
void process_line(char line[256], FILE* fout, FILE* expected_out) {
	printf("%s", line);	

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
	uint8_t reg1, reg2, regd, imm;

	switch(instr->format) {
		case R_TYPE :
			regd = get_reg(words[1]);
			reg1 = get_reg(words[2]);
			reg2 = get_reg(words[3]);
			if((reg1 == 255) || (reg2 == 255) || (regd == 255)) {
				printf("Error passing args at [%s]\n", line);
				return;
			}
			handle_r_type(instr, regd, reg1, reg2, fout, expected_out);
			break;
		case I_TYPE :
			// Different handling of load functions because of their assembly format
			if(strcmp(instr->name, "lw")  == 0 || strcmp(instr->name, "lb") == 0 ||
			   strcmp(instr->name, "lbu") == 0 || strcmp(instr->name, "lh") == 0 ||
			   strcmp(instr->name, "lhu") == 0) {
				char pom_word[40];
				strcpy(pom_word, words[2]);
				regd = get_reg(words[1]);
				imm = get_imm_ls(words[2]);
				reg1 = get_reg_ls(pom_word);
				if(regd == 255 || reg1 == 255) {
					printf("Error passing args at [%s]\n", line);
					return;
				}
				handle_i_type(instr, regd, reg1, imm, fout, expected_out);
				break;
			}

			regd = get_reg(words[1]);
			reg1 = get_reg(words[2]);
			imm = get_imm(words[3]);
			if(regd == 255 || reg1 == 255) {
				printf("Error passing args at [%s]\n", line);
				return;
			}
			handle_i_type(instr, regd, reg1, imm, fout, expected_out);
			break;
		case S_TYPE :
			char pom_word[40];
			strcpy(pom_word, words[2]);
			regd = get_reg(words[1]);
			imm = get_imm_ls(words[2]);
			reg1 = get_reg_ls(pom_word);
			if(regd == 255 || reg1 == 255) {
				printf("Error passing args at [%s]\n", line);
				return;
			}
			handle_s_type(instr, regd, imm, reg1, fout, expected_out);
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
uint16_t get_imm(char word[40]) {
	char* token = strtok(word, ",");
    return atoi(token);
}

/**
 * With load sotre functions, syntax is different
 * because of brackets around second register.
 */
uint16_t get_imm_ls(char word[40]) {
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
void handle_r_type(Instruction* instr, uint8_t regd, uint8_t reg1, uint8_t reg2, FILE* output, FILE* expected_out) {
	uint32_t result;

	result = ((instr->funct7 & 0x7F) << 25) |
             ((reg2          & 0x1F) << 20) |
             ((reg1          & 0x1F) << 15) |
             ((instr->funct3 & 0x07) << 12) |
             ((regd          & 0x1F) << 7)  |
             (instr->opcode  & 0x7F);

	printf("0x%X\n\n", result);

	output_result(result, output);
	output_expected(instr, regd, reg1, reg2, 0, expected_out);
}

/**
 * Compresses all bits that make an I_TYPE instruction,
 * stores it in a variable result, writes that result
 * to a file in a single line using function output_result.
 * Then writes expected result to other output file using
 * function output_expected.
 */
void handle_i_type(Instruction* instr, uint8_t regd, uint8_t reg1, uint16_t imm, FILE* output, FILE* expected_out) {
	uint32_t result;

	result = ((imm           & 0x7FF) << 20) |
             ((reg1          & 0x1F)  << 15) |
             ((instr->funct3 & 0x07)  << 12) |
             ((regd          & 0x1F)  << 7)  |
             (instr->opcode  & 0x7F);

	printf("0x%X\n\n", result);

	output_result(result, output);
	output_expected(instr, regd, reg1, 0, imm, expected_out);
}

/**
 * Compresses all bits that make an S_TYPE instruction,
 * stores it in a variable result, writes that result
 * to a file in a single line using function output_result.
 * Then writes expected result to other output file using
 * function output_expected.
 */
void handle_s_type(Instruction* instr, uint8_t regd, uint16_t imm, uint8_t reg1, FILE* output, FILE* expected_out) {
	uint32_t result;

	result = ((imm           & 0xFE0) << 25) |
             ((regd          & 0x1F)  << 20) |
             ((reg1          & 0x1F)  << 15) |
             ((instr->funct3 & 0x07)  << 12) |
	         ((imm           & 0x1F)  << 7) |
             (instr->opcode  & 0x7F);

	printf("0x%X\n\n", result);

	output_result(result, output);
	output_expected(instr, regd, reg1, 0, imm, expected_out);
}

/* Format of the expected result:
 * pc, opcode, f3, f7, rd, rs1, rs2, alu_out, wb_out, wb
 */
void output_expected(Instruction *instr, uint8_t regd, uint8_t reg1, uint8_t reg2, uint16_t imm, FILE* expected_out) {
	char exp_line[400];
	char wb;
	int wb_out;
	int alu_out;

	// Mask registers because of potential overflow
	reg1 &= 0x1F;
	reg2 &= 0x1F;
	regd &= 0x1F;

	if(instr->format == S_TYPE)
		wb = '0';
	else
		wb = '1';

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
	else if(instr->format == I_TYPE && strstr(instr->name, "l") == NULL) {
		if(instr->signess == 0) {
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
	else if(strstr(instr->name, "l") != NULL || instr->format == S_TYPE) {
		alu_out = imm + registers[reg1];
		if(instr->format == S_TYPE) {
			// Store value of register regd to 4 bytes of dmem (because of word)
			if(strcmp(instr->name, "sw") == 0) {
				dmem[alu_out + 3] = ((registers[regd] & 0xFF000000) >> 24);
				dmem[alu_out + 2] = ((registers[regd] & 0xFF0000) >> 16);
				dmem[alu_out + 1] = ((registers[regd] & 0xFF00) >> 8);
				dmem[alu_out] = registers[regd] & 0xFF;
				wb_out = dmem[alu_out+3] | dmem[alu_out+2] | dmem[alu_out+1] | dmem[alu_out];
			}
			// Store value of register regd to 2 bytes of dmem (because of half)
			else if(strcmp(instr->name, "sh") == 0) {
				dmem[alu_out + 1] = ((registers[regd] & 0xFF00) >> 8);
				dmem[alu_out] = registers[regd] & 0xFF;
				wb_out = ((0x00001111 & (dmem[alu_out+1] | dmem[alu_out])));
			}
			// Store value of register regd to a byte of dmem (because of byte)
			else if(strcmp(instr->name, "sb") == 0) {
				dmem[alu_out] = registers[regd] & 0xFF;
				wb_out = (0x00000011 & dmem[alu_out]);
			}
		}
		else {
			int sign_pom;
			// Load value from 4 bytes of dmem, signed.
			if(strcmp(instr->name, "lw") == 0) {
				registers[regd] = (dmem[alu_out + 3] << 24) |
								  (dmem[alu_out + 2] << 16) |
								  (dmem[alu_out + 1] << 8)  |
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
					              	((dmem[alu_out + 1] << 8)  |
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
			registers[regd] = dmem[alu_out];
			wb_out = registers[regd];
		}
	}

	// Combine all arguments to a single string
	sprintf(exp_line, "%u, \"%07b\", \"%03b\", \"%07b\", %u, %u, %u, %d, %d, '%c'\n",
			pc, instr->opcode, instr->funct3, instr->funct7, regd, reg1, reg2, alu_out, wb_out, wb);

	fputs(exp_line, expected_out);

	// increment program counter
	pc += 4;

	printf("EXPECTED: %s\n", exp_line);
}

/**
 * Writes instruction machine code to output file
 */
void output_result(uint32_t result, FILE* output) {
	char instruction[35];
	sprintf(instruction, "%032b\n", result);
	fputs(instruction, output);
}
