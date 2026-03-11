/**
 * @file assembler.h
 */

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

/**
 * Enum for currently supported types of instructions.
 * Used in Instruction struct.
 */
typedef enum {
    R_TYPE,
    I_TYPE,
    S_TYPE,
	B_TYPE,
	J_TYPE,
	U_TYPE
} InstrFormat;

/// Array of registers used in expected result generator
int32_t registers[32];

/// Data memory used in expected result generator
uint8_t dmem[1024];

// Below functions are used in calculating expected output
int add(int a, int b) { return a+b; }
int sub(int a, int b) { return a-b; }
int xor_op(int a, int b) { return a^b; }
int or_op(int a, int b) { return a|b; }
int and_op(int a, int b) { return a&b; }
int sll(int a, int b) { return a<<b; }
unsigned int srl(unsigned int a, unsigned int b) { return a>>b; }
int sra(int a, int b) { return a>>b; }
int slt(int a, int b) { return (a < b)?1:0; }
unsigned int sltu(unsigned int a, unsigned int b) { return (a < b)?1:0; }
unsigned addiu(unsigned int a, unsigned int b) { return a + b; } // For load and store functions:
int utype_fun(int a, int b) { return a + (b<<12); }
int beq(int a, int b) { return a==b; }
int bne(int a, int b) { return a!=b; }
int blt(int a, int b) { return a<b; }
int bge(int a, int b) { return a>=b; }
unsigned int bltu(unsigned int a, unsigned int b) { return a<b; }
unsigned int bgeu(unsigned int a, unsigned int b) { return a<b; }

/**
 * Program Counter, used for expected result generator
 */
unsigned int pc = 0;

/**
 * Struct used for defining different types of instructions.
 */
typedef struct {
    const char *name;
    InstrFormat format;
    uint8_t opcode;
    uint8_t funct3;
    uint8_t funct7;
	uint8_t signess;
	int (*signed_operation)(int, int);
    unsigned int (*unsigned_operation)(unsigned int, unsigned int);
} Instruction;

/**
 * Table of currently supported functions
 */
Instruction instr_table[] = {
	{"add",   R_TYPE, 0x33, 0x0, 0x00, 0, add, NULL},
	{"sub",   R_TYPE, 0x33, 0x0, 0x20, 0, sub, NULL},
	{"xor",   R_TYPE, 0x33, 0x4, 0x00, 0, xor_op, NULL},
	{"or",    R_TYPE, 0x33, 0x6, 0x00, 0, or_op, NULL},
	{"and",   R_TYPE, 0x33, 0x7, 0x00, 0, and_op, NULL},
	{"sll",   R_TYPE, 0x33, 0x1, 0x00, 0, sll, NULL},
	{"srl",   R_TYPE, 0x33, 0x5, 0x00, 1, NULL, srl},
	{"sra",   R_TYPE, 0x33, 0x5, 0x20, 0, sra, NULL},
	{"slt",   R_TYPE, 0x33, 0x2, 0x00, 0, slt, NULL},
	{"sltu",  R_TYPE, 0x33, 0x3, 0x00, 1, NULL, sltu},

	{"addi",  I_TYPE, 0x13, 0x0, 0x00, 0, add, NULL},
	{"xori",  I_TYPE, 0x13, 0x4, 0x00, 0, xor_op, NULL},
	{"ori",   I_TYPE, 0x13, 0x6, 0x00, 0, or_op, NULL},
	{"andi",  I_TYPE, 0x13, 0x7, 0x00, 0, and_op, NULL},
	{"slli",  I_TYPE, 0x13, 0x1, 0x00, 0, sll, NULL},
	{"srli",  I_TYPE, 0x13, 0x5, 0x00, 1, NULL, srl},
	{"srai",  I_TYPE, 0x13, 0x5, 0x00, 0, sra, NULL},
	{"slti",  I_TYPE, 0x13, 0x2, 0x00, 0, slt, NULL},
	{"sltiu", I_TYPE, 0x13, 0x3, 0x00, 1, NULL, sltu},
	{"jalr",  I_TYPE, 0x67, 0x0, 0x00, 0, add, NULL},

	{"lb",    I_TYPE, 0x03, 0x0, 0x00, 1, NULL, addiu},
	{"lh",    I_TYPE, 0x03, 0x1, 0x00, 1, NULL, addiu},
	{"lw",    I_TYPE, 0x03, 0x2, 0x00, 1, NULL, addiu},
	{"lbu",   I_TYPE, 0x03, 0x4, 0x00, 1, NULL, addiu},
	{"lhu",   I_TYPE, 0x03, 0x5, 0x00, 1, NULL, addiu},

	{"sb",    S_TYPE, 0x23, 0x0, 0x00, 1, NULL, addiu},
	{"sh",    S_TYPE, 0x23, 0x1, 0x00, 1, NULL, addiu},
	{"sw",    S_TYPE, 0x23, 0x2, 0x00, 1, NULL, addiu},

	{"beq",   B_TYPE, 0x63, 0x0, 0x00, 0, beq, NULL}, //fja
	{"bne",   B_TYPE, 0x63, 0x1, 0x00, 0, bne, NULL}, //fja
	{"blt",   B_TYPE, 0x63, 0x4, 0x00, 0, blt, NULL}, //fja
	{"bge",   B_TYPE, 0x63, 0x5, 0x00, 0, bge, NULL}, //fja
	{"bltu",  B_TYPE, 0x63, 0x6, 0x00, 1, NULL, bltu}, //fja
	{"bgeu",  B_TYPE, 0x63, 0x7, 0x00, 1, NULL, bgeu}, //fja
													   //
	{"jal",   J_TYPE, 0x6F, 0x0, 0x00, 0, add, NULL}, //fja
	
	{"lui",   U_TYPE, 0x37, 0x4, 0x00, 0, utype_fun, NULL}, //fja
	{"auipc", U_TYPE, 0x17, 0x0, 0x00, 0, utype_fun, NULL}, //fja
};

