#!/bin/bash
#
#Izoox.com
#David Scalf 
#Swap Script
#Used for setting swap size on servers.
#
#

#!/bin/sh

# Do argument checks
if [ ! "$#" -ge 1 ]; then
    echo "Usage: $0 {size}"
    echo "Example: $0 4G"
    echo "(Default path: /swapfile)"
    echo "Optional path: Usage: $0 {size} {path}"
    exit 1
fi


## Intro
echo "Welcome to Swap setup script! This script will automatically setup a swap file and enable it."
echo "Root access is required, please run as root or enter sudo password." 
echo "Source is @ https://github.com/Cretezy/Swap with modifications be David Scalf of Izoox, llc."

## Setup variables

# Get size from first argument
SWAP_SIZE=1048576
if [ ! -z "$1" ]; then
    SWAP_SIZE=$1
else
    BUFFER=$(awk '( $1 == "Mem:" ) { print $6 }' < free)
    FREE=$BUFFER*.75
    RESERVED = 
# Get path from second argument (default to /swapfile)
SWAP_PATH="/swapfile"
if [ ! -z "$2" ]; then
    SWAP_PATH=$2
fi

## Run
swapoff -a # Disable swap
rm -f /swapfile
dd if=/dev/zero of=$SWAP_PATH bs=1048576 count=$SWAP_SIZE # Allocate size
chmod 600 $SWAP_PATH                # Set proper permission
mkswap $SWAP_PATH                   # Setusp swap
swapon $SWAP_PATH                   # Enable swap
echo "$SWAP_PATH   none    swap    sw    0   0" | sudo tee /etc/fstab -a # Add to fstab

## Outro

echo "Done! You now have a $SWAP_SIZE swap file at $SWAP_PATH"
