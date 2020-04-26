# Pickle Rick

A Rick and Morty CTF. Help turn Rick back into a human!

## nmap -p- [ip]

```
Starting Nmap 7.80 ( https://nmap.org ) at 2020-04-26 01:00 UTC
Nmap scan report for ip-10-10-160-245.eu-west-1.compute.internal (10.10.160.245)
Host is up (0.0045s latency).
Not shown: 65533 closed ports
PORT   STATE SERVICE
22/tcp open  ssh
80/tcp open  http
MAC Address: 02:A2:5E:0E:7C:36 (Unknown)

Nmap done: 1 IP address (1 host up) scanned in 5.95 seconds
```

## website at :80

Contains a short bit of text outlining the scenario. The html source contains:

```
<!--

    Note to self, remember username!

    Username: R1ckRul3s

  -->
```

Nikto reveals its running apache and that /login.php exists. dirb additionally showed robots.txt and a browsable assets folder. The latter showed nothing of note, but the former contained the text: `Wubbalubbadubdub`. This worked as a password on the login form, providing access to portal.php. I didn't guess this myself unfortunately: got distracted running hydra, which wasn't working. Stupid CTF logic.

## portal cmd interface

Portal.php presented a page with a number of tabs, all of which said access denied except for the REAL rick. The only tab accessible, the default, allowed me to execute commands in a shell-like way.

`ls -lA` revealed:

```
total 32
-rwxr-xr-x 1 ubuntu ubuntu   17 Feb 10  2019 Sup3rS3cretPickl3Ingred.txt
drwxrwxr-x 2 ubuntu ubuntu 4096 Feb 10  2019 assets
-rwxr-xr-x 1 ubuntu ubuntu   54 Feb 10  2019 clue.txt
-rwxr-xr-x 1 ubuntu ubuntu 1105 Feb 10  2019 denied.php
-rwxrwxrwx 1 ubuntu ubuntu 1062 Feb 10  2019 index.html
-rwxr-xr-x 1 ubuntu ubuntu 1438 Feb 10  2019 login.php
-rwxr-xr-x 1 ubuntu ubuntu 2044 Feb 10  2019 portal.php
-rwxr-xr-x 1 ubuntu ubuntu   17 Feb 10  2019 robots.txt
```

I tried `cat`, but got `Command disabled to make it hard for future PICKLEEEE RICCCKKKK.`

`pwd` revealed the path was `/var/www/html`, `whoami` revealed I was acting as `www-data` and `ls -lA /var/www` revealed the web dir was owned by root, so I could not write any files into it. No simple web shell for me.

However, the text files in the above listing I could obviously just browse to. Sup3rS3cretPickl3Ingred.txt revealed the first ingredient: `mr. meeseek hair`

clue.txt contained: `Look around the file system for the other ingredient.`
