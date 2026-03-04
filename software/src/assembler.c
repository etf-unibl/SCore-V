#include "../inc/assembler.h"

int main(int argc, char* argv[]) {
	FILE *fptr;
	fptr = fopen("test.txt", "r");
	if(fptr == NULL) {
		printf("Unable to open file");
		return 0;
	}

	process_file(fptr);

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
	if (token[0] != 'r') return -1;
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
	if (token[0] != 'r') return -1;
    return atoi(token + 1);
}

void handle_r_type(Instruction* instr, uint8_t regd, uint8_t reg1, uint8_t reg2, FILE* output, FILE* expected_out) {
	uint32_t result;

	printf("\nreg2 0x%X\n", reg2 & 0x1F);
	printf("reg1 0x%X\n", reg1 & 0x1F);
	printf("regd 0x%X\n", regd & 0x1F);

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

	printf("\nregd 0x%X\n", regd & 0x1F);
	printf("reg1 0x%X\n", reg1 & 0x1F);
	printf("imm 0x%X\n", imm & 0x7FF);

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

	printf("\nregd 0x%X\n", regd & 0x1F);
	printf("reg1 0x%X\n", reg1 & 0x1F);
	printf("imm 0x%X\n", imm & 0x7FF);

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

	wb = 'c';
	alu_out = 12;
	wb_out = 14;

	sprintf(exp_line, "%u, \"%07b\", \"%03b\", \"%07b\", %u, %u, %u, %d, %d, '%c'",
			pc, instr->opcode, instr->funct3, instr->funct7, regd, reg1, reg2, alu_out, wb_out, wb);
	pc += 4;

	printf("EXPECTED: %s\n", exp_line);
}

void output_result(uint32_t result, FILE* output) {
	int i=0;
	while (result) {
    	if (result & 1)
        	fputc('1', output);
    	else
        	fputc('0', output);
    	result >>= 1;
		i++;
	}
	for(;i<32;i++) {
        fputc('0', output);
	}
	fputc('\n', output);
}
