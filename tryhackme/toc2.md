# toc2

https://tryhackme.com/room/toc2

"It's a setup... Can you get the flags in time?"

Interesting room! Sort of an education in a specific vulnerability.

1. recon showed 80 and 22. On 80 was a holding page that gave some credentials, without specifying for what.
2. robots.txt revealed a sub dir containing a cms setup file, and also in a comment gave the name of a local database
3. running the setup file, i created a new cms installation using the credentials from the home page and the database name when prompted for database details
4. logging in, under file manager, i could upload arbitary files. uploading php web shells directly didn't seem to work (they were rendered as txt/html), but i found uploading one as a text file then renaming it to php, then navigating to its path directly worked. The direct navigation might have worked without renaming - by default, the file manager used some sort of module manager to load the files which might have broken the web shell.
5. with the web shell in place, i set up a reverse shell and got access as www-data
6. the home user was for a user named 'frank', where the user flag was readable. also within was a note that gave the users password. this allowed me to drop my shell and ssh in normally
7. under the users folder was a 'root_access' folder containing a suid binary and some c code, along with a root-only file called root_password_backup. the suid binary would, however, only read files the user had access to, suid be damned.
8. the room talks about a linux file access race condition, where in the code if it uses the path to check access and then the path again to read, if you rename the file the path is pointing too between these checks you can bypass such access control. the video linked to is this one by LiveOverflow: https://www.youtube.com/watch?v=5g137gsB9Wk. In the video he uses a linux syscall to rapidly rename the files, but the c code here actually waits deliberately for a full second, so this was not necessary.
9. to get root I created a dummy file and created a symlink to it, e.g. `ln -s dummyfile myfile`, then in a separate window I readied (but didn't run yet!) `rm myfile && ln -s root_password_backup myfile`. then in the first window, i started `readcreds myfile` and quickly switched over and ran the command. first try: got the root creds :)

Flag was in the root folder as normal, after switching to the root user with their creds. Interesting room.
