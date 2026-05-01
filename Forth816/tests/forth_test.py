#!/usr/bin/env python3
"""
forth_test.py - Forth regression test runner for 65816 Forth816
Sends .fs test files to a serial port, captures output, compares to masters.

Usage:
    python forth_test.py <port> <test_dir> [options]

Options:
    --baud BAUD         Baud rate (default: 9600)
    --delay MS          Delay between characters in milliseconds (default: 10)
    --timeout SEC       Seconds to wait for ###DONE### sentinel (default: 30)
    --preamble FILE     Preamble file name in test_dir (default: preamble.fs)
    --no-preamble       Skip preamble for all tests
    --master DIR        Directory containing master output files (default: test_dir/masters)
    --output DIR        Directory to write captured output (default: test_dir/output)
    --report FILE       Report file path (default: test_dir/report.txt)
    --generate-masters  Copy captured output to masters directory as .expected files
"""

import argparse
import difflib
import os
import glob
import shutil
import sys
import time
import serial


SENTINEL = "###DONE###"
FAIL_MARKERS = ("INCORRECT RESULT:", "WRONG NUMBER OF RESULTS:")


def parse_args():
    parser = argparse.ArgumentParser(description="Forth816 regression test runner")
    parser.add_argument("port", help="Serial port (e.g. COM3)")
    parser.add_argument("test_dir", help="Directory containing .fs test files")
    parser.add_argument("--baud", type=int, default=9600,
                        help="Baud rate (default: 9600)")
    parser.add_argument("--delay", type=float, default=10.0,
                        help="Delay between characters in milliseconds (default: 10)")
    parser.add_argument("--timeout", type=int, default=30,
                        help="Seconds to wait for ###DONE### sentinel (default: 30)")
    parser.add_argument("--preamble", default="preamble.fs",
                        help="Preamble filename in test_dir (default: preamble.fs)")
    parser.add_argument("--no-preamble", action="store_true",
                        help="Skip preamble for all tests")
    parser.add_argument("--master",
                        help="Directory containing master output files "
                             "(default: test_dir/masters)")
    parser.add_argument("--output",
                        help="Directory to write captured output files "
                             "(default: test_dir/output)")
    parser.add_argument("--report",
                        help="Report file path (default: test_dir/report.txt)")
    parser.add_argument("--generate-masters", action="store_true",
                        help="Copy captured output to masters directory as "
                             ".expected files. Existing masters are overwritten.")
    return parser.parse_args()


def find_test_files(test_dir, preamble_name):
    """Find all .fs files except the preamble, sorted alphabetically."""
    pattern = os.path.join(test_dir, "*.fs")
    files = sorted(glob.glob(pattern))
    files = [f for f in files if os.path.basename(f) != preamble_name]
    if not files:
        print(f"No .fs test files found in {test_dir}")
        sys.exit(1)
    return files


def send_file(ser, path, char_delay_sec):
    """Send file contents to serial port with per-character delay."""
    with open(path, "r") as f:
        contents = f.read()
    for ch in contents:
        ser.write(ch.encode("ascii"))
        time.sleep(char_delay_sec)


def run_test_file(ser, preamble_path, test_path, char_delay_sec, skip_preamble):
    """Send preamble (unless skipped) then test file to serial port."""
    if not skip_preamble:
        send_file(ser, preamble_path, char_delay_sec)
    send_file(ser, test_path, char_delay_sec)


def capture_output(ser, timeout_sec):
    """Read from serial port until sentinel or timeout.
    Returns (captured_string, sentinel_found)."""
    captured = []
    deadline = time.time() + timeout_sec
    current_line = []

    while time.time() < deadline:
        if ser.in_waiting:
            ch = ser.read(1).decode("ascii", errors="replace")
            if ch == "\n":
                line = "".join(current_line).rstrip("\r")
                captured.append(line)
                if SENTINEL in line:
                    return "\n".join(captured), True
                current_line = []
            else:
                current_line.append(ch)
        else:
            time.sleep(0.001)

    # Timeout: flush any partial line
    if current_line:
        captured.append("".join(current_line).rstrip("\r"))
    return "\n".join(captured), False


def load_master(master_dir, test_name):
    """Load master output file. Returns string or None if not found."""
    master_path = os.path.join(master_dir, test_name + ".expected")
    if not os.path.exists(master_path):
        return None
    with open(master_path, "r") as f:
        return f.read()


def save_output(output_dir, test_name, captured):
    """Save captured output to file. Returns path written."""
    os.makedirs(output_dir, exist_ok=True)
    out_path = os.path.join(output_dir, test_name + ".actual")
    with open(out_path, "w") as f:
        f.write(captured)
    return out_path


