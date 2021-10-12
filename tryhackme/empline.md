# Empline

https://tryhackme.com/room/empline

A medium-classed room that wasn't too tricky.
  
A scan revealed 22, 80 and 3306. On 80 was a made-up website.
  
Amongst the links on the site was a url for 'job.empline.thm/careers'. By setting up host entries, I could visit this site and see it was running software called 'OpenCats, 0.9.4'.

An exploit exists for this version, here: https://www.exploit-db.com/exploits/50316

In order to run this I needed to install 'python-docx' via pip, and run it with pip3. However, while it generated a valid docx file, the post to the site wouldn't work.

Nevertheless, by going to the careers page, opening the job position, and applying using the generated docx file from the exploit, I was able to see the result in the webform: base64 encoded contents of the file I specified (initially `/etc/passwd`).

The next step was finding something interesting to read, and `config.php` from the opencats install seemed useful. This contained credentials for mysql.

I was able to use these creds to access mysql remotely, where I found a table 'users' in the 'opencats' database, that contained usernames and md5 hashes, one of which was crackable for the user 'george'.

George was also listed as one of the users in /etc/passwd, so I tried the credentials over ssh and got a user session (and the user flag).

Running linpeas.sh on this machine revealed a copy of ruby had cap_chown capabilities. I exploited this to assign george ownership of the passwd file: `/usr/local/bin/ruby -e 'require "fileutils"; FileUtils.chown("george", "george", "/etc/passwd")'`

I then added a new user (appended `user3:$1$user3$rAGRVf5p2jYTqtqOW5cPu/:0:0:/root:/bin/bash`, which has password `pass123`) to passwd, which allowed me to `su user3` and get a root shell (and the final flag).
