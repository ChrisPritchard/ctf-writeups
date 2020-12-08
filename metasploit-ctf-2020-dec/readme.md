# Metasploit CTF - December 2020

- Player Name:  **aquinas_nz**
- Team Name:    **() { :;}; echo vulnerable**

This is the first CTF for me where I have finished all the challenges and, as I came 9th out of ~1000, the first where I have won something. I also did this as a solo player rather than as a team, in contrast to all but two of the other top ten.

<img src="./final-top-10.png" />

While the top 15 get the prizes, only the top ten show on the board. Lucky lucky :D

The gist of the competition was that you were given a jump host and from there could reach a final vm. On that VM there were 20+ ports, with each of the initially visible ports (with a couple of exceptions) being a source for a flag. Once you had a flag in PNG form, you were to md5sum it and submit the result as the flag key on the challenge portal. In almost all cases I got the flag image and [they are saved here](./flag-cards) - a few either did not have a card, or the card was too hard to retrieve so I just grabbed the md5 via whatever RCE I was running.

Tools used:

- Windows Terminal, to use Powershell and create a local socks proxy through the jump host via `ssh -D 8888 -i .\metasploit_ctf_kali_ssh_key.pem kali@ip`. As I was on windows this was very useful.
- Kali on WSL2 - I also used Kali on the jump host when I needed more speed, e.g. for ffuf or running the exploit for 5555. But mostly I just used my main machines WSL2 instance.
- Hashcat on Windows - nothing like a 2080 for password cracking (except, er, a 3080/90, which I don't have).
- Burp Suite on Windows - the proxy from above was punched into burp's project config so I could use its inbuilt browser and brute forcing without messing about. The speed was quite good.
- [Cyberchef](https://gchq.github.io/CyberChef/). Occasionally for specific challenges, but primarily for converting base64 back into card images, or if I needed to exfil a binary or something. Cyberchef is just a more stable way to do this than to use windows terminal, which can be slightly flaky when you paste a hundred pages of base64 into it.

I have listed my very brief solutions for each challenge below, with the occasional note, in the order of the port number (not the order I solved them). The headings are taken right from the results of an initial `nmap -sS -sV`.

## 53/udp

Found this second to last, as up until this point I hadn't done a UDP scan because they are slow.

`nmap -sU` revealed port 53, so I used dig to query it and verify it was indeed a DNS server. Doing a dig against 'metasploit.ctf' revealed nothing, but doing a reverse lookup (ie. `dig @ip +x ip`) revealed a custom card url. Querying the card url via dig and the DNS server for its TXT records (`dig @ip targeturl txt +noall +answer`) revealed one full of base64, which I grabbed and ran through cyberchef to get the card.

## 1337/tcp open  waste?      syn-ack ttl 63

Accessible over `nc ip 1337`, this presented an interactive interface, like a telnet session. One of the options reflected what you submitted back to you, but it took a long time for me to learn this was a format string exploit (which I've never encountered before). Basically, if C format strings are handled poorly, you can submit something like `%x` or `%p` and just read from memory.

The challenge was just finding the flag with its md5 in memory - almost unique, this challenge did not have a card image sadly. The ultimate exploit was to submit `%9$s` which read the flag from the binary's stack or similar.

## 1080/tcp open  socks5      syn-ack ttl 63 (No authentication; connection failed)

A socks proxy. I tried nmap's proxy options, but these failed me. Ultimately I configured proxy chains to run through the proxy port, and used `proxychains nmap 127.0.0.1`  to scan the server and find a hidden website. On there was the flag image, so `proxychains wget` retrieved it for me.

## 80/tcp   open  http        syn-ack ttl 63 nginx 1.19.5

The first flag, probably for everybody. The flag is right there, along with a message saying all the others are on the other ports.

## 4545/tcp open  http        syn-ack ttl 63 SimpleHTTPServer 0.6 (Python 3.8.5)

A file server showing a binary (`.elf`) and an encoded file (`.enc`). I used [ghidra](https://ghidra-sre.org/) on the binary to discover once you submitted whatever key it was looking for (I didn't bother to figure this out) it used a XOR on 'A' (`0x41`) over the enc file. I did that in Cyberchef to get the flag.

## 5555/tcp open  telnet      syn-ack ttl 63

A game, where over the terminal (`nc` again) you had to press left and right to dodge falling obstacles. Pretty neat! The game would get faster and faster, and I for one found it near impossible.

Instead I wrote [this in Golang](./5555.go), which played it for me. I had to run this on the jump host so the lag wouldn't break it, but fairly quickly I hit the max scare and the game told me to look under another, just opened port, where I found the flag :)

## 6868/tcp open  http        syn-ack ttl 63 WSGIServer 0.2 (Python 3.8.5)

A photography site where you could sign up to get 'notes', with a strict system: first name, optional middle name, and last name, resulting in a custom url like (for me) CP or CJP, depending on whether I used my middle name.

With burp I brute forced other users, then brute forced their notes (just 0 - 10 after the initials, for a url like `/notes/CP/0`). From that I found mentions of some sysadmin who had pushed to have the middle name bit reduced to one letter, and across several notes I found her name was `Beth Yager` with a long middle name, `UDD`. `BUDDY`. Grabbing her notes, there was a mention of files, and at a guess, `/files/BUDDY/2` got me the flag.

## 8080/tcp open  http        syn-ack ttl 63 Apache httpd 2.4.38 ((Debian))

I think the second flag after the first. It gave you a user called 'guest' which took five seconds per login attempt, and the challenge was to find another user. A simple brute force via burp using the built in short user list found `demo` also took five seconds. Entered that to get the flag.

## 8092/tcp open  http        syn-ack ttl 63 Apache httpd 2.4.38 ((Debian))

A login form that provided the running PHP code beneath. You had to submit a password that would be hashed with a salt you weren't able to see, and the hash it would be compared with. Looked like type juggling, and after a quick refresher, I solved the challenge by using Burp to send `user=admin&password[]=`. 

The way this works is that the password becomes an array, and the hashing function the code was using would error and return null (no exceptions!). By omitting the hash, that is also null and so the comparison passes and I got the flag.

## 8101/tcp open  http        syn-ack ttl 63 Apache httpd 2.4.38 ((Debian))

This was the very *last* challenge I did, and the second point I thought about quitting. It gave you a pcap file and asked you to write a metasploit module to 'replicate the attack'. I've never done that before, and had no interest in doing so. But at this point I was at 1900/2000 (the flags were a hundred each) and still in a position to win a prize, so I finally decided to just have a crack at it, no pressure.

I used the samples they provided, but ultimately my main source was copying existing snippets of code from metaploit ftp exploits in the framework. The exploit, according to the [pcap you can see here](./capture.pcap), had three phases: connect to a ftp server and upload a php file, connect to the webserver and observe that the php file is reachable and runnable, and then, presumably, open a meterpreter connection back. They provided a res file that waited for the meterpreter session, which I've preserved [here](./5_of_clubs.rc) with little changes

The ftp stuff was hard but eventually solved, the web request to evaluate the php was tricky since there were framework name collisions that were annoying to get around, but ultimately this challenge had a clever trick - it was all a ruse! Once the file was uploaded and you could process it, you basically had a module that executed rce on the server... forget about meterpreter! I just used the rce and the helpful feedback page the website had, to examine the server and find the flag. I then just read its md5 sum into the logs, and submitted that for the win!

The final exploit is [here](./5_of_clubs.rb), with the original 'im vulnerable' command. I modified that to do a find and then a md5sum.

## 8123/tcp open  http        syn-ack ttl 63 WSGIServer 0.2 (Python 3.8.5)

A funny site about how the admin hates salt and salting hashes, and salt on hashes (the food). Funny stuff. I had to get into admin, which was protected by basic auth.

The site had the admin's email address, the path to admin, and subpages that both allowed you to discover a password had to be 9-14 characters, and that the admin's password started with `ihatesalt`. This latter was via a 'password hint page', and via burp I was able to see the hint was actually one part of a json payload that included the full password hash. 

I bruteforced the final password via hashcat with `./hashcat.exe -a 3 -m 0 ..\jimjones.hash ihatesalt?a?a?a?a?a`

## 8200/tcp open  http        syn-ack ttl 63 Apache httpd 2.4.38 ((Debian))

I think the third challenge I beat, a simple php upload vuln. To bypass the filter I just needed the extension to be .jpg.json, and for the web shell to have the magic bytes of an image, which was easy enough to source. With the shell I found a hidden subdirectory containing the flag.

## 8201/tcp open  http        syn-ack ttl 63 nginx 1.19.5

This one took a while, because I was dumb. Navigating it redirected to an explicit host which broke the browsing, but I was able to inspect the proper response in burp by overriding the target and host header. The inner host was intranet.metasploit.ctf, and that there was something on 'other subdomains'.

A spent a lot of time bruteforcing basically `FUZZ.metasploit.ctf`, giving up. When I came back to this I got the solution in seconds by doing `FUZZ.intranet.metasploit.ctf` /facepalm. The flag was on `hidden.intranet.metasploit.ctf`.

## 8202/tcp open  http        syn-ack ttl 63 nginx 1.19.5

A SPA site which had some funny api queryies going on as you browsed it. Eventually recognised it as a graphQL api, and used introspection to find a posts table. Querying that using the api got me the flag.

## 8888/tcp open  http        syn-ack ttl 63 Werkzeug httpd 1.0.1 (Python 3.8.5)

This was probably the hardest, and almost caused me to give up. I spent hours on it on the first night, and woke up the next morning figuring it was unsolvable. I actually *did* give up, truthfully, and only came back in when I had a brain flash :) More details on this one because it was epic.

1. the site showed a massive list of metasploit modules, and initially had no obvious forms of attack
2. eventually, while trying to trigger an error, I mangled its session cookie. this triggered an error that said 'pickle.loads' failed
3. pickle is a python object serialiser/deserialisation technique, and I had actually encountered it in a [recent attack room on tryhackme](tryhackme.com/room/peakhill)
4. soon enough I had RCE on the server via this technique (you can execute a command when it deserialises and object), but where was the flag?
5. it didn't take me long to find it - [8888-app.py file here](./8888-app.py) shows what they did. The flag's contents were loaded into memory and the flag itself deleted.

This stumped me. How, even with rce (and as root no less!) could I retrieve the flag? I tried undeleting it, considered dumping memory, no luck.

Ultimately the next day, after noon, while lying in bed and staring at the ceiling, the solution came to me: the way the pickle attack works is that you can specify how the pickled object is reconstituted by specifying an object and some args. The RCE comes from specifying the object as `os.command` and the args as what you want to run. But... what about a different object? Does python have something like eval? It does! It has exactly something like eval! And I knew I can access global variables like the loaded FLAG via `globals()['FLAG']`. 

So I used [8888-exploit.py](./8888-exploit.py) to create a base64 payload that when run would take the FLAG variable and write it back to disk where I could reach it. This one was sooooo satisfying, given I had spent almost four hours on it.

## 9000/tcp open  http        syn-ack ttl 63 WEBrick httpd 1.6.0 (Ruby 2.7.0 (2019-12-25))

This one took a long time. A simple search box that exposed a file listing. I figured os command injection, but nothing I could do would trigger it. I eventually passed the form paramter as an array (i.e. search[]= rather than search=) which triggered a full exception with stack traces. Via that I found the command being run was `find ./Games -iname "*#{param}*"`.

Again, this looked like os command injection, but nothing I did could break out of those quotes. Finally, almost by luck, I discovered in the docs for find that \`\` should still work - I can't escape, but I can evaluate commands directly in place. Testing this with `echo -e \x41` and getting the results for a regular search for `A` verified this.

Via this I found the flag and emitted its contents into the form template the page was derived from, so I could extract the image. I could have just done an md5 in place, but I like the images :) (also I only remembered this later).

## 9001/tcp open  http        syn-ack ttl 63 Thin httpd

Pretty obvious sql injection. Used union selects from the sqlite master tables to find all table names, then extracted the cols from the 'hidden' table to find the path to the hidden flag.

## 9007/tcp open  http        syn-ack ttl 63 Apache httpd 2.4.46 ((Unix))

A zip file. I didn't even bother trying to extract it normally, but just ran `binwalk -e` over it which pulled the flag out.

## 9009/tcp open  ssh         syn-ack ttl 63 OpenSSH 7.6p1 Ubuntu 4ubuntu0.3 (Ubuntu Linux; protocol 2.0)

Quite tricky. The banner told you to login in as admin, so I did guessing the password was `password`. Once on, it was a traditional privesc, but using a technique I haven't used in a very long time and with a twist. 

There was one SUID executable, `vpn_connect`, that took a username, password and a log location. It would emit the username/password into the log location as a overwrite (but not complete replace). So... how to abuse this?

Eventually I worked out that if you used a very long password it would loop onto a newline, essentially allowing you to write lines you controlled with a bit of garbage in front of them. Not too much text - I tried and failed to use this to append to `root/.ssh/authorized_keys` - but enough for say... a line in `passwd` with a silly password.

While this made me nervous, it did indeed work when I appended a new user with id and group 0 (and so basically another root user) and a md5 hashed password. `su mynewuser` got me root and the flag.
 
## 9008/tcp open  java-object syn-ack ttl 63 Java Object Serialization

This port was ultimately only used in the context of the next challenge, and didn't have a flag of its own.

## 9010/tcp open  http        syn-ack ttl 63 Apache httpd 2.4.38

A curious one. The port contained a file listing allowing you to download a jar file. Running it, and pointing it at 9008 above, would give you a terminal listing allowing to download the flag if you entered the right password.

I came back to this a few times, after using [jd-gui](https://java-decompiler.github.io/) to decompile it but not seeing where there was an exploit.

Ultimately the solution was simple, if a bit messy (I don't write java normally, so had to install a few things like the SDK): I used the code from the decompile, changed it so just before downloading it marked me as being authenticated, then recompiled it into a jar and ran it. It worked! It turns out that while auth was checked 'server side', it was also checked at certain critical points 'client side', and so I was able to bypass the check.

You can see the code with its modifications [here](./QOH_Client.jar.src). One note, I did this on my main machine, so to get this working through the socks proxy I ran the compiled class files as so: `java -DsocksProxyHost="127.0.0.1" -DsocksProxyPort=8888 Client .\AuthState.class .\Client.class`

