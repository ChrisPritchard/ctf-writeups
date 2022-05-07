# Natas 24

To see the site:

1. Go to [http://natas24.natas.labs.overthewire.org](http://natas24.natas.labs.overthewire.org)
2. Log in with natas24, OsRmXFguozKpTZZ5X14zNO43379LZveg

The code uses strcmp, a function that can also be bypassed using type juggling: passing an array instead of a string will cause strcmp to return true. You can't pass an array through the form, but via the querystring works fine.

3. Append to the querystring `?passwd[0]=1` to reveal the password for natas25.
