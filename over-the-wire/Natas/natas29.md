# Natas 29

To see the site:

1. Go to [http://natas29.natas.labs.overthewire.org](http://natas29.natas.labs.overthewire.org)
2. Log in with natas29, airooCaiseiyee8he8xongien9euhe8b

Perl! I've never worked with perl... but, given the dropdown changes the querystring with a suspiciously named 'file' parameter, and that if you change the parameter to /etc/natas_webpass/natas30 you get "meeeep!" printed, I guessed this was some sort of file injection with the server filtering out natas. 

A quick search found that the way to open files in perl is to use open(), and that this has a massive escape feature in that you can pipe the file inside using pipe params. One other thing I didn't know is that Perl, which is very close to C, can terminate any string by submitting the null byte \00 or %00 in url terms - we are not in .NET land anymore, friends.

3. Using the url `http://natas29.natas.labs.overthewire.org/index.pl?file=|ls+%00` you can see the contents of the web directory. View source is helpful from here on, manipulating the URL from there. To get access despite the 'right click blocking', use your browser menu.
4. The url `http://natas29.natas.labs.overthewire.org/index.pl?file=|cat+index.pl+%00` will show the perl script mixed with html for the page, confirming how the open works and that /natas is searched for and broken.
5. On a whim I tested something I've tested many times before with natas and bandit but which has never worked: command line wildcards. It worked here! Use this url to get the password for natas30: `http://natas29.natas.labs.overthewire.org/index.pl?file=|cat /etc/?????_webpass/?????30%00`