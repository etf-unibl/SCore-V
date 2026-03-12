#!/bin/sh

SCRIPT_DIR=$(dirname "$0")
cd "$SCRIPT_DIR/../software/"
make assembler
if [ $? -ne 0 ]; then
    echo "Make failed, falling back to old assembler executable"
else
    echo "Make successful"
fi
./obj/assembler ../hardware/init_files/input_program.txt
if [ $? -ne 0 ]; then
    echo "There were errors in syntax of assembler"
    exit 1
else
    echo "Assembler created output files successfuly"
fi
