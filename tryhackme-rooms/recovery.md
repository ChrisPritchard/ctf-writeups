# Recovery

https://tryhackme.com/room/recovery

A room I had a lot of fun with, surprisingly. Sort of a boot2root combine with forensics, though a bit jokey :) Premise is that the server has been defaced and compromised, and you need to log in and repair everything. You are provided with an initial set of ssh credentials, alex:madeline, and a port where you can get up to six flags as you fix things.

## Flag 0

1. a port scan revealed 80 and 22, 80 showing a garbelled site. 
2. ssh'ing with the creds would fill the screen with "YOU DIDN'T SAY THE MAGIC WORD" as described in the scenario
3. using scp I grabbed the users dotfiles, and inspected .bashrc to see the evil script at the end. removing this, I scp'd it back, and then ssh'd in successfully.

This revealed flag 0 on port 1337's webpage

## Flag 1

One thing quickly obvious was that after a minute the logged in user would be logged out, which was annoying. So all actions had to be done quick or over multiple logins.

1. in the home dir was the 'fixutil' binary that compromised the machine. I copied this back to my machine and decompiled it with Ghidra
2. apart from adding the evil script to .bashrc, it also replaced the content of a dll called liblogging.so at /lib/x86_64-linux-gnu/liblogging.so
3. finally it ran /bin/admin, before exiting. going back to machine I ran ldd on /bin/admin to see it invoked that dll, and checked that the dll was writable.
4. copying both back to my machine for analysis, i found /bin/admin was a suid binary, and would invoke a LogIncorrectAttempt function in liblogging
5. in the compromised liblogging.so, this would do a number of things as root: add an authorized key to roots authorized keys, add a new root user, encrypt all the web site files, and create a /etc/cron.d/evil job that would invoke /opt/brilliant_script.sh which logged the user out.
6. the cron file and other tasks were owned by root, so to get root I did the following:

    a. created a c file with the following content (on my host machine):

      ```c
      #include <stdlib.h>

      void LogIncorrectAttempt(char *attempt)
      {
        system("cp /bin/sh /home/alex/esh && chmod u+s /home/alex/esh");
      }
      ```
        
    b. compiled this with `gcc -Wall -fPIC -shared -o liblogging.so suid.c`
    
    c. copied this over the compromised liblogging.so file on the server
    
    d. ran /bin/admin myself (you had to enter a bad password when prompted)
    
    e. used the newly created `esh` sh suid binary to elevate to root
    
10. deleting the brilliant_script.sh stopped the logouts

This unlocked flag 1

## Flag 2

To get flag 2, I had to restore liblogging. The fixutil assembly backed it up to /tmp, and then the root run liblogging.so copied the temp copy to the lib folder as oldliblogging.so

Simply renaming the old file to the proper new file unlocked Flag 2

## Flag 3

Flag 3 required removing the entry in authorized keys. I actually replaced it instead, with my own pub key, which made bouncing on and off the server as root easier. This unlocked the flag regardless

## Flag 4

The security user couldn't be deleted with userdel (at least not to my knowledge), as it had been given id and group id 0, making it basically a synonym for root. However, as root, I could remove the lines for security manually from passwd and shadow. This unlocked flag 4.

## Flag 5

1. examining the encryption code, I found the web files were at `/usr/local/apache2/htdocs/`. Additionally, the encryption keys were stored at /opt/.fixutil/backup.txt
2. examining the enncryption process, it was a simple XOR with the key.
3. copying the web files locally, I used cyberchef to decrypt them one by one with the key. NOTE: initially I had run fixutil on first load, which repeated the encryption and created two keys in backup.txt. If a reader is in this situation, know that you will need to XOR twice, in reverse order of the keys.
4. with the fixed web files, I scp'd them back onto the server

This unlocked the final flag, flag 5.
