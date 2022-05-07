# Natas 25

To see the site:

1. Go to [http://natas25.natas.labs.overthewire.org](http://natas25.natas.labs.overthewire.org)
2. Log in with natas25, GHF6X7YwACaYYssHVY05cFq83hRktl4c

I needed some hints on this one, but the solution is straight forward. The point of entry is the lang request variable, controlled by the select drop down or the querystring. It `include`s a file, which will render that file as html and/or parse it as PHP. So, obvious idea is to point it at the password file. It starts at language/ (a relative dir to the website), so ../../../../../etc/natas_webpass/natas26 is the starting point. However the code replaces all occurances of `../` with an empty string in the path, and will outright quit if 'natas_webpass' is detected. I also tested using wildcards like ? but they didn't work.

First hint was that replacing `../` with an empty string is not as secure as it seems: `.../...//` will, under such a transformation, *become* `../`. With that in mind we can now transverse anywhere except natas_webpass, as the second protection is ironclad (it stops the request).

Second hint was to use another piece of the code which I had dismissed: when `../` or `natas_webpass` are found in the submitted variable, the code logs to a log directory. The log file is made up of various information, including the user agent. The log path is specified, and the filename is appended with the session id. Cool - I control both the session id AND the useragent, which means I can control a portion of what goes into the file. And there are no checks on *that* content.

3. Using dev tools, change the submitted user agent header to `<?php passthru("cat /etc/natas_webpass/natas26"); ?>`
4. Change the session id cookie (PHPSESSID) to "exfil"
5. Add the querystring parameter `?lang=.../...//.../...//.../...//.../...//.../...//var/www/natas/natas25/logs/natas25_exfil.log`
6. Send the request and check the response to get the password for natas26