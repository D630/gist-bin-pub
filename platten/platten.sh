#!/usr/bin/env bash

# Show file system

echo
sudo lsblk -o NAME,FSTYPE,UUID,RO,RM,SIZE,STATE,OWNER,GROUP,MODE,TYPE,MOUNTPOINT,LABEL,MODEL
echo
df -ah
echo
