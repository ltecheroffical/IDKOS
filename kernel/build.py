#!/usr/bin/env python3

import os
import sys
import shlex
import subprocess
import itertools
import shutil

from contextlib import contextmanager
from pathlib import Path

DEBUG = "DEBUG" in os.environ

CC = os.environ.get("CC", "i686-elf-gcc")
AS = os.environ.get("AS", "i686-elf-as")
LD = os.environ.get("LD", "i686-elf-ld")
OBJCOPY = os.environ.get("OBJCOPY", "i686-elf-objcopy")

INCLUDE_DIR = "include"
SRC_DIR = "src"

LINKER_SCRIPT = "linker.ld"

CFLAGS = shlex.split(os.environ.get("CFLAGS", "")) + ["-g", "-O0", "-fno-omit-frame-pointer", "-funwind-tables"] if DEBUG else ["-O2"]
ASMFLAGS = shlex.split(os.environ.get("ASMFLAGS", ""))

BUILD_DIR = os.environ.get("BUILD_DIR", "build")

KERNEL_OUTPUT = os.path.join(BUILD_DIR, "kernel")
KERNEL_OUTPUT_BIN = KERNEL_OUTPUT + ".bin"
KERNEL_OUTPUT_ELF = KERNEL_OUTPUT + ".elf"

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
        src = Path(SRC_DIR)

        outputs = []

        for file in src.rglob("*.c"):
            output = Path(BUILD_DIR) / file.with_name(file.name + ".o")
            output.parent.mkdir(parents=True, exist_ok=True)

            print("CC", file)
            try:
                subprocess.run([CC, "-c", "-ffreestanding", "-I", INCLUDE_DIR, *CFLAGS, "-o", output, file], check=True)
            except subprocess.CalledProcessError as e:
                sys.exit(e.returncode)

            outputs.append(output)

        for file in itertools.chain(src.rglob("*.s"), src.rglob("*.S")):
            output = Path(BUILD_DIR) / file.with_name(file.name + ".o")
            output.parent.mkdir(parents=True, exist_ok=True)

            print("AS", file)
            try:
                subprocess.run([AS, "-o", output, *ASMFLAGS, file], check=True)
            except subprocess.CalledProcessError as e:
                sys.exit(e.returncode)

            outputs.append(output)

        print("LD", KERNEL_OUTPUT_ELF)
        try:
            subprocess.run([LD, "-T", LINKER_SCRIPT, "-I", INCLUDE_DIR, "-o", KERNEL_OUTPUT_ELF, *outputs], check=True)
        except subprocess.CalledProcessError as e:
            sys.exit(e.returncode)

        print("OBJCOPY", KERNEL_OUTPUT_BIN)
        try:
            subprocess.run([OBJCOPY, "--gap-fill=0x00", "-O", "binary", KERNEL_OUTPUT_ELF, KERNEL_OUTPUT_BIN])
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