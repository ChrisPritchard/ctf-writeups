# Natas 20

To see the site:

1. Go to [http://natas20.natas.labs.overthewire.org](http://natas20.natas.labs.overthewire.org)
2. Log in with natas20, eofm3Wsshxc5bwtVnEuGIlr7ivb9KABF

Reading through the source, the code to write and read session values is insecure; the vuln is that key/values are saved as text line by line, and read the same way.
By specifying a value (the name value, which you can submit via the form) with a newline and carriage return, you can add additional keys to the loaded session.

3. Enter "admin\r\nadmin 1" (without quotes) into the name field and submit to get the password for natas21