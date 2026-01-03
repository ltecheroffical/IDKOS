#!/usr/bin/env python3

import os
import sys
import shutil
import pathlib
import subprocess

from contextlib import contextmanager

DEBUG = "DEBUG" in os.environ

SRC_DIR = "src"
BUILD_DIR = "build"

NASMFLAGS = ["-DDEBUG"] if DEBUG else [] 

MAIN_ASM_FILE = os.path.join(SRC_DIR, "stage2.asm")

OUTPUT_FILE = os.path.join(BUILD_DIR, "stage2.bin")

@contextmanager
def change_dir(destination):
    prev_dir = os.getcwd()
    os.chdir(destination)
    try:
        yield
    finally:
        os.chdir(prev_dir)

def build():
    with change_dir(os.path.dirname(__file__)):
        os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)

        print("NASM", MAIN_ASM_FILE)
        try:
            subprocess.run(["nasm", "-f", "bin", "-I", SRC_DIR, "-o", OUTPUT_FILE, *NASMFLAGS, MAIN_ASM_FILE], check=True)
        except subprocess.CalledProcessError as e:
            sys.exit(e.returncode)

def clean():
    shutil.rmtree(os.path.join(os.path.dirname(__file__), BUILD_DIR), ignore_errors=True)

if __name__ == "__main__":
    if len(sys.argv) > 1:
        if sys.argv[1].lower() == "clean":
            clean()
            exit(0)
    build()