# Vulnnet

https://tryhackme.com/room/vulnnet1

A fairly basic room, though I struggled with the initial foothold. To get there, I ultimately required some help, so the first part of this can be attributed to me looking up the old walkthroughs for this rooms prior incarnation on other platforms.

1. enum revealed 22 and 80. the room spec also specified that 'vulnnet.thm' should be added as a hosts entry, which is generally a sign of subdomain enumeration
2. in the source for the javascript files on 80, and confirmed with ffuf, I found the other domain, [redacted].vulnnet.thm, but this was protected by basic auth.
3. poking around the website on vulnnet.thm, nothing seemed to stand it. it had two forms, neither of which did anything - the best i could see was '?referer=', but messing around with that in burp revealed nothing

the first of two hints i sourced was here: referer is actually a lfi inclusion vuln. its not really obvious, so i didn't feel bad about getting help here. via base 64 php filter, i could see the content of index.php which revealed it was a basic include with some minor protections: ../ was replaced with '', which meant I could use `..././` to back pack if i wanted to. the second hint i needed was possibly premature - i should have done more research: knowing that 'broadcast' was protected by basic auth, i needed to get the content of an .htpasswd file, specifically a generic htpasswd file here: `php://filter/convert.base64-encode/resource=/etc/apache2/.htpasswd`

4. with the contents of htpasswd, I took the hash and broke it using hashcat: `hashcat -m 1600 hash rockyou.txt`. this got me the username and password for 'broadcast'
5. on the broadcast site was a product called 'ClipBucket'. I did some research and found multiple vulnerabilities: https://www.exploit-db.com/exploits/44250
6. using the unauthenticated photo upload vuln, I uploaded a php web shell, which was accessible under `files/photos`. the user was www-data

at this point, the second part of the room began, moving from www-data to a user and then to root. this part was fairly easy.

7. initial enumeration through the webshell revealed that there was a cronjob run by root, kicking off a script that backed up files for the user 'server-management' to /var/backups
8. looking inside backups i found a `ssh-backup.tar.gz`. extracting this (still through the webshell) got me a id_rsa file, with a key
9. I extracted this to my host machine, then cracked it via `ssh2john` and `john --wordlist=rockyou.txt ssh.hash`. now i could ssh in as 'server-management' and got the first flag.
10. going back to the backup script, the backup process vas via `tar cvf <filename> *`, somewhat obfuscated with the * being hidden under a variable. this is a classic tar wildcard exploit

the backup worked from the Documents folder of the user I had ssh'ed in. Going there, I created a shell.sh file, then two checkpoint files via:

```
echo "" > "--checkpoint-action=exec=sh shell.sh"
echo "" > --checkpoint=1
```

then I waited. the content of shell.sh was `cp /bin/bash . && chmod u+s bash`, which created a suid bash locally. Once created, using `./bash -p` got me a root shell and the final flag :D
