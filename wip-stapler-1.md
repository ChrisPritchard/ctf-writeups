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

## FTP Anonymous

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

## HTTP

The website is blank page showing that `The requested resource <code class="url">/</code> was not found on this server.`. 

A nikto and dirb reveal .profile, and .bashrc are present, showing this is surfacing a home folder. A search for other files, and path traversal, don't find anything, but this might be a candidate for something in future.

I tried posting content into it, but that failed.

## SMB

This blog was useful for SMB shenanigans: [smb-enumeration-for-penetration-testin](https://medium.com/@arnavtripathy98/smb-enumeration-for-penetration-testing-e782a328bf1b)

I ran the following to get a list of files on the share:

```
kali@kali:~$ smbmap -H 192.168.1.74 -P 139 -R
[+] Finding open SMB ports....
[+] Guest RPC session established on 192.168.1.74...
[+] IP: 192.168.1.74:139        Name: 192.168.1.74                                      
        Disk                                                    Permissions     Comment
        ----                                                    -----------     -------
        print$                                                  NO ACCESS       Printer Drivers
        .                                                  
        dr--r--r--                0 Fri Jun  3 12:52:52 2016    .
        dr--r--r--                0 Mon Jun  6 17:39:56 2016    ..
        dr--r--r--                0 Sun Jun  5 11:02:27 2016    kathy_stuff
        dr--r--r--                0 Sun Jun  5 11:04:14 2016    backup
        kathy                                                   READ ONLY       Fred, What are we doing here?
        .\
        dr--r--r--                0 Fri Jun  3 12:52:52 2016    .
        dr--r--r--                0 Mon Jun  6 17:39:56 2016    ..
        dr--r--r--                0 Sun Jun  5 11:02:27 2016    kathy_stuff
        dr--r--r--                0 Sun Jun  5 11:04:14 2016    backup
        .\kathy_stuff\
        dr--r--r--                0 Sun Jun  5 11:02:27 2016    .
        dr--r--r--                0 Fri Jun  3 12:52:52 2016    ..
        -r--r--r--               64 Sun Jun  5 11:02:27 2016    todo-list.txt
        .\backup\
        dr--r--r--                0 Sun Jun  5 11:04:14 2016    .
        dr--r--r--                0 Fri Jun  3 12:52:52 2016    ..
        -r--r--r--             5961 Sun Jun  5 11:03:45 2016    vsftpd.conf
        -r--r--r--          6321767 Mon Apr 27 13:14:45 2015    wordpress-4.tar.gz
        tmp                                                     READ, WRITE     All temporary files should be stored here
        .\
        dr--r--r--                0 Thu Mar 26 19:28:20 2020    .
        dr--r--r--                0 Mon Jun  6 17:39:56 2016    ..
        -r--r--r--              274 Sun Jun  5 11:32:58 2016    ls
        IPC$                                                    NO ACCESS       IPC Service (red server (Samba, Ubuntu))
```

Connecting with `smbclient \\\\192.168.1.74\\kathy` I was able to download the three files under `kathy_stuff` and `backup`.

The content of `todo-list.txt` was `I'm making sure to backup anything important for Initech, Kathy`.

The vsftp file seemed pretty standard. The wordpress archive suggests to me their might be a wordpress site somewhere.

The ls file under tmp looks to be a txt file (I can also run it, with odd results). It returns the following content from a cat:

```
.:
total 12.0K
drwxrwxrwt  2 root root 4.0K Jun  5 16:32 .
drwxr-xr-x 16 root root 4.0K Jun  3 22:06 ..
-rw-r--r--  1 root root    0 Jun  5 16:32 ls
drwx------  3 root root 4.0K Jun  5 15:32 systemd-private-df2bff9b90164a2eadc490c0b8f76087-systemd-timesyncd.service-vFKoxJ
```

Which does look like the possible content of the actual tmp dir on the machine. Importantly, I discover I can actually upload files into this tmp dir. Hmm.

## Port 12380

I had taken a look at this earlier with nc, but hadn't gotten far. I *should* have guessed it was a http/https port - I tested this now, given the wordpress archive. Sure enough, `http://192.168.1.74:12380` shows a holding page, with nothing interesting except an uncommon response header `dave: something doesn't look quite right here`. 

A nikto scan suggests the site has a ssl configured, and when I browse to `https://192.168.1.74:12380` I get something different: a blank page with the text `Internal Index Page!`

The robots.txt file contained two entries: `admin112233` and `blogblog`. The first took me to a xss page, that posts a warning message about beef hooks (a way to use xss to exploit user browser sessions via a tool called BEEF) before redirecting to xss-payloads.com. Accessing the site wiothout javascript (or via burp) reveals nothing except a congratulations for not falling to a script attack.

Browsing to /blogblog/ reveals a word press site, with nothing of obvious on it.

## WordPress and plugins

Browsing through the site I found a post indicating that said `The only thing really which Vicki managed to sort out was to a few WordPress plugins for us. Please be sure to check out their new features!`

I did a wordpress scan against the site, with aggresive searching for plugins, and found several (these were also listed under the listable `wp-content/plugins` directory). The first that I checked, `advanced-video-embed-embed-videos-or-playlists`, had a [public exploit-db entry](https://www.exploit-db.com/exploits/39646) for local file inclusion.

Using this I created a post whose jpeg thumbnail was actually the wp-config.php file, which I grabbed via `wget` and catted to reveal the root credentials of mysql on the box, which I used to log in through phpmyadmin.
