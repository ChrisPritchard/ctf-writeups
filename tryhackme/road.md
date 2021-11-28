# Road

https://tryhackme.com/room/road

Quite a fun little room, with a few things that caught me up.

1. Enumeration reveals 22 and 80. On the latter is a website for 'Sky Couriers'
2. Suddomain and directory busting revealed little, but there was a login page that featured a register link
3. By registering an account, I could get access to the admin portal. In there was just two pieces of functionality: a change password link and a profile edit page.
4. The profile edit page featured a 'upload profile image' function, but it was only available to the admin@sky.thm account.
5. The reset password functionality, when tested, passed the email address of the target account as one of its params. Using this I was able to reset the admin password and get access.
6. The upload profile image functionality did not seem to have any restrictions, however there was no indication *where* the image was uploaded, as the image or whatever was not displayed.
7. Burp's target functionality actually showed me where, by picking up a url in a comment. This allowed me to find my webshell and gain RCE
8. On the box as www-data, I did some basic enumeration. /etc/passwd revealed there was a mongodb user; by running `mongo` I got access to the mongo database, and in one of the database collections was the password for the webdeveloper user.
9. With this password I could SSH in and read the user flag.
10. The webdeveloper user had sudo rights to run a backup program:

  ```
  Matching Defaults entries for webdeveloper on sky:
    env_reset, mail_badpass, secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin\:/snap/bin,
    env_keep+=LD_PRELOAD

  User webdeveloper may run the following commands on sky:
      (ALL : ALL) NOPASSWD: /usr/bin/sky_backup_utility
  ```

  I exfiltrated this and decompiled it to find it was running tar with a wildcard. I tried the [wild card exploit](https://www.hackingarticles.in/linux-privilege-escalation-using-ld_preload/), but this was unsuccessful.

11. However, I noted that the sudoers file contained `env_keep += LD_PRELOAD`. This meant that it would be [exploitable via LD_PRELOAD](https://www.hackingarticles.in/linux-privilege-escalation-using-ld_preload/).
12. I created a c script with the following contents

  ```
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

13. I then compiled this with `gcc -fPIC -shared -o shell.so shell.c -nostartfiles`
14. Finally I got a root shell and the root flag with `sudo LD_PRELOAD=/home/webdeveloper/shell.so /usr/bin/sky_backup_utility`
