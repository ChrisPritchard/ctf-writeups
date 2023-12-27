# Advent of Cyber '23 Side Quest

Main room for tracking is accessible here: https://tryhackme.com/room/adventofcyber23sidequest

This was a real fun challenge, these rooms, significantly due to the competitive nature of the rooms. Given I won the overall competition (which required coming first in SQ4) I particularly enjoyed them :)

I did these rooms with the aid of my team, made up of some of the volunteer room testers for THM (we didn't get to test these rooms, so were allowed to participate): Shamollash, Shadow Absorber and Scrubz

## Side Quest 1, Released Day 1

Finding the address: there were four QR code fragments, one in task 5 of the main side quest room. The other three could be found in links on social media:
- LinkedIn post: https://www.linkedin.com/posts/tryhackme_can-you-help-elf-mcskidy-and-her-team-tackle-activity-7135598321280188416-5wnQ?utm_source=share&utm_medium=member_desktop
- One was in the THM discord
- One was on Twitter (non elno link): https://nitter.net/RealTryHackMe/status/1730184898365767880#m

Once combined they gave the address of the First challenge, which involved deciphering a PCAPNG file to answer questions. **Note**, I recommend getting the latest version of wireshark for this.

To answer the questions, the file must be decoded in the following way:
- first, recognise that it is wifi traffic and use aircrack-ng or hashcat retrieve the password for the network, so you can decrypt the wifi packets
- next recognise that there are two streams of traffic over the network: TLS and reagular HTTP. The http traffic will show a backdoor and allow retrieving the destination servers TLS signing keys
  	- one way to detect this is to look at stats
- with the signing keys, decode the TLS traffic to get RDP traffic. Extract this traffic for further work ('Extract PDUs to File' from the file menu)
- using a tool like pyrdp, decode the RDP traffic into an MP4 of the session, and some json info of things like clipboard contents. This will allow all questions to be answered.

> with pyrdp (https://github.com/GoSecure/pyrdp), it has that normal dependency hell you get with python, yay.
> My process to get it going was to run it with docker, mapping some directory containing the pcap e.g. `docker run -it -v c:/users/chris/downloads:/tmp/downloads gosecure/pyrdp:latest`
> Then, once you have a shell in the container, run `export QT_QPA_PLATFORM=offscreen` to fix the QT bug that was popping up.
> After this you can do things like `pyrdp-convert.py -f mp4 pdus.pcap` to get the mp4 file without issue (some errors, but ignorable)

## Side Quest 2, Release Day 6

Finding the address: the javascript game for this day involves memory corruption. Its possible to induce the game to reveal the next QR code:
- buy the yeti token: set name to `testtesttest~~~~` to get max coins, then go to store and buy 'a'
- set 'namer' name to Ted: `testtesttesttesttesttesttestTed`
- set 'store' name to Midas: `testtesttesttestMidas`
- set coins to 31337 + 8: `testtesttestqz`
- change player name to `Snowball`
- enter secret code `UUDDLRLRBA` (just type these letters/directions while the screen is focused)

Once in the side quest room, its a standard boot to root:
- multiple ports, including a site on 8080 that prevents external access and a 'trivision' camera interface on a high port
- there is a vuln in this camera software that can be exploited: https://no-sec.net/arm-x-challenge-breaking-the-webs/. I fixed up the script with some notes here: https://gist.github.com/ChrisPritchard/1a858629007ade1bd0ed9814e0d40486 (sq2-trivision-shell-rce.py)
- when run this will get a limited privilege shell. You can use this to enumerate the camera application and get the second flag (buried in one of its pages). Additionally you can find credentials that will allow you to curl the login form for the 8080 site (requests must be made with basic auth) and it will respond: 
	`curl -v http://10.10.159.68:8080/login.php -d 'submit=ok&username=&password=' -u 'redacted:redacted'`
- the login form is vulnerable to mongodb injection - with effort, this will allow you extract usernames from the database (same link as above, https://gist.github.com/ChrisPritchard/1a858629007ade1bd0ed9814e0d40486, sq2-mongodb-username-bruteforce.py - this might require setting up tunneling)
- signing in with the detective's username will get you the flag - note you can bypass passwords with standard mongodb login bypasses, e.g. `password[$ne]=test`

## Side Quest 3, Release Day 11

Finding the address: on the desktop of the admin user for this day is the saved website of a chat log. If you explore this you will see that they cropped an image - the acropalyse vuln and exploits can recover the full image from this which contains the QR code.
I used this for the cropping: https://github.com/frankthetank-music/Acropalypse-Multi-Tool

Once in the side quest room, its another boot to root.
- there are a few suspect ports: one hosts FTP, one hosts vim, one nano and one blank
- ftp contains the first flag, and also allows you to put files. put a copy of busybox
- with nano and/or vim, you can use their file browsing capabilities to explore the file system, including seeing where the ftp directory is and where the vim/nano binaries have been placed. you can also open arbitary files, e.g. /proc/self/environ to get the second flag
- create a custom executable that will copy your busybox binary over the nano binary, and rename it to sh while also making it executable (there is no chmod on the box). an example is with my other scripts, https://gist.github.com/ChrisPritchard/1a858629007ade1bd0ed9814e0d40486, sq3-file-copier.c. You will need to compile it on the right version of ubuntu to be appropriately linked, ubuntu 22, or make it static.
- using vim, set the shell to be this new custom executable and start a shell to execute it. then set the shell to be your new sh/busybox binary.
- you can now escape vim into a busybox shell. by running ps aux, you can see the 'blank' port from above maps to a missing sh binary elsewhere in the system, running as root.
- copy busybox over that missing path, then connect over the new port to get a root shell
- finally, a standard docker escape will get to the host and get the final flag. Specifically the release agent docker escape, e.g. https://vickieli.dev/system%20security/escape-docker/#container-escape

## Side Quest 4, Release Day 20

Finding the address: in the git history of the server, the older advent of cyber image contains the QR code

The side room is another boot to root:
- two ports, 22 and 8000
- On 8000 is a 'downloader site', running using werzkeug
- The downloader url is vulnerable to SQL injection. With this you can see it retrieves a url from a db and then downloads that. Using injection you can specify any url including file:// urls
- With this capability, the following exploit can be exercised to get access to the werkzeug debug console: https://book.hacktricks.xyz/network-services-pentesting/pentesting-web/werkzeug. From there, a python shell can get you access as mcskidy
- To get mcskidy's password you can inspect the git history of the app in their home folder. This will reveal the old database password, which is their personal password.
- Sudo -L reveals they can run /opt/check.sh as root, and that the path for sudo includes mcskidy's home folder. So the exploit to use is path hijacking.
- Examing check.sh you will find it uses /opt/.bashrc. This is a standard bashrc, but includes an extra line at the top: `enable -n [ # ]` - what this specifies is that `[` in bash will check the path first before the builtin
- Creating a binary or script named `[` in mcskidy's home folder enables you to hijack root privileges when you run the script

I got the last room around five minutes before the next in line, very close!
