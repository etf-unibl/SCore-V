#include "../inc/assembler.h"

int main(int argc, char* argv[]) {
	FILE *fptr;
	if(argc != 2) {
		printf("Missing input file location argument");
		return 0;
	}
	fptr = fopen(argv[1], "r");
	if(fptr == NULL) {
		printf("Unable to open file");
		return 0;
	}

	process_file(fptr);
	for(int i=0;i<12;i++)
		printf("%08b\n", dmem[i]);

	fclose(fptr);
}

void process_file(FILE* fptr) {
	char line[256];
	FILE* fout;
	fout = fopen("output.txt", "w");
	if(fout == NULL) {
		printf("Unable to open file\n");
	}

	FILE *expected_out;
	expected_out = fopen("expected.txt", "w");
	if(fptr == NULL) {
		printf("Unable to open file");
		return;
	}


	while(fgets(line, sizeof(line), fptr)) {
		process_line(line, fout, expected_out);
	}

	fclose(fout);
	fclose(expected_out);
}

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

uint8_t get_reg(char reg_word[40]) {
	char* token = strtok(reg_word, ",");
	if (token[0] != 'x') return -1;
    return atoi(token + 1);
}

uint16_t get_imm(char word[40]) {
	char* token = strtok(word, ",");
    return atoi(token);
}

uint16_t get_imm_ls(char word[40]) {
	char* token = strtok(word, "(");
    return atoi(token);
}

uint8_t get_reg_ls(char word[40]) {
	char* token = strtok(word, "(),");
	token = strtok(NULL, "(),");
	if (token[0] != 'x') return -1;
    return atoi(token + 1);
}

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

/* Format of the array:
 * pc, opcode, f3, f7, rd, rs1, rs2, alu_out, wb_out, wb
 */
void output_expected(Instruction *instr, uint8_t regd, uint8_t reg1, uint8_t reg2, uint16_t imm, FILE* expected_out) {
	char exp_line[400];
	char wb;
	int wb_out;
	int alu_out;

	reg1 &= 0x1F;
	reg2 &= 0x1F;
	regd &= 0x1F;

	if(instr->format == S_TYPE)
		wb = '0';
	else
		wb = '1';
	wb_out = 14;

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
	else if(strstr(instr->name, "l") != NULL || instr->format == S_TYPE) {
		alu_out = imm + registers[reg1];
		if(instr->format == S_TYPE) {
			if(strcmp(instr->name, "sw") == 0) {
				dmem[alu_out + 3] = ((registers[regd] & 0xFF000000) >> 24);
				dmem[alu_out + 2] = ((registers[regd] & 0xFF0000) >> 16);
				dmem[alu_out + 1] = ((registers[regd] & 0xFF00) >> 8);
				dmem[alu_out] = registers[regd] & 0xFF;
				wb_out = dmem[alu_out+3] | dmem[alu_out+2] | dmem[alu_out+1] | dmem[alu_out];
			}
			else if(strcmp(instr->name, "sh") == 0) {
				dmem[alu_out + 1] = ((registers[regd] & 0xFF00) >> 8);
				dmem[alu_out] = registers[regd] & 0xFF;
				wb_out = ((0x00001111 & (dmem[alu_out+1] | dmem[alu_out])));
			}
			else if(strcmp(instr->name, "sb") == 0) {
				dmem[alu_out] = registers[regd] & 0xFF;
				wb_out = (0x00000011 & dmem[alu_out]);
			}
		}
		else {
			int sign_pom;
			if(strcmp(instr->name, "lw") == 0) {
				registers[regd] = (dmem[alu_out + 3] << 24) |
								  (dmem[alu_out + 2] << 16) |
								  (dmem[alu_out + 1] << 8)  |
								  (dmem[alu_out]);
				wb_out = registers[regd];
			}
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
			else if(strcmp(instr->name, "lb") == 0) {
				if((dmem[alu_out] & 0x80) != 0)
					sign_pom = 0xFFFFFFFF;
				else
					sign_pom = 0x000000FF;

				registers[regd] = 0x000000FF & (dmem[alu_out]);
				wb_out = registers[regd];
			}
			else if(strcmp(instr->name, "lhu") == 0) {
				registers[regd] = (0x0000FFFF) & 
									((dmem[alu_out + 1] << 8)  |
								  	(dmem[alu_out]));
				wb_out = registers[regd];
			}
			else if(strcmp(instr->name, "lbu") == 0) {
				registers[regd] = 0x000000FF & (dmem[alu_out]);
				wb_out = registers[regd];
			}
			registers[regd] = dmem[alu_out];
			wb_out = registers[regd];
		}
	}

	sprintf(exp_line, "%u, \"%07b\", \"%03b\", \"%07b\", %u, %u, %u, %d, %d, '%c'",
			pc, instr->opcode, instr->funct3, instr->funct7, regd, reg1, reg2, alu_out, wb_out, wb);
	pc += 4;

	printf("EXPECTED: %s\n", exp_line);
}

void output_result(uint32_t result, FILE* output) {
	char instruction[35];
	sprintf(instruction, "%032b\n", result);
	fputs(instruction, output);
}
