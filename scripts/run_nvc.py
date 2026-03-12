#!/usr/bin/env python3
#
# Usage:
#   python3 run_nvc.py <program.txt> <dmem.txt> [vunit options]
#
# Arguments:
#   program.txt  - path to IMEM init file (one hex byte per line)
#   dmem.txt     - path to DMEM init file (one hex 32-bit word per line)
#
# Example:
#   python3 run_nvc.py ../hardware/init_files/instruction_memory.txt \
#                      ../hardware/init_files/data_memory.txt
#

import os
import sys
from pathlib import Path

if len(sys.argv) < 3:
    print("Usage: python3 run_nvc.py <program.txt> <dmem.txt> [vunit options]")
    sys.exit(1)

IMEM_FILE = str(Path(sys.argv[1]).resolve()).replace("\\", "/")
DMEM_FILE = str(Path(sys.argv[2]).resolve()).replace("\\", "/")

# Strip our two positional args before VUnit parses sys.argv
sys.argv = [sys.argv[0]] + sys.argv[3:]

os.environ["VUNIT_SIMULATOR"] = "nvc"

from vunit import VUnit

VU = VUnit.from_argv(vhdl_standard="2008")
VU.add_vhdl_builtins()
VU.add_osvvm()
VU.add_verification_components()

HARDWARE_PATH = Path(__file__).parent / ".." / "hardware"
SRC_PATH      = HARDWARE_PATH / "design"
TESTS_PATH    = HARDWARE_PATH / "tests"

design_lib = VU.add_library("design_lib")
design_lib.add_source_files(SRC_PATH / "*.vhd")

# Only score_v_signature_tb — not *.vhd — to avoid conflicts with
# score_v_tb and other testbenches that expect different generics
testbench_lib = VU.add_library("testbench_lib")
testbench_lib.add_source_files(TESTS_PATH / "score_v_signature_tb.vhd")

score_v_sig_tb = testbench_lib.test_bench("score_v_signature_tb")
score_v_sig_tb.set_generic("g_init_file",      IMEM_FILE)
score_v_sig_tb.set_generic("g_dmem_init_file", DMEM_FILE)

VU.main()
