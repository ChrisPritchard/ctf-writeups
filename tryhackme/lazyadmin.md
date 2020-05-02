# Lazy Admin

This one took longer than it should have, because later in the piece I was dumb and didn't immediately run `sudo -l`. ALWAYS RUN `sudo -l`!!!

1. Recon showed port 22 and port 80
2. A dirb on port 80 revealed /content, which when browsed to revealed a CMS called sweetrice
3. On exploit db for sweetrice, there is a backups disclosure cve: https://www.exploit-db.com/exploits/40718
4. Inside the backup sql file, I found the username `manager` with hash `42f749ade7f9e195bf475f37a44cafcb`
5. A reverse lookup via https://md5hashing.net/ revealed the password as `Password123`
6. Logging into SweetRice, the media centre allows arbitrary uploads. I zipped up p0wnyShell and uploaded it with 'extract zip' set. This gave me a www-data web shell
7. The user flag in `/home/itguy/user.txt` was `THM{63e5bce9271952aad1113b6f1ac28a07}`
8. Enumeration at this point revealed a file called `backup.pl` in `itguy`s home directory. Backup called `/etc/copy.sh` which contained the text of a bash reverse shell. `copy.sh` was writeable, so I updated it with the same shell script but one which pointed to my attacker machine. Tested by running backup.pl and getting a reverse shell as www-data.

At this point I was dumb, and got stuck for a bit. I eventually ran `linpeas.sh` which told me what I should have found out myself immediately: `sudo -l` reveals:

```
Matching Defaults entries for www-data on THM-Chal:
    env_reset, mail_badpass,                       
    secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin\:/snap/bin

User www-data may run the following commands on THM-Chal:
    (ALL) NOPASSWD: /usr/bin/perl /home/itguy/backup.pl
```

Easy. However, I failed to run sudo without a password for a bit. One thing to remember is that the above text is a match expression, an exact match expression.

9. To get a root shell, after opening a listener and updating copy.sh, I ran `sudo /usr/bin/perl /home/itguy/backup.pl` (note the exact match to the allowed rule in sudoers)

10. The root flag at `/root/root.txt` was `THM{6637f41d0177b6f37cb20d775124699f}`