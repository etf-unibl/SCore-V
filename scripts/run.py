#!/usr/bin/env python3
import os

from pathlib import Path
from vunit import VUnit

script_dir = Path(__file__).parent.resolve()

command = str(script_dir / "compile.sh")
os.system(command)

VU = VUnit.from_argv()
VU.add_vhdl_builtins()
VU.add_osvvm()
VU.add_verification_components()

HARDWARE_PATH = Path(__file__).parent / ".." / "hardware"
SRC_PATH      = HARDWARE_PATH / "design"
TESTS_PATH    = HARDWARE_PATH / "tests"
INIT_PATH     = HARDWARE_PATH / "init_files"

# Keep library references so we can call set_generic later
design_lib    = VU.add_library("design_lib")
design_lib.add_source_files(SRC_PATH / "*.vhd")

testbench_lib = VU.add_library("testbench_lib")
# testbench_lib.add_source_files(TESTS_PATH / "*.vhd")

for f in TESTS_PATH.glob("*.vhd"):
    if f.name != "score_v_signature_tb.vhd":
        testbench_lib.add_source_files(f)

# Resolve absolute paths — forward slashes required by GHDL on Windows
IMEM_FILE     = str((INIT_PATH / "instruction_memory.txt").resolve()).replace("\\", "/")
EXPECTED_FILE = str((INIT_PATH / "expected.txt").resolve()).replace("\\", "/")
DMEM_FILE = str((INIT_PATH / "data_memory.txt").resolve()).replace("\\", "/")

# fetch_instruction testbench
testbench_lib.test_bench("fetch_instruction_tb").set_generic("g_init_file", IMEM_FILE)

# load_store_unit testbench
testbench_lib.test_bench("load_store_unit_tb").set_generic("g_init_file", DMEM_FILE)

# score_v testbench — needs both IMEM and DMEM paths
score_v_tb = testbench_lib.test_bench("score_v_tb")
score_v_tb.set_generic("g_init_file",      IMEM_FILE)
score_v_tb.set_generic("g_dmem_init_file", DMEM_FILE)
score_v_tb.set_generic("g_expected_file",  EXPECTED_FILE)

VU.add_compile_option("ghdl.a_flags", ["--std=08", "-frelaxed-rules"])
VU.set_sim_option("ghdl.elab_e", True)

VU.main()
