# Natas 26

To see the site:

1. Go to [http://natas26.natas.labs.overthewire.org](http://natas26.natas.labs.overthewire.org)
2. Log in with natas26, oGgWAJ7zcGT28vYazGo4rkhOPDhBu34T

Looking at the code, there doesn't seem to be much you can do. A class called Logger looks promising, with its write methods, but the write path doesn't seem controllable and the class isn't used anywhere anyway. The rest of the code seems straightforward, with injection opportunities via the parameters, session id and a base64-encoded, serialized 'drawing' cookie, however messing around with these got me nowhere. I could potentially control the name of the image, but I couldn't control its content except by submitting valid values to draw lines.

In .NET languages serialization/unserialization is occasionally a serious problem (e.g. with expand attacks), and given everything in PHP land seems to be '.NET-but-much-much-worse', I did a quick look to see if there are exploits with unserialize. And there is: [https://www.notsosecure.com/remote-code-execution-via-php-unserialize/](https://www.notsosecure.com/remote-code-execution-via-php-unserialize/).

In brief, if you can submit your own input to unserialize (which I can, since its a base64-encoded cookie), and if you have a class handy which does file writing when destructed (hello Logger class!), then you can craft a serialized payload that will instantiate your class on the server, writing what you wish when its thrown away.

The payload below does just that, placing a php file in the images directory (which we know is already write-accessible/user-readable, as the generated images go there) with a payload that reads the password.

`O:6:\"Logger\":3:{s:15:\"\0Logger\0logFile\";s:36:\"/var/www/natas/natas26/img/exfil.php\";s:15:\"\0Logger\0initMsg\";s:0:\"\";s:15:\"\0Logger\0exitMsg\";s:52:\"<?php passthru('cat /etc/natas_webpass/natas27'); ?>\";}`

FYI, The above string has its quotes already escaped, to make it easier to paste into PHP's `base64_encode` or similar. For the raw value, replace all `\"` with `"`
FYI2, the Logger class has private variables, and these are settable using the syntax `\0[classname]\0[property name]`. If they were public the `\0[classname]\0` wouldn't be necessary.

3. base64 encode the payload string (with php interactive you can use `base64_encode`), and set/add the `drawing` cookie with the value.
4. Reload the page, then navigate to `/img/exfil.php`. It should contain the password for natas27, twice (the unserialize occurs twice in the code and the Logger appends).

