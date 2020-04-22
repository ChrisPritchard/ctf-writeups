# Kioptrix: 1

https://www.vulnhub.com/entry/kioptrix-level-1-1,22/

Recommended as an OSCP-like VM here: https://www.abatchy.com/2017/02/oscp-like-vulnhub-vms

## Setup

I had tried this one before, but had failed to get it to work. Not even able to get it to run. Not sure entirely what I fixed to get it running this time, but I'll document the steps in case they're helpful.

I use virtualbox on Windows 10. I tend to do vulnhub VMs by running the VM in one instance and Kali next to it in another. My windows PC is a beast, and so I have no issue running these VMs performance or space wise.

1. Kioptrix: 1 is a VMWare VM. It comes down in a .rar, which I extracted, revealing a VMDK file.
2. I create a new VM in virtual box (normally I import the .ova, not possible here), and select the VMDK as the harddrive
3. For network settings, I set both Kali and the Kioptrix VM to use Host only
4. Additionally, I changed the hardware for the Kiptrix VM from the default `Intel PRO/1000 MT Desktop (82540EM)` to `PCnet-PCI II (Am79C970A)`

This last step seemed to be the key - before that, no matter what I did, I could not find Kioptrix on the network. The host only step is probably unnecessary - I just needed to switch to it to absolutely confirm Kioptrix was not coming up. My home network is a bit noisy, so bridged (which is what I normally use) wasn't making Kioptrix's absence clear.

## Recon

Nmap -p- reveals:

```
PORT      STATE SERVICE
22/tcp    open  ssh
80/tcp    open  http
111/tcp   open  rpcbind
139/tcp   open  netbios-ssn
443/tcp   open  https
32768/tcp open  filenet-tms
```

A full scan (-T4 -A) revealed:

```
PORT      STATE SERVICE     VERSION
22/tcp    open  ssh         OpenSSH 2.9p2 (protocol 1.99)
| ssh-hostkey: 
|   1024 b8:74:6c:db:fd:8b:e6:66:e9:2a:2b:df:5e:6f:64:86 (RSA1)
|   1024 8f:8e:5b:81:ed:21:ab:c1:80:e1:57:a3:3c:85:c4:71 (DSA)
|_  1024 ed:4e:a9:4a:06:14:ff:15:14:ce:da:3a:80:db:e2:81 (RSA)
|_sshv1: Server supports SSHv1
80/tcp    open  http        Apache httpd 1.3.20 ((Unix)  (Red-Hat/Linux) mod_ssl/2.8.4 OpenSSL/0.9.6b)
| http-methods: 
|_  Potentially risky methods: TRACE
|_http-server-header: Apache/1.3.20 (Unix)  (Red-Hat/Linux) mod_ssl/2.8.4 OpenSSL/0.9.6b
|_http-title: Test Page for the Apache Web Server on Red Hat Linux
111/tcp   open  rpcbind     2 (RPC #100000)
139/tcp   open  netbios-ssn Samba smbd (workgroup: MYGROUP)
443/tcp   open  ssl/https   Apache/1.3.20 (Unix)  (Red-Hat/Linux) mod_ssl/2.8.4 OpenSSL/0.9.6b
|_http-server-header: Apache/1.3.20 (Unix)  (Red-Hat/Linux) mod_ssl/2.8.4 OpenSSL/0.9.6b
|_http-title: 400 Bad Request
|_ssl-date: 2020-04-12T01:56:50+00:00; +4h00m03s from scanner time.
| sslv2: 
|   SSLv2 supported
|   ciphers: 
|     SSL2_RC2_128_CBC_WITH_MD5
|     SSL2_DES_192_EDE3_CBC_WITH_MD5
|     SSL2_RC4_128_EXPORT40_WITH_MD5
|     SSL2_RC4_64_WITH_MD5
|     SSL2_RC2_128_CBC_EXPORT40_WITH_MD5
|     SSL2_DES_64_CBC_WITH_MD5
|_    SSL2_RC4_128_WITH_MD5
32768/tcp open  status      1 (RPC #100024)
```

A dirb on the website at 80 reveals:

```
---- Scanning URL: http://192.168.53.9/ ----
+ http://192.168.53.9/~operator (CODE:403|SIZE:273)                                                                                                                            
+ http://192.168.53.9/~root (CODE:403|SIZE:269)                                                                                                                                
+ http://192.168.53.9/cgi-bin/ (CODE:403|SIZE:272)                                                                                                                             
+ http://192.168.53.9/index.html (CODE:200|SIZE:2890)                                                                                                                          
==> DIRECTORY: http://192.168.53.9/manual/                                                                                                                                     
==> DIRECTORY: http://192.168.53.9/mrtg/                                                                                                                                       
==> DIRECTORY: http://192.168.53.9/usage/                                                                                                                                      
                                                                                                                                                                               
---- Entering directory: http://192.168.53.9/manual/ ----
(!) WARNING: Directory IS LISTABLE. No need to scan it.                        
    (Use mode '-w' if you want to scan it anyway)
                                                                                                                                                                               
---- Entering directory: http://192.168.53.9/mrtg/ ----
+ http://192.168.53.9/mrtg/index.html (CODE:200|SIZE:17318)                                                                                                                    
                                                                                                                                                                               
---- Entering directory: http://192.168.53.9/usage/ ----
+ http://192.168.53.9/usage/index.html (CODE:200|SIZE:3704)        
```

This reveals three things installed on the apache website:

- Module mod_perl (whose index page also suggests this is Apache 1.3b5) (under manual/mod)
- Multi Router Traffic Grapher (MRTG 2.9.6) (under /mrtg)
- Webalizer Version 2.01 (under /usage)
