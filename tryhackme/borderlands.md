# Borderlands **INCOMPLETE**

https://tryhackme.com/room/borderlands

enum on the website reveals a git directory. using gitdumper, you can get the sites content which reveals a portion of three 'api keys', and a sql injection vulnerability along with the mysql creds (root)
through the git log, you can get the full git api key, and the web api key is around too. the android key needs to be pulled from the apk you can download, but is ciphered. knowing the first 20 characters from the api code, you can deduce (trial and error, getting a key that returns the result, though the key's structure becomes obvious quickly) the vignere cipher key and get the full value
with the sqli you can add a php shell to a dumpfile at /var/www/html/shell.php
to get a reverse shell, you php-reverse shell and either the sqli or a web shell with base 64 decode
on the machine need to enumerate adjacent servers. i struggled here; need to get better at 'living off the land', e.g. php or python network and port scanners.
