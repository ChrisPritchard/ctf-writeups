# Sunset: Sunrise

https://www.vulnhub.com/entry/sunset-sunrise,406/

## Reconnaisance

A quick nmap over all ports only revealed 22, 80, 3306 and 8080 open. No FTP this time.

Port 80 is hosting some sort of default nginx file, while 8080 seems to be hosting the var/www folder using something called Weborf/0.12.2. It showed html/ and when I clicked through, it contained `index.nginx-debian.html` that showed the same content as port 80.
