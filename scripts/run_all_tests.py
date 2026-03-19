#!/usr/bin/env python3
#
# Usage:
#    python3 run_all_tests.py <conformance_root_dir>
#
# Arguments:
#    conformance_root_dir - Path to the directory containing test subfolders.
#                           Each subfolder must contain:
#                           - program.txt (IMEM init)
#                           - dmem.txt (DMEM init)
#                           - sig_values.txt (Signature bounds)
#
# Description:
#    This script iterates through all subdirectories of the provided root,
#    detects the required initialization files, and automatically executes
#    the 'run_nvc.py' script for each test case.
#
# Example:
#    python3 run_all_tests.py /mnt/d/pds/project/conformance/
#
import subprocess
import sys
from pathlib import Path

if len(sys.argv) < 2:
    sys.exit(1)

ROOT_DIR = Path(sys.argv[1]).resolve()

for test_dir in ROOT_DIR.iterdir():
    if test_dir.is_dir():
        program = test_dir / "program.txt"
        dmem = test_dir / "dmem.txt"
        sig_val = test_dir / "sig_values.txt"
        sig_out = test_dir / "out.signature"

        if program.exists() and dmem.exists() and sig_val.exists():
            print(f"Running: {test_dir.name}")
            subprocess.run([
                "python3", "run_nvc.py",
                str(program), str(dmem), str(sig_val), str(sig_out)
            ])
        else:
            missing = []
            if not program.exists(): missing.append("program.txt")
            if not dmem.exists():    missing.append("dmem.txt")
            if not sig_val.exists(): missing.append("sig_values.txt")
            
            print(f"Skipping {test_dir.name} - Missing: {', '.join(missing)}")