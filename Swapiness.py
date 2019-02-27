#!/usr/bin/env python
# encoding: utf-8
# Izoox SwapScript
# David Scalf
# 2019
#
# Script for the removal of swap files and partitions and the calculation and creation of a swap file.

# Imports
import os
import psutil
import shlex


# Start of the Swappiness
def start():
    os.system('sudo cp -f /etc/fstab /etc/fstab.old')
    if_swap()

# Calc the new swap file
def calc_swap():
    mem = psutil.virtual_memory().total
    if mem < 1000000000:
        swap = 1024
    elif mem > 1000000000 and mem < 2000000000:
        swap = 2048
    elif mem > 2000000000 and mem < 4000000000:
        swap = 3072
    elif mem > 4000000000 and mem < 9000000000:
        swap = 4096
    elif mem > 9000000000 and mem < 20000000000:
        swap = 8192
    else:
        swap = 16384
    create_swap(swap)

# Create the new swap File
def create_swap(size):
    os.system('sudo dd if=/dev/zero of=swapfile bs=1M count=' + str(size))
    os.system('sudo chmod 600 swapfile')
    os.system('sudo mkswap swapfile')
    os.system('sudo swapon swapfile')
    os.system('sudo echo "/root/swapfile swap swap defaults 0 0" >> /etc/fstab')

# Is swap setup already
def if_swap():
    swap_list = [line.rstrip('\n') for line in open('/proc/swaps')]
    if swap_list[1] is not None:
        os.system('swapoff -a')
        # Remove old Swap
        for counter, value in enumerate(swap_list[1:]):
            path = shlex.split(value)
            if path[1] == 'file':
                os.system('sudo rm -fr ' + path[0])
                os.system("sudo sed '\|" + path[
                    0] + "|d' /etc/fstab > /etc/fstab.tmp && sudo mv -f /etc/fstab.tmp /etc/fstab")
            elif path[1] == 'partition':
                part = path[0]
                part = part[5:]
                id = part[:2]
                if id == 'dm':
                    os.system('ls -l /dev/mapper | grep ' + part + ' >> part_' + part + '.txt')
                    tmp = shlex.split(open('part_' + part + '.txt'))
                    os.system("sudo sed '\|" + tmp[8] + "|d' /etc/fstab > /etc/fstab.tmp && sudo mv -f /etc/fstab.tmp /etc/fstab")
                    os.system('sudo rm -fr part_' + part + '.txt')

                else:
                    os.system("sudo sed '\|" + path[0] + "|d' /etc/fstab > /etc/fstab.tmp && sudo mv -f /etc/fstab.tmp /etc/fstab")
    calc_swap()


start()
