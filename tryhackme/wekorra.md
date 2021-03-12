# Wekor

https://tryhackme.com/room/wekorra

A medium level room, semi involved. The room suggested adding wekor.thm to your hosts file, which is generally a hint that sub domain enumeration is required.

1. Rustscan revealed 22 and 80. On 80 was a blankish site, but the robots file had many entries. Only one worked, and gave a hint to a another path for a site called 'it.next'
2. I started enumerating the above, and at the same time used burp intruder to search for subdomains. Eventually it found one, also mostly blank, but which said 'site is coming soon!'.
3. I ran dirb on this subdomain, and found a wordpress site. Nice. Only one user was picked up by wpscan, and I started bruteforcing.
4. Back with 'it.next', I manually enumerated this, looking for forms and the site. Eventually I found one that allowed for sql injection (found by submitting `'` and getting the classic mysql error message).
5. Dumping the database with sqlmap revealed just a single, useless table. But manual enumeration eventually showed I was running as root - with this in mind, I gathered the usernames and hashes from the wordpress database.
6. Putting these into crackstation revealed nothing, but throwing them at hashcat with rockyou revealed the passwords for three users (not the admin account).
7. Trying these users, the second one I tried was a wordpress admin. In the admin dashboard, I uploaded the WPTerm plugin to get a web shell via the plugin interface.
8. Using the webshell, I got a reverse shell which I upgraded with the pty spawn method.
9. In one of the wordpress configuration files (tracked down using linpeas) was the password for the root database user, which made things convenient.
10. further enumeration however got me nowhere: secure-file-priv was set, meaning I couldn't perform the udf trick for privesc
11. moving on, I ran `netstat -tlpanu` to get local services, and found port `11211`. researching showed this was memcache, which seems unusual. going through tips on this page https://book.hacktricks.xyz/pentesting/11211-memcache, I tracked down keys for the Orka user, getting their password.
12. the password worked (though annoyingly, only via my reverse shell and not through a clean new ssh session), and I got the user flag.
13. `sudo -l` showed the user could run a `bitcoin` binary. I decompiled this with ghidra and saw it would run using python the script next to the binary, which appeared to simulate a bitcoin transfer.
14. the binary seemed to be coded in such a way that despite running a system command, I couldn't inject anything. The python script couldn't be deleted either (so I couldnt swap it out with a python shell).
15. I ran linpeas again, which showed `/usr/sbin` was writable, which is part of the default path. importantly, python was in `/usr/local/bin`, a path *after* `/usr/sbin`. therefore, I created a new file called `python` in `/usr/sbin` containing `/bin/bash -p`, and marked it as executable. running the bitcoin binary again as sudo got me a root shell and the final flag :)
