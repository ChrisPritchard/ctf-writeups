# Sunset 1

https://www.vulnhub.com/entry/sunset-1,339/

## netdiscover to find the vm, nmap

A bit tricky, since I run a lot of things on my home network, and the machine didn't leap out at me. I got the ips and then started nmapping them to find the target.

Ultimately the machine netdiscover identified as `PCS Systemtechnik GmbH` was the correct one. A `nmap -p-` identified only 21 and 22 open, with an intense scan revealing:

```
PORT   STATE SERVICE VERSION
21/tcp open  ftp     pyftpdlib 1.5.5
| ftp-anon: Anonymous FTP login allowed (FTP code 230)
|_-rw-r--r--   1 root     root         1062 Jul 29  2019 backup
| ftp-syst: 
|   STAT: 
| FTP server status:
|  Connected to: 192.168.1.153:21
|  Waiting for username.
|  TYPE: ASCII; STRUcture: File; MODE: Stream
|  Data connection closed.
|_End of status.
22/tcp open  ssh     OpenSSH 7.9p1 Debian 10 (protocol 2.0)
| ssh-hostkey: 
|   2048 71:bd:fa:c5:8c:88:7c:22:14:c4:20:03:32:36:05:d6 (RSA)
|   256 35:92:8e:16:43:0c:39:88:8e:83:0d:e2:2c:a4:65:91 (ECDSA)
|_  256 45:c5:40:14:49:cf:80:3c:41:4f:bb:22:6c:80:1e:fe (ED25519)
```

## Anonymous FTP backup

Connecting to the FTP endpoint, I found a file `backup`. Its contents look like the contents of a shadow file:

```
CREDENTIALS:                                                                                                                                                                                                       
office:$6$$9ZYTy.VI0M7cG9tVcPl.QZZi2XHOUZ9hLsiCr/avWTajSPHqws7.75I9ZjP4HwLN3Gvio5To4gjBdeDGzhq.X.                                                                                                                  
datacenter:$6$$3QW/J4OlV3naFDbhuksxRXLrkR6iKo4gh.Zx1RfZC2OINKMiJ/6Ffyl33OFtBvCI7S4N1b8vlDylF2hG2N0NN/                                                                                                              
sky:$6$$Ny8IwgIPYq5pHGZqyIXmoVRRmWydH7u2JbaTo.H2kNG7hFtR.pZb94.HjeTK1MLyBxw8PUeyzJszcwfH0qepG0                                                                                                                     
sunset:$6$406THujdibTNu./R$NzquK0QRsbAUUSrHcpR2QrrlU3fA/SJo7sPDPbP3xcCR/lpbgMXS67Y27KtgLZAcJq9KZpEKEqBHFLzFSZ9bo/
space:$6$$4NccGQWPfiyfGKHgyhJBgiadOlP/FM4.Qwl1yIWP28ABx.YuOsiRaiKKU.4A1HKs9XLXtq8qFuC3W6SCE4Ltx/  
```

## Cracking sunset

I opened the above file and deleted all but sunset's hash, then used john with rockyou.txt to get the password `cheer14`. This worked when ssh'ing onto the machine, and in their home dir was `user.txt` containing `5b5b8e9b01ef27a1cc0a2d5fa87d7190`, which meant nothing to me (might be a red herring).

Running `sudo -l` revealed sunset also had access to /usr/bin/ed, an ancient text editor (one line at a time) in linux. This tool runs as root (when run with sudo) and can execute commands. So, as sunset, `sudo /usr/bin/ed`, then use `!/bin/sh` to start a shell. Finally, cd to `/root` and cat the flag.

/root/flag.txt: `25d7ce0ee3cbf71efbac61f85d0c14fe`