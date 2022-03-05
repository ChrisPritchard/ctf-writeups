# Oh My WebServer

*Can you root me?*

Yes. Yes I can.

Bit of an odd room - I compromised it pretty quickly, but not sure if I followed the correct path as I got root before user.

1. A scan revealed just ports 22 and 80. On 80 was the simple 'It works!' message, so I started bruteforcing with gobuster.
2. This wasn't going anywhere so I checked out the software versions. SSH looked secure, but Apache was running 2.4.49, infamous for some recent path traversal/RCE bugs with CGI-BIN.
3. I used this script to cleanly get RCE: https://www.exploit-db.com/exploits/50383
4. The target machine did not have many utilitys: no netcat, no wget. Usually indicative of a docker container and sure enough, .dockerfile was in /. I downloaded a static version of ncat from https://github.com/andrew-d/static-binaries/raw/master/binaries/linux/x86_64/ncat and used curl to download it to the machine.
5. Using this ncat instance (after setting permissions) I was able to get a reverse shell with `ncat -e`.
6. In the tmp directly (which is where I had saved ncat) I found an omi.py. Its possible this was accidentally left here? It contained a script that appeared to exploit remote execution on a given IP address.
7. I ran `ifconfig` to see the IP address was 172.17.0.2, so I tried using the script against 172.17.0.1 with the command whoami, which returned root.
8. Repeating steps 4 and 5 I got a reverse shell as root on 172.17.0.1, the apparent host. Here I got the root flag.
9. To get the user flag I simply ran a search: `find / -name user.txt 2>/dev/null`, where it was revealed as possibly being present in a docker container somewhere (not the one I had come from). I was able to read the file result to get the user flag.

Cheers
