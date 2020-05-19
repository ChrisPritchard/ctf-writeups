# Library

"boot2root machine for FIT and bsides guatemala CTF"

Another machine in this set, and ultimately easy. Didn't make the immediate leap at the beginning or at the end, but I got through it in an hour I think ultimately.

1. Recon revealed port 80 and 22. The website was a single page, with nothing in the source.

2. Dirb, gobuster and nikto with a variety of wordlists revealed nothing. Appeared to be a single page, with a browsable images folder containing nothing of note. I grabbed the images and checked them for stegonography without luck.

3. The one hint I could find was robots.txt:

```
User-agent: rockyou 
Disallow: /
```

I tried using rockyou as the wordlist for dirb/gobuster, but no luck.

4. I finally clicked when I saw one or more of the posts were authored by 'meliodas'. Given the comments were by 'root' and 'www-data', this was no doubt a genuine username. With `hydra -u meliodas -P rockyou.txt ssh://ipaddress` it quickly found the password: `iloveyou1`. I love you too buddy!

5. Once in, the user flag was in the home directory. There was also a `bak.py` owned by root that used python to zip up `/var/www/html` and put it in `/var/backups/website.zip`:

```python
!/usr/bin/env python
import os
import zipfile

def zipdir(path, ziph):
    for root, dirs, files in os.walk(path):
        for file in files:
            ziph.write(os.path.join(root, file))

if __name__ == '__main__':
    zipf = zipfile.ZipFile('/var/backups/website.zip', 'w', zipfile.ZIP_DEFLATED)
    zipdir('/var/www/html', zipf)
    zipf.close()
```

6. Sudo -l revealed:

```
Matching Defaults entries for meliodas on ubuntu:
    env_reset, mail_badpass, secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin\:/snap/bin

User meliodas may run the following commands on ubuntu:
    (ALL) NOPASSWD: /usr/bin/python* /home/meliodas/bak.py
```

Hmm.

7. Immediately I thought of symlinks, and I was right, but it took a while to get it right:

- first, html was owned by root, so I couldn't create symlinks there. It took me a while to realise this was why `ln -s /root /var/www/html/root` was failing, and not because /root was off limits for a symlink.
- `/blog` in `/html` was owned by meliodas, but creating a /root symlink there didn't change the size of the output zip.
- After a lot of trial and error, investigating python module hijacking etc (but that felt too high level for this CTF), I eventually learned a little about symlinks. I found out that the zipfile in python DOES get the contents of symlinks, but it has to be direct to files.

8. `ln -s /root/root.txt /var/www/html/Blog/root.txt` changed the size of the output zip, and unzipping it with `unzip /var/backups/website.zip -d ~/out/` got me the root flag.

Ultimately pretty easy. Would have liked to get full root, rather than just nicking the flag. Looking at a writeup following victory, turns out this could have been done easier: even though the file was owned by root and I could only read `bak.py`, since `meliodas` owned the directory I could have deleted `bak.py`. If I had done that, I could have replaced it with my own shell script and got full root that way. Something to remember in future.