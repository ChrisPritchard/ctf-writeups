# Inferno

https://tryhackme.com/room/inferno

"Real Life machine vs CTF. The machine is designed to be real-life and is perfect for newbies starting out in penetration testing" <- not too sure about this.

Enum for this machine was frustrating, as there were dozens of ports open. In fact, I usually use nmap -sS -sV -vv for recon but it took over an hour here to scan the whole box. Much better to use rustscan, which on the tryhackme machine can be run with docker as so:

  `docker run -it --rm --name rustscan rustscan/rustscan:latest -a 10.10.36.88 -- -sV`
  
In any event, only the two standard ports were actually open, 22 and 80. On 80 was a simple website with a quote from dante's inferno, and with a bit of enum via gobuster, a sub directory `/inferno` that was protected by basic auth.

No further enumeration returned anything else, not even a username - typically I don't like to randomly brute force username's AND passwords, but that was the next step here. Long story short, going with a short list of usernames or just random guessing might get you to running hydra like:

  `hydra -l admin -P /usr/share/wordlists/rockyou.txt -f 10.10.105.168 -m /inferno http-get`
  
Which eventually revealed the password for admin.

On /inferno was a installation of a web ide called 'Codiad'. It showed a file directory under inferno, the tool itself. However, no paths were writable: even though Codiad supports creating or uploading files, trying to do so would fail.

The tool itself is out of support, and there are some CVEs against it unresolved. A quick DDG found https://github.com/WangYihang/Codiad-Remote-Code-Execute-Exploit, but it wouldn't work as is - the tool was not setup to support basic auth.

In order to get it functioning, I modded the `exploit.py` file so whenever it used session.get or session.post, it would specify basic auth headers. E.g.:

  ```python
  response = session.post(url, data=data, verify=False)
  ```
  
  Became
  
  ```python
  headers = {
    "Authorization": "Basic etcetc"
  }
  response = session.post(url, data=data, headers=headers, verify=False)
  ```
 
Once I got a shell, I noted that it would periodically close, probably due to a cronjob somewhere. It looked like every minute. I was able to work with this however.

In the home directory was dante's folder, with the local.txt file being unreadable. I ran a `ls -laR` which found, under /Downloads, a `.download.dat`. In very CTF fashion (not real life pentest at all) this contained hexadecimal characters which I ran through cyberchef to reveal dante's password.

At this point I dropped the exploit shell and just ssh'd in, getting the first flag.

Getting to root was easy: `sudo -l` revealed the user could run /usr/bin/tee as root without a password (even though I had the password). Tee sends its input to two outputs, and can both write and append. Being able to use it as root means I could use it to append to the passwd file, and I used a handy entry I keep around for just such an occasion (which i put into a file called pass): `cat pass | sudo /usr/bin/tee -a /etc/passwd` with pass containing: `user3:$1$user3$rAGRVf5p2jYTqtqOW5cPu/:0:0:/root:/bin/bash` (which has password `pass123`).

Once done, I just `su user3` with `pass123` to escalate to root. The final proof.txt was in /root. Easy.
