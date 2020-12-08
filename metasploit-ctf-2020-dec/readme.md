# Metasploit CTF - December 2020

Player Name:  aquinas_nz
Team Name:    () { :;}; echo vulnerable

This is the first CTF for me where I have finished all the challenges and, as I came 9th out of ~1000, the first where I have one something. I also did this as a solo player rather than as a team, in contrast to all but two of the other top ten.

The final [scoreboard can be seen here](./Top 10 Teams.png). While the top 15 get the prizes, only the top ten show on the board. Lucky lucky :D

The gist of the competition was that you were given a jump host and from there could reach a final vm. On that VM there were 20+ ports, with each of the initially visible ports (with a couple of exceptions) being a source for a flag. Once you had a flag in PNG form, you were to md5sum it and submit the result as the flag key on the challenge portal. In almost all cases I got the flag image and [they are saved here](./flag-cards) - a few either did not have a card, or the card was too hard to retrieve so I just grabbed the md5 via whatever RCE I was running.

Tools used:

- Windows Terminal, to use Powershell and create a local socks proxy through the jump host via `ssh -D 8888 -i .\metasploit_ctf_kali_ssh_key.pem kali@ip`. As I was on windows this was very useful.
- Kali on WSL2
- Burp Suite on Windows - the proxy from above was punched into burp's project config so I could use its inbuilt browser and brute forcing without messing about. The speed was quite good.
- [Cyberchef](https://gchq.github.io/CyberChef/). Mainly for encoding challenges, but primarily for converting base64 back into card images, or if I needed to exfil a binary or something. Cyberchef is just a more stable way to do this than to use windows terminal, which can be slightly flaky when you paste a hundred pages of base64 into it.

I have listed my very brief solutions for each below, with the occasional note in the order of the port number (not the order I solved them). The headings are taken right from the results of an initial `nmap -sS -sV`.

## 53/udp

Found this second to last, after guessing 9008 which also hadn't had a flag but had been involved in the flag for 9010 probably wasn't the right answer. Up until this point I hadn't done a UDP scan because they are slow.

`nmap -sU` revealed port 53, so I used dig to query it and verify it was indeed a DNS server. Doing a dig against 'metasploit.ctf' revealed nothing, but doing a reverse lookup (ie. dig @ip +x ip) revealed a custom card url. Querying the card url via dig and the DNS server for its TXT records revealed one full of base 64, which I grabbed and ran through cyberchef to get the card.

## 1337/tcp open  waste?      syn-ack ttl 63

Accessible over nc ip 1337, this presented an interaction interface, like a telnet session. One of the options reflected what you submitted back to you, but it took a long time for me to learn this was a format string exploit (which i've never encountered before). Basically, if C format strings are handled poorly, you can submit something like %x or %p and just read from memory.

The challenge was just finding the flag with its md5 in memory - almost unique, this challenge did not have a card image sadly. The ultimate exploit was to submit `%9$s` which read the flag from the binary's stack or similar.

## 1080/tcp open  socks5      syn-ack ttl 63 (No authentication; connection failed)

A socks proxy. I tried nmap's proxy options, but these failed me. Ultimately I configured proxy chains to run through the proxy port, and used `proxychains nmap 127.0.0.1`  to scan the server and find a hidden website. On there was the flag image, so `proxychains wget` retrieved it for me.

## 80/tcp   open  http        syn-ack ttl 63 nginx 1.19.5

The first flag, probably for everybody. The flag is right there, along with a message saying all the others are on the other ports.

## 4545/tcp open  http        syn-ack ttl 63 SimpleHTTPServer 0.6 (Python 3.8.5)

A file server showing a binary (.elf) and an encoded file (.enc). I used [ghidra](https://ghidra-sre.org/) on the binary to discover once you submitted whatever key it was looking for (I didn't bother to figure this out) it used a XOR on 'A' (0x41) over the enc file. I did that in Cyberchef to get the flag.

## 5555/tcp open  telnet      syn-ack ttl 63

A game, where over the terminal (nc again) you had to press left and right to dodge falling obstacles. Pretty neat! The game would get faster and faster, and I for one found it near impossible.

Instead I wrote [this in Golang](./5555.go), which played it for me. I had to run this on the jump host so the lag wouldn't break it, but fairly quickly I hit the max scare and the game told me to look under another, just opened port, where I found the flag :)

## 6868/tcp open  http        syn-ack ttl 63 WSGIServer 0.2 (Python 3.8.5)
DONE IDOR challenge: brute force notes to find admin Beth UDD Yager (BUDDY), then her files /files/BUDDY/2 for card

8080/tcp open  http        syn-ack ttl 63 Apache httpd 2.4.38 ((Debian))
DONE (brute force username looking for delay, found demo)

8092/tcp open  http        syn-ack ttl 63 Apache httpd 2.4.38 ((Debian))
DONE php type juggling: user=admin&password[]= (password hash becomes null, no second param submitted so also null)

8123/tcp open  http        syn-ack ttl 63 WSGIServer 0.2 (Python 3.8.5)
DONE hint reveals admin hash and prefix, bruteforced with hashcat via `./hashcat.exe -a 3 -m 0 ..\jimjones.hash ihatesalt?a?a?a?a?a`

8200/tcp open  http        syn-ack ttl 63 Apache httpd 2.4.38 ((Debian))
DONE (upload php polyglot (.jpg.php and must have magic bytes), image was in hidden sub dir on server)

8201/tcp open  http        syn-ack ttl 63 nginx 1.19.5
DONE intranet.metasploit.ctf, manually set host header. brute force FUZZ.intranet.metasploit.ctf to find hidden. where the flag is

8202/tcp open  http        syn-ack ttl 63 nginx 1.19.5
DONE graphql under /api, introspection reveals posts, query posts to get flag

8888/tcp open  http        syn-ack ttl 63 Werkzeug httpd 1.0.1 (Python 3.8.5)
DONE pickle deserialisation, pass command to eval to read flag from global variable and write to disk

9000/tcp open  http        syn-ack ttl 63 WEBrick httpd 1.6.0 (Ruby 2.7.0 (2019-12-25))
search processes commands in ``, used that to find where the html form being viewed was, then append commands to it and finally base64 of image when found

9001/tcp open  http        syn-ack ttl 63 Thin httpd
DONE (sql injection, union select to get all tables, then all values from hidden table)

9007/tcp open  http        syn-ack ttl 63 Apache httpd 2.4.46 ((Unix))
DONE zip file extracted using binwalk -e

9009/tcp open  ssh         syn-ack ttl 63 OpenSSH 7.6p1 Ubuntu 4ubuntu0.3 (Ubuntu Linux; protocol 2.0)
DONE vpn_connect used to add new user with controlled password and 0:0 to passwd

9008/tcp open  java-object syn-ack ttl 63 Java Object Serialization
9010/tcp open  http        syn-ack ttl 63 Apache httpd 2.4.38
DONE recompiled app to set auth is true on download action

## TODO

8101/tcp open  http        syn-ack ttl 63 Apache httpd 2.4.38 ((Debian))
writing a custom metaploit module
