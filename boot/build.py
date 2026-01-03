#!/usr/bin/env python3

import os
import sys
import math
import shutil
import pathlib
import subprocess

from contextlib import contextmanager

SRC_TREE_DIR = os.path.dirname(__file__)

sys.path.append(SRC_TREE_DIR)

import stage1.build as stage1
import stage2.build as stage2

BUILD_DIR = "build"

OUTPUT_FILE = os.path.join(BUILD_DIR, "disk.img")

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
        stage1.build()
        stage2.build()

        stage1_size = os.path.getsize(os.path.join(os.path.dirname(stage1.__file__), stage1.OUTPUT_FILE))
        stage2_size = os.path.getsize(os.path.join(os.path.dirname(stage2.__file__), stage2.OUTPUT_FILE))

        DISK_IMAGE_ROUND_UP_SIZE = 1024
        DISK_IMAGE_MINIMUM_EXTRA_SPACE = 512
        disk_image_total_needed = stage1_size + stage2_size + DISK_IMAGE_MINIMUM_EXTRA_SPACE
        disk_image_size = DISK_IMAGE_ROUND_UP_SIZE * ((disk_image_total_needed + 1023) // 1024)

        os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)

        with open(OUTPUT_FILE, "wb") as f:
            with open(os.path.join(os.path.dirname(stage1.__file__), stage1.OUTPUT_FILE), "rb") as bs:
                f.write(bs.read())
            f.truncate(disk_image_size)

        fdisk_script = f"""
        n
        p
        1

        +{(stage2_size + 511) // 512}
        t

        da
        w
        """.encode('utf-8')

        subprocess.run(["fdisk", OUTPUT_FILE], input=fdisk_script, stdout=subprocess.PIPE, check=True)
        fdisk_list = subprocess.run(["fdisk", "-l", OUTPUT_FILE], stdout=subprocess.PIPE, check=True)

        sector_offset = None
        for line in fdisk_list.stdout.splitlines():
            if f"{OUTPUT_FILE}1" in str(line):
                parts = line.split()
                if len(parts) > 1:
                    sector_offset = int(parts[1])
                    break

        assert(sector_offset is not None)

        byte_offset = sector_offset * 512

        with open(OUTPUT_FILE, "r+b") as f:
            f.seek(byte_offset)
            with open(os.path.join(os.path.dirname(stage2.__file__), stage2.OUTPUT_FILE), "rb") as s2:
                f.write(s2.read())

def clean():
    stage1.clean()
    stage2.clean()
    shutil.rmtree(os.path.join(os.path.dirname(__file__), BUILD_DIR), ignore_errors=True)

if __name__ == "__main__":
    if len(sys.argv) > 1:
        if sys.argv[1].lower() == "clean":
            clean()
            exit(0)
    build()