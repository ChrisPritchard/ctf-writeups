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

From this I ran the suggested sql map command to test it.