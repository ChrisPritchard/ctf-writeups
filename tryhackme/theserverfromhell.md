# The Server From Hell

https://tryhackme.com/room/theserverfromhell

This room was a lot of work, but also a lot of fun!

The hints were security, firewall, nfs and shell escape. Firewall became immediately obvious when I ran a rustscan, which identified thousands upon thousands of ports. I gave up doing a version scan, and instead moved on to the first step: the room said, start with 1337.

1. connecting to 1337 with netcat revealed a short message, that said `grab the banners of the first 100 ports and look for the troll` or something to that effect
2. to do this, i used the nmap banner script: `nmap -p 1-100 --script banner <ip> > banners.txt`. I then used `grep banner: banners.txt` to just get the troll face, which had in the middle the next port to talk to.
3. on that next port was a note about the firewall, and said I should investigate nfs on its regular port (e.g. 111, 2049)
4. to investigate nfs I used `nmap -p 111 -sV --script nfs-ls <ip>`, which revealed `/home/nfs`could be mounted.
5. to mount this I created a `nfs` folder on my attack machine then mounted the remote nfs folder using `mount -t nfs <ip>:/home/nfs nfs -o nolock`
6. inside the new folder was a backup.zip file. this was password protected, so I used `/opt/john/zip2john backup.zip > backup.john` get the hash, then `john --wordlist=rockyou.txt backup.john` to get the password
7. once extracted, i got a /home/hades folder and a .ssh directory. in the ssh directory was the first flag
8. the .ssh dir also contained the private key of the hades user, but the 22 port wasn't responding on the server. there was a hint file that contained `2500-4500`, obviously a port range.
9. there were a few ways i could proceed: scanning those ports with `nmap -sV` was an option, or just grabbing their banners via `--script banner`. I tried the latter but the banners were a bit garbage (likely intentional). Instead I tried a slower method: `for i in {2500..4500}; do echo $i; ssh -i id_rsa hades@<ip> -p $i; done`, which slowly tried port after port until the right one was found (only took a few minutes).
10. on the machine, it looked like I was in a ruby interactive session. to escape this I used `exec('/bin/bash')`
11. once escaped I got the user flag.
12. the final escalation to root was via capabilities: the hint was `getcap`. `getcap -r / 2>/dev/null` revealed `/bin/tar = cap_dac_read_search+ep`, meaning tar can read as root.
13. using this, I could skip to read the root flag via `/bin/tar xf "/root/root.txt" -I '/bin/sh -c "cat 1>&2"'`
14. A more satisfying path was to use the above to read `/etc/shadow`, which contained the root password hash, which I then cracked with `john --format=sha512crypt hash --wordlist=rockyou.txt` (just copying the shadow file line, username and all, into hash was sufficient) which cracked the password almost immediately.

With the root password, and the port for ssh from before, I could ssh in as root :) Fun room!
