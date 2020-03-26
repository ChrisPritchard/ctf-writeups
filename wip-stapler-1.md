# Stapler: 1

https://www.vulnhub.com/entry/stapler-1,150/

Recommended on the list of [OSCP-like VMs here](https://www.abatchy.com/2017/02/oscp-like-vulnhub-vms).

## Recon

An all port scan returned:

```
PORT      STATE  SERVICE
20/tcp    closed ftp-data
21/tcp    open   ftp
22/tcp    open   ssh
53/tcp    open   domain
80/tcp    open   http
123/tcp   closed ntp
137/tcp   closed netbios-ns
138/tcp   closed netbios-dgm
139/tcp   open   netbios-ssn
666/tcp   open   doom
3306/tcp  open   mysql
12380/tcp open   unknown
```

So: ftp, ssh, 'domain' (dns), http, a samba share, mysql and two custom ports(?) 666 and 12380

## DOOM nc

I used nc to read port 666, which returned a byte stream. Using `nc 192.168.1.76 666 > out.bin` I got the content, then used `binwalk out.bin` to find it was a zip file. Unzipping returned `message2.jpg`. The image was of a series of shell commands, copied here as:

```
~$ echo Hello World.
Hello World.
~$ 
~$ echo Scott, please change this message
segmentation fault
```

Perhaps an indication of a binary somewhere which an overflow error?

## FTP

Connecting shows this banner:

```
220-
220-|-----------------------------------------------------------------------------------------|                                                                                                   
220-| Harry, make sure to update the banner when you get a chance to show who has access here |                                                                                                   
220-|-----------------------------------------------------------------------------------------|                                                                                                   
220-                                                                                                                                                                                              
220
```

I can log in as anonymous, and find a single file: `note` The contents of `note` are:

```
Elly, make sure you update the payload information. Leave it in your FTP account once your are done, John.
```
