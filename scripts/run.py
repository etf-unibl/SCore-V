#!/usr/bin/env python3

from pathlib import Path
from vunit import VUnit

VU = VUnit.from_argv()
VU.add_vhdl_builtins()
VU.add_osvvm()
VU.add_verification_components()

HARDWARE_PATH = Path(__file__).parent / ".." / "hardware"
SRC_PATH = HARDWARE_PATH / "design"
TESTS_PATH = HARDWARE_PATH / "tests"

VU.add_library("design_lib").add_source_files(SRC_PATH / "*.vhd")
VU.add_library("testbench_lib").add_source_files(TESTS_PATH / "*.vhd")

VU.main()
