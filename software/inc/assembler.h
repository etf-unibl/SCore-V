#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

typedef enum {
    R_TYPE,
    I_TYPE,
    S_TYPE
} InstrFormat;

typedef struct {
    const char *name;
    InstrFormat format;
    uint8_t opcode;
    uint8_t funct3;
    uint8_t funct7;
	uint16_t imm;
} Instruction;

Instruction instr_table[] = {
	{"add",   R_TYPE, 0x33, 0x0, 0x00},
	{"sub",   R_TYPE, 0x33, 0x0, 0x02},
	{"xor",   R_TYPE, 0x33, 0x4, 0x00},
	{"or",    R_TYPE, 0x33, 0x6, 0x00},
	{"and",   R_TYPE, 0x33, 0x7, 0x00},
	{"sll",   R_TYPE, 0x33, 0x1, 0x00},
	{"srl",   R_TYPE, 0x33, 0x5, 0x00},
	{"sra",   R_TYPE, 0x33, 0x5, 0x02},
	{"slt",   R_TYPE, 0x33, 0x2, 0x00},
	{"sltu",  R_TYPE, 0x33, 0x3, 0x00},

	{"addi",  I_TYPE, 0x13, 0x0, 0x00},
	{"xori",  I_TYPE, 0x13, 0x4, 0x00},
	{"ori",   I_TYPE, 0x13, 0x6, 0x00},
	{"andi",  I_TYPE, 0x13, 0x7, 0x00},
	{"slli",  I_TYPE, 0x13, 0x1, 0x00},
	{"srli",  I_TYPE, 0x13, 0x5, 0x00},
	{"srai",  I_TYPE, 0x13, 0x5, 0x00},
	{"slti",  I_TYPE, 0x13, 0x2, 0x00},
	{"sltiu", I_TYPE, 0x13, 0x2, 0x00},

	{"lb",    I_TYPE, 0x03, 0x0, 0x00},
	{"lh",    I_TYPE, 0x03, 0x1, 0x00},
	{"lw",    I_TYPE, 0x03, 0x2, 0x00},
	{"lbu",   I_TYPE, 0x03, 0x4, 0x00},
	{"lbu",   I_TYPE, 0x03, 0x5, 0x00},

	{"sb",    S_TYPE, 0x23, 0x0, 0x00},
	{"sh",   S_TYPE, 0x23, 0x1, 0x00},
	{"sw",   S_TYPE, 0x23, 0x2, 0x00}
};

/** Function that call process_line function on each line
 * of input .txt.
 */
void process_file(FILE *fptr);

/** Function that find type of instruction (R, I or S) and
 * converts it to machine code approprietely.
 */
void process_line(char line[256], FILE* fout);

/** Returns register number from a string,
 * used in handle_x_type functions.
 */
uint8_t get_reg(char reg_word[40]);

/** Returns imm value from a string,
 * used in handle_x_type functions.
 */
uint16_t get_imm(char word[40]);

/** Returns imm value from a string,
 * used in handle_x_type functions of load/store
 * type.
 */
uint16_t get_imm_ls(char word[40]);

/** Returns imm value from a string,
 * used in handle_x_type functions of load/store
 * type.
 */
uint8_t get_reg_ls(char word[40]);

/** Function that writes a single instruction machine code
 * to output file
 */
void output_result(uint32_t result, FILE* output);

/** Helper function that finds type of instrucion */
Instruction* find_instruction(const char *name);

/** Handles R_TYPE instructions, fills uint32_t result and
 *  calls output_result function.
 */
void handle_r_type(Instruction* instr, uint8_t regd, uint8_t reg1, uint8_t reg2, FILE* output);

/** Handles I_TYPE instructions, fills uint32_t result and
 *  calls output_result function.
 */
void handle_i_type(Instruction* instr, uint8_t regd, uint8_t reg1, uint16_t imm, FILE* output);

/** Handles S_TYPE instructions, fills uint32_t result and
 *  calls output_result function.
 */
void handle_s_type(Instruction* instr, uint8_t regd, uint8_t reg1, uint16_t imm, FILE* output);
