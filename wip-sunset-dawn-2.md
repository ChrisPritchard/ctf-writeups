# WIP: Sunset: Dawn 2

https://www.vulnhub.com/entry/sunset-dawn2,424/

## Recon

Doing a nmap scan revealed 80 and two non-standard ports:

```
nmap -p- 192.168.1.189
Starting Nmap 7.80 ( https://nmap.org ) at 2020-03-18 17:37 EDT
mass_dns: warning: Unable to determine any DNS servers. Reverse DNS is disabled. Try using --system-dns or specify valid servers with --dns-servers
Nmap scan report for 192.168.1.189
Host is up (0.0021s latency).
Not shown: 65532 closed ports
PORT     STATE SERVICE
80/tcp   open  http
1435/tcp open  ibm-cics
1985/tcp open  hsrp

Nmap done: 1 IP address (1 host up) scanned in 7.70 seconds
```

A deep scan, nikto etc didn't reveal anything of interest. The website contained a standard banner, and a download like:

```
Website currently under construction, try again later.

In case you are suffering from any kind of inconvenience with your device provided by the corporation please contact with IT support as soon as possible, however, if you are not affiliated by any means with "Non-Existent Corporation and Associates" (NECA) LEAVE THIS SITE RIGHT NOW.
News:

    Due the last breach that the organization has suffered from and yet no explanation for such attempt of disruption was compiled; NECA has come to a solution, which was to close all services and unite them in once, therefore, creating the "Dawn" server. It can be downloaded from here. A client is currently under development.
    The camera feeds have been successfully installed.
    The personal has been updated. 

Things we need to implement:

    IDS and WAF software.
    A brand new blue team, capable of detecting and repelling malicious actors.
```

I downloaded the dawn.zip, which contained a windows executable `dawn.exe` plus a readme.txt containing:

```
DAWN Multi Server - Version 1.1

Important:

Due the lack of implementation of the Dawn client, many issues may be experienced, such as the message not being delivered. In order to make sure the connection is finished and the message well received, send a NULL-byte at the ending of your message. 
Also, the service may crash after several requests.

Sorry for the inconvenience!
```
