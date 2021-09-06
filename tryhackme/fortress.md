# Fortress

https://tryhackme.com/room/fortress

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
