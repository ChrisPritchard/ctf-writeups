# Jurassic Park

This medium-hard task will require you to enumerate the web application, get credentials to the server and find 5 flags hidden around the file system. Oh, Dennis Nedry has helped us to secure the app too...

You're also going to want to turn up your devices volume (firefox is recommended). So, deploy the VM and get hacking..

## Recon

Initial `nmap -p-` revealed:

```
Starting Nmap 7.80 ( https://nmap.org ) at 2020-04-26 02:54 UTC
Nmap scan report for ip-10-10-23-246.eu-west-1.compute.internal (10.10.23.246)
Host is up (0.00065s latency).
Not shown: 65533 closed ports
PORT   STATE SERVICE
22/tcp open  ssh
80/tcp open  http
MAC Address: 02:C7:70:B4:4A:54 (Unknown)

Nmap done: 1 IP address (1 host up) scanned in 2.83 seconds
```

nikto and dirb against the website revealed a delete page, whose contents was the following:

```
New priv esc for Ubunut??

Change MySQL password on main system!
```

The assets dir was also listable.