def generate_master(master_dir, test_name, actual_path):
    """Copy .actual file to masters directory as .expected file."""
    os.makedirs(master_dir, exist_ok=True)
    master_path = os.path.join(master_dir, test_name + ".expected")
    shutil.copy2(actual_path, master_path)
    return master_path


def check_failures(captured):
    """Return list of failing lines from captured output."""
    failing = []
    for line in captured.splitlines():
        if any(marker in line for marker in FAIL_MARKERS):
            failing.append(line)
    return failing


def run_tests(args):
    test_dir = os.path.abspath(args.test_dir)
    master_dir = args.master or os.path.join(test_dir, "masters")
    output_dir = args.output or os.path.join(test_dir, "output")
    report_path = args.report or os.path.join(test_dir, "report.txt")
    char_delay_sec = args.delay / 1000.0
    skip_preamble = args.no_preamble
    gen_masters = args.generate_masters

    preamble_path = os.path.join(test_dir, args.preamble)
    if not skip_preamble and not os.path.exists(preamble_path):
        print(f"Preamble file not found: {preamble_path}")
        print("Use --no-preamble to skip it.")
        sys.exit(1)

    test_files = find_test_files(test_dir, args.preamble)
    print(f"Found {len(test_files)} test file(s) in {test_dir}")
    print(f"Port:             {args.port}")
    print(f"Baud:             {args.baud}")
    print(f"Char delay:       {args.delay}ms")
    print(f"Preamble:         {'skipped' if skip_preamble else preamble_path}")
    print(f"Generate masters: {'yes' if gen_masters else 'no'}")
    print()

    if gen_masters:
        print("*** GENERATE MASTERS MODE: existing .expected files will be "
              "overwritten ***")
        print()

    results = []  # list of (test_name, status, details)

    ser = serial.Serial(args.port, baudrate=args.baud, timeout=1)
    try:
        for test_path in test_files:
            test_name = os.path.splitext(os.path.basename(test_path))[0]
            print(f"Running {test_name}.fs ... ", end="", flush=True)

            # Send preamble and test file
            run_test_file(ser, preamble_path, test_path,
                          char_delay_sec, skip_preamble)

            # Capture output until sentinel or timeout
            captured, sentinel_found = capture_output(ser, args.timeout)

            # Save captured output for inspection
            actual_path = save_output(output_dir, test_name, captured)

            if not sentinel_found:
                print("TIMEOUT")
                results.append((test_name, "TIMEOUT",
                                 ["No ###DONE### sentinel received"]))
                continue

            # Generate masters if requested — skip comparison for this run
            if gen_masters:
                master_path = generate_master(master_dir, test_name, actual_path)
                print(f"MASTER -> {master_path}")
                results.append((test_name, "MASTER", []))
                continue

            # Check for ttester failures in captured output
            failing_lines = check_failures(captured)

            # Compare against master if one exists
            master = load_master(master_dir, test_name)
            diff_lines = []
            if master is not None:
                diff = list(difflib.unified_diff(
                    master.splitlines(),
                    captured.splitlines(),
                    fromfile=test_name + ".expected",
                    tofile=test_name + ".actual",
                    lineterm=""
                ))
                diff_lines = diff

            if not failing_lines and not diff_lines:
                print("PASS")
                results.append((test_name, "PASS", []))
            else:
                print("FAIL")
                details = []
                if failing_lines:
                    details.extend(failing_lines)
                if diff_lines:
                    details.extend(diff_lines)
                results.append((test_name, "FAIL", details))

    finally:
        ser.close()

    # Write report
    passed   = sum(1 for _, s, _ in results if s == "PASS")
    failed   = sum(1 for _, s, _ in results if s == "FAIL")
    timedout = sum(1 for _, s, _ in results if s == "TIMEOUT")
    mastered = sum(1 for _, s, _ in results if s == "MASTER")

    os.makedirs(os.path.dirname(os.path.abspath(report_path)), exist_ok=True)
    with open(report_path, "w") as f:
        f.write("Forth816 Regression Test Report\n")
        f.write("=" * 40 + "\n")
        f.write(f"Tests run:       {len(results)}\n")
        if gen_masters:
            f.write(f"Masters written: {mastered}\n")
        else:
            f.write(f"Passed:          {passed}\n")
            f.write(f"Failed:          {failed}\n")
            f.write(f"Timed out:       {timedout}\n")
        f.write("=" * 40 + "\n\n")

        for test_name, status, details in results:
            f.write(f"{test_name}: {status}\n")
            for line in details:
                f.write(f"    {line}\n")
            if details:
                f.write("\n")

    # Print summary to console
    print()
    print("=" * 40)
    if gen_masters:
        print(f"Masters written: {mastered}")
    else:
        print(f"Passed: {passed}  Failed: {failed}  Timed out: {timedout}")
    print(f"Report written to {report_path}")


if __name__ == "__main__":
    args = parse_args()
    run_tests(args)
