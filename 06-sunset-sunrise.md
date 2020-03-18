# Sunset: Sunrise

https://www.vulnhub.com/entry/sunset-sunrise,406/

## Reconnaisance

A quick nmap over all ports only revealed 22, 80, 3306 and 8080 open. No FTP this time.

Port 80 is hosting some sort of default nginx file, while 8080 seems to be hosting the var/www folder using something called Weborf/0.12.2. It showed html/ and when I clicked through, it contained `index.nginx-debian.html` that showed the same content as port 80.

Looking up Weborf with that version, it is vulnerable to path traversal when using encoding slashes, and testing this proved I could navigate throughout the machine.

## Exploring and wfuzz

I browsed around the machine, but couldn't find anything. I could reach the weborf home directory, but couldn't see anything in there. Following a hint, I decided to use wfuzz on it.

The path to show the directory was `http://192.168.53.7:8080/..%2f..%2fhome%2fweborf%2f`, and a useful wordlist for local user directory fuzzing is `/usr/share/wordlists/dirb/common.txt` on kali.
