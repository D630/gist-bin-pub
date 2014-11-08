#!/bin/sh

# dudel - disk usage of unlinked, but still open files
# http://chneukirchen.org/dotfiles/bin/dudel

find -L /proc/*/fd -maxdepth 1 -type f -links 0 -printf '%b %p\n' 2>/dev/null |
while read size fd; do
  pid=${fd#/proc/}
  pid=${pid%/fd/*}
  prog=$(readlink /proc/$pid/exe)
  prog=${prog##*/}
  printf "%-10d %-10s %-20s %s\n" $size "$prog" $fd "$(readlink $fd)"
done
