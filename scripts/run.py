#!/usr/bin/env python3

from pathlib import Path
from vunit import VUnit

VU = VUnit.from_argv()
VU.add_vhdl_builtins()
VU.add_osvvm()
VU.add_verification_components()

HARDWARE_PATH = Path(__file__).parent / ".." / "hardware"
SRC_PATH      = HARDWARE_PATH / "design"
TESTS_PATH    = HARDWARE_PATH / "tests"
INIT_PATH     = HARDWARE_PATH / "init_files"

VU.add_library("design_lib").add_source_files(SRC_PATH / "*.vhd")
VU.add_library("testbench_lib").add_source_files(TESTS_PATH / "*.vhd")

# Resolve absolute path to instruction_memory.txt and normalise
# separators to forward slashes (required by GHDL on Windows).
IMEM_FILE = str((INIT_PATH / "instruction_memory.txt").resolve()).replace("\\", "/")

# Pass the path as a generic to the fetch_instruction testbench.
# The testbench forwards it to both the UUT and its local golden reference.
tb = VU.library("testbench_lib").test_bench("fetch_instruction_tb")
tb.set_generic("g_init_file", IMEM_FILE)

VU.main()