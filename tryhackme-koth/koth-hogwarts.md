# Hogwarts KOTH machine

The ports on this machine are random, except 22. The creds for encrypted files, users and random paths are all random too.

Paths to foothold:

- On 22 is a website (hard to access with regular browsers). By browsing `/permissions` the secret path to an upload website can be found. This allows any upload, as long as the content type is set to `application/pdf`. A webshell uploaded this way and accessed via `/uploads/shell.php` will have access as `www-data`.
- On the random ftp port, under .../... is a hidden zip file, `.I_saved_it_harry.zip`. it needs to be cracked with zip2john, but contains the ssh creds for `neville`
- The site on the random http port has a login form that is vulnerable to sql injection: using it the ssh creds for the `hermoine` user can be retrieved

Paths to root:

- /etc/room_of_requirement is a suid binary that will grant a root shell with: `{ echo -e "012345678901234567890123\xbe\xba\xfe\xca"; cat; } | /etc/room_of_requirement`
- `/bin/ip` has the suid bit set. this can get root via:

  ```
  ip netns add foo
  ip netns exec foo /bin/sh -p
  ```
  
- `hermoine` can run `date` as sudo, though this just allows file read as far as i can tell with `date -f file`
- `draco` can run `easy_install` as root, which can privesc via:

  ```
  TF=$(mktemp -d)
  echo "import os; os.execl('/bin/sh', 'sh', '-c', 'sh <$(tty) >$(tty) 2>$(tty)')" > $TF/setup.py
  sudo easy_install $TF
  ```

- there is a random high port that requires the three deathly hallows. these are stored at the end of these files (yes including the binary):

  - /var/www/mystaticsite/style.cloudflare.css
  - /var/www/mymainsite/login.css
  - /etc/room_of_requirement
  
  while the two css files can be accessed via the two public websites, the binary afaik requires a foot hold
  
  submitting the three 26 character random phrases as <one> <two> <three> (order doesnt matter) grants a root shell
  
  ## flags
  
  - /root/headmaster.txt
  - /home/hermoine/special_spell.txt
  - /home/harry/special_spell.txt
  - /home/draco/achievements.txt
  - /var/www/mymainsite/conn.php
  - mysql db (root:neville_was_chosen), basement db, monsters table
  - /etc/left_corridor/seventh_floor/.entrance (thanks to mug3njutsu on discord for this)
