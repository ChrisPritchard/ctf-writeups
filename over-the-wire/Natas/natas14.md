# Natas 14

1. Go to [http://natas14.natas.labs.overthewire.org](http://natas14.natas.labs.overthewire.org)
2. Log in with natas14, Lg96M10TdfaPyVBkJdjymbllQ5L6qdl1
3. This is a basic sql injection attack. In MySQL you can use ` OR 1` as part of a where clause to negate it (its always true) (e.g. `select * from users where username = "" or 1`), so use `" OR 1 #` in the username field (no password needed) to get the password for natas 15. The `#` just ignores the rest of the statement.

By following the source code, you can see you can add a debug flag either in the query string of the page if you also put username in the querystring with your injection, or in the target url of the form field using inpect/dev tools. This will display the executed sql for you, to verify it is done correctly.
