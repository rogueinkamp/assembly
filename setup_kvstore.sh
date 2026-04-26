#!/bin/bash

# Create clean workspace
mkdir -p /home/evanr/kvstore
cd /home/evanr/kvstore

# Copy all necessary files
cp /home/evanr/assembly/kvstore/server.asm .
cp /home/evanr/assembly/kvstore/get.asm .
cp /home/evanr/assembly/kvstore/shared.inc .
cp /home/evanr/assembly/kvstore/Makefile .
cp /home/evanr/assembly/kvstore/GUIDE.md .

# Simplify Makefile for new location
sed -i 's|kvstore/||g' Makefile
sed -i 's|-I.*|-I.|g' Makefile

# Update includes in assembly files
sed -i 's|kvstore/shared.inc|shared.inc|g' *.asm

# Initialize git
git init
git add .
git commit -m "Initial commit - clean kvstore workspace"

echo "Setup complete in /home/evanr/kvstore"
echo "Start new aider session there with:"
echo "cd /home/evanr/kvstore && aider"