/** Function that call process_line function on each line
 * of input .txt.
 */
void process_file(FILE *fptr);

/** Function that find type of instruction (R, I or S) and
 * converts it to machine code approprietely.
 */
void process_line(char line[256], FILE* fout, FILE* expected_out);

/** Returns register number from a string,
 * used in handle_x_type functions.
 */
uint8_t get_reg(char reg_word[40]);

/** Returns imm value from a string,
 * used in handle_x_type functions.
 */
int get_imm(char word[40]);

/** Returns imm value from a string,
 * used in handle_x_type functions of load/store
 * type.
 */
int get_imm_ls(char word[40]);

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
void handle_r_type(Instruction* instr, uint8_t regd, uint8_t reg1, uint8_t reg2, FILE* output, FILE* expected_out);

/** Handles I_TYPE instructions, fills uint32_t result and
 *  calls output_result function.
 */
void handle_i_type(Instruction* instr, uint8_t regd, uint8_t reg1, int imm, FILE* output, FILE* expected_out);

/** Handles S_TYPE instructions, fills uint32_t result and
 *  calls output_result function.
 */
void handle_s_type(Instruction* instr, uint8_t reg2, int imm, uint8_t reg1, FILE* output, FILE* expected_out);

/** Handles B_TYPE instructions, fills uint32_t result and
 *  calls output_result function.
 */
void handle_b_type(Instruction* instr, int imm, uint8_t reg1, uint8_t reg2, FILE* output, FILE* expected_out);

/** Handles J_TYPE instructions, fills uint32_t result and
 *  calls output_result function.
 */
void handle_j_type(Instruction* instr, uint8_t regd, int imm,  FILE* output, FILE* expected_out);

/** Handles U_TYPE instructions, fills uint32_t result and
 *  calls output_result function.
 */
void handle_u_type(Instruction* instr, uint8_t regd, int imm, FILE* output, FILE* expected_out);

/** Prints expected output
 */
void output_expected(Instruction *instr, uint8_t regd, uint8_t reg1, uint8_t reg2, int imm, FILE* expected_out);

/**
 * Converts value to string of value's bits
 * and fills with zeros to the bits(the second argument)
 */
void bits_to_str(unsigned int value, int bits, char *out);
