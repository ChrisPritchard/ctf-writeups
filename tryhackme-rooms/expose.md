# Expose

https://tryhackme.com/room/expose, ranked Easy

*Exposing unnecessary services in a machine can be dangerous. Can you capture the flags and pwn the machine?*

In my opinion, this room should be renamed 'Rabbit's Nest', given the number of rabbit holes and misdirections it contains. However, it actually is fairly simple *assuming* you find the foothold, which can be simple or impossible based on your setup.

1. A scan reveals 21 (FTP), 22 (SSH), 53 (DNS), 1337 (Apache website) and 1883 (MQTT).

   - 21 allows ftp anon, but is blank with no write access;
   - 53 doesn't containj any useful info,
   - 1883 just shows broker channels and no other access.
   
   So 21, 53 and 1883 are all red herrings (probably 22 as well, as I didn't use it). I'd say this probably makes the hint published in the room discription above *also* a red herring, as the foot hold is in the web service.

3. The website on 1337 just shows 'EXPOSED' text. To proceed, directory brute forcing is required and this is where the challenge can be easy or impossible. I always use [directory-list-2.3-medium.txt](https://github.com/danielmiessler/SecLists/blob/master/Discovery/Web-Content/directory-list-2.3-medium.txt) as my enum wordlist of choice - its a nice 220k worth of options, and I've found it pretty reliable. Using this will reveal `/admin`, `/javascript/psl`, `javascript/jquery` and `/phpmyadmin`, however none of these are the foothold:

  - the admin site doesn't contain a html form, so is just non-functional html
  - the javascript sub folders are not relevant
  - the phpmyadmin site is a recently patched version, largely impersious if you don't have credentials

3. The path you need to find is in several wordlists aside from the one I used: one which works is [raft-large-directories.txt](https://github.com/danielmiessler/SecLists/blob/master/Discovery/Web-Content/raft-large-directories.txt), a mere 60k wordlist but which has the specific path for the foothold. It finds it almost immediately with ffuf - the page found is identical to `/admin` earlier discovered except this variant is functional, with javascript that submits user credentials to `[path]/includes/user_login.php`

4. Simple experiementation can show that the page will error if commas or other sql syntax is added, so using burp take a copy of the request to user_Login and give it to sqlmap with `-r request.txt --dump`: this will rapidly dump the contents of the database, revealing a couple of tables. One of these tables contains two new hidden webpaths, and the credentials for one of them. The other path requires that you submit a username to access it.

5. With the first path, after logging in you are presented with a message that indicates you should try parameter fuzzing. However, if you look at the source code for this page (best in something like burp, as its only available on the post request) it will mention using 'file'. Accordingly, this is a simple LFI page: by adding `?file=/etc/passwd` you can retrieve the users of the box.

6. With these users, you can now submit the right user to access the other hidden path, which presents an upload form. The form restricts to `.png` files, and there is javascript that checks that the extension sent is a `png` or a `jpg`. However as this validation is entirely client side, by disabling the javascript you can upload whatever you wish. I uploaded a mini PHP shell, and in the response of the upload request the source code contains a hint as to where the files are uploaded. This provided a simple web shell as www-data.

7. From here the path to user and root is trivial: getting a reverse shell, you can find a user's home directory containing a file named `SSH_creds.txt`. These creds do not work over SSH (another rabbit hole?) but do work for `su [user]` from your rev shell, getting the first flag. To get to root, that user can access /bin/find which is restricted to that user and root, and has its suid bit set. Therefore, `find . -exec /bin/sh -p \; -quit` will give a root shell.

Overall a fairly simple room, but one where using the wrong wordlist will hurt you. Something to keep in mind whenever you can't find anything - switch up your wordlists!
