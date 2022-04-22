# Overpass 3 - Hosting

https://tryhackme.com/room/overpass3hosting

Actually a pretty easy room, apart from the final privesc which had a twist I hadn't seen before.

1. Enum revealed 21, 22 and 80. 21 was NOT anonymous, so was left with 80 for enum
2. dirb on 80 revealed a /backups/ folder containing backup.zip
3. within was a xlsx (excel spreadsheet) encrypted with gpg and a gpg key. `gpg --import <key>` then `gpg --decrypt <file>` got a raw excel file
4. the excel file contained three usernames - none worked on ssh, but the paradox user for worked for ftp
5. the ftp folder was obviously the web directory for 80. i uploaded a web shell and confirmed i could reach it, as user www-data
6. various reverse shell methods failed, so i ended up using the php-reverse-shell.php by pentest monkey (its on the attack box by thm under /usr/share/webshells/php)    
7. on teh machine, the users were paradox and james. su paradox with the same password from ftp allowed me to switch to paradox
8. i added my pub key to paradoxes authorised keys to make for easy ssh and tested

All of the above took about ten minutes, just following the trail of breadcrumbs (okay maybe a little longer than ten minutes, but it wasn't *hard* is what I'm saying. The next bit took a lot longer, due to the twist.

9. running linpeas showed an exported nfs dir with no root squash. This vuln is detailed here: https://book.hacktricks.xyz/linux-unix/privilege-escalation/nfs-no_root_squash-misconfiguration-pe

    Specifically, `cat /etc/exports` showed:

      `/home/james *(rw,fsid=0,sync,no_root_squash,insecure)`

10. I established a tunnel from my attack machine via `ssh -fNv -L 3049:localhost:2049 paradox@10.10.97.35`
11. i created a mount dir via `mkdir /tmp/pe`

At this point things stopped working: the next step would be `mount -t nfs -o port=3049 localhost:/home/james /tmp/pe` however this didn't work. I tried all sort of commands and the like, but it would not mount.

The trick, ultimately was in the exports above. For NFSv4, the option `fsid=0` means that the mount is exposed as a root mount. That is, you are not mount `/home/james`, you are mounting `/`!

12. so the command was `mount -t nfs -o port=3049 localhost:/ /tmp/pe`
13. this gave access to the user dir of james, but also the ability to drop a suid binary in there. i copied `sh` into the folder and set the suid bit
14. inside jame's folder was also a .ssh directory with a private key. grabbing this I was able to log in as james and use the suid binary to get root.

Overall an easy room as I said, but fun.
