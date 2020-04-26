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

Nikto reveals its running apache and that /login.php exists. dirb additionally showed robots.txt and a browsable assets folder. The latter showed nothing of note, but the former contained the text: `Wubbalubbadubdub`. This worked as a password on the login form, providing access to portal.php

