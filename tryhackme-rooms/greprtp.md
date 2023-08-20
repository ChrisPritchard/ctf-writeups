# Grep

*A challenge that tests your reconnaissance and OSINT skills.*

https://tryhackme.com/room/greprtp

My approach to this room was unconventional: the room name suggests the use of grep the tool, and its icon suggests google and github would be useful, presumably finding something on these platforms that allow you to breach the machine. I did not do any of this.

1. A recon with rustscan will find 22, 80, 443 and 51337. additionally, the certificate on both 51337 and 443 suggests the domain is `grep.thm`. The only url that responds to this is on 443, which redirects to `/public/html`.

> Note, the 443 (initial target site) does not come up immediately. Best to wait maybe five mins.

3. This site allows you to register and login, however if you try to login it will fail with an 'invalid API key' message. Looking at the javascript, a key is being submitted to `/api/login.php` as part of a header named `X-Thm-Api-Key`. The key is a md5 hash (`e8d25b4208b80008a9e15c8698640e85`) of the term `johncena`, a common value in wordlists.

> This is the first point of deviation from the intended path. The path would have you searching github for the company name and cms software, to find a repo that the room creator has placed. This repo contains the correct API key. Additionally, there is also a postman collection you can find with the key. I however didn't go that direction - my few searches didn't find anything, and then my other approach worked.

3. In the belief this is a brute forcing challenge, I needed to try different MD5 values for the API key. I used FFUF with the rockyou wordlist, but to convert the wordlist values to MD5 before passing to FFUF I used a tool called [Cook](https://github.com/glitchedgitz/cook). FFUF can take its wordlist from Stdin, and Cook will pass MD5 hashes one at a time (trying to convert rockyou to md5 in one go is extremely time consuming). The final command was:

    `cook -f: /usr/share/wordlists/rockyou.txt f.md5 | ffuf -u https://grep.thm/api/register.php -X POST -H "X-Thm-Api-Key: FUZZ" -fr "Invalid or Expired API key" -w -`

4. With the correct api key you can get a registered account and then login. The dashboard contains the second flag (the api key was the first). A pattern emerges: pages under `/public/html/FUZZ.php` and api endpoints under `/api/FUZZ.php`. With FFUF and a directory wordlist, its possible to find upload.php in both locations.

5. The upload form restricts to image types, but only by magic bytes, e.g. you can specify any filename. To bypass this is simple: upload the smallest possible PNG or similar (just create a 1x1 pixel image), intercept the request with something like burp, change the filename to something like `shell.php`, and append or replace all bytes in the uploaded file after the initial line of magic bytes with something like `<?php system($_GET[1]) ?>`.

6. To find the uploaded file, further enumeration will reveal an `uploads` folder under /api. Going to `/api/uploads/shell.php?1=id` finds the shell and proves code execution.

> This was the second point of deviation from the main path - technically its possible to proceed without getting a reverse shell. You can find a database sql backup file with the answers you need to proceed. However I didn't do that.

7. Using a nc.openbsd reverse shell payload you can get a revshell as www-data. Reading the config.php file reveals the local database credentials, however trying to run `mysql -u [user] -p` will fail, as the mysql binary has been marked as only usable by root.

8. To get past this, and knowing that the web application can access the DB so the database server itself is not blocked, you can simply download a copy of the mysql binary from the attackbox. Once copied, make it executable and then you can connect as above. This allows retrieving the admin's email address.

9. Their password is bcrypted, however the last questions for the room implies that there is a email checker site that will give you the answer. In the `var/www` folder is a [REDACTED] subfolder, containing two php files that are not readable by www-data. Knowing that there was that web port discovered at the beginning, 51337, going to `https://[REDACTED].grep.thm:51337` will reveal the final site, and give you the admin's password when you submit their email.
