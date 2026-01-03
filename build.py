#!/usr/bin/env python3

import os
import sys
import shutil
import subprocess

import boot.build as boot
import kernel.build as kernel

DISK_IMAGE_SIZE_BYTES = 1024 * 1024 * 4

BUILD_DIR = "build"

OUTPUT_FILE = os.path.join(BUILD_DIR, "disk.img")
ROOT_OUTPUT_FILE = os.path.join(BUILD_DIR, "root.img")

FDISK_SCRIPT = f"""
n
p
2


t

06
w
""".encode('utf-8')

def build():
    print("Boot:")
    boot.build()
    print("Kernel:")
    kernel.build()

    os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)

    with open(OUTPUT_FILE, "wb") as f:
        with open(os.path.join(os.path.dirname(boot.__file__), boot.OUTPUT_FILE), "rb") as bs:
            f.write(bs.read())
        f.truncate(DISK_IMAGE_SIZE_BYTES)

    subprocess.run(["fdisk", OUTPUT_FILE], input=FDISK_SCRIPT, stdout=subprocess.PIPE, check=True)
    fdisk_list = subprocess.run(["fdisk", "-l", OUTPUT_FILE], stdout=subprocess.PIPE, check=True)

    root_sector_offset = None
    root_sector_count = None
    for line in fdisk_list.stdout.splitlines():
        if f"{OUTPUT_FILE}2" in str(line):
            parts = line.split()
            if len(parts) > 1:
                root_sector_offset = int(parts[1])
                root_sector_count = int(parts[3])
                break

    assert(root_sector_offset is not None)
    assert(root_sector_count is not None)

    root_byte_offset = root_sector_offset * 512
    root_size = root_sector_count * 512

    with open(ROOT_OUTPUT_FILE, "wb") as f:
        f.truncate(root_size)

    subprocess.run(["mkfs.fat", "-F16", "-s", "1", "-n", "ROOT", "-v", ROOT_OUTPUT_FILE], check=True)
    subprocess.run(["mcopy", "-i", ROOT_OUTPUT_FILE, os.path.join(os.path.dirname(kernel.__file__), kernel.KERNEL_OUTPUT_BIN), "::/"], check=True)

    with open(OUTPUT_FILE, "r+b") as f:
        f.seek(root_byte_offset)
        with open(ROOT_OUTPUT_FILE, "rb") as r:
            f.write(r.read())

def clean():
    kernel.clean()
    boot.clean()
    shutil.rmtree(os.path.join(os.path.dirname(__file__), BUILD_DIR), ignore_errors=True)

if __name__ == "__main__":
    if len(sys.argv) > 1:
        if sys.argv[1].lower() == "clean":
            clean()
            exit(0)
    build()