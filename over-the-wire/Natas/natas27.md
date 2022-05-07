# Natas 27

To see the site:

1. Go to [http://natas27.natas.labs.overthewire.org](http://natas27.natas.labs.overthewire.org)
2. Log in with natas27, 55TBjpPZUUJgVP5b3BnbG6ON9uDPVzCJ

I needed help for this one, as the vuln is due to silly behaviour by mysql.

I figured out that the solution to this one was to get a second user for natas28 created, as the dump data function will return all data for all users with natas28 as their username, not just a single row. To create a user, I needed the validUser check to fail, couldn't figure out how.

The solution/bug is: when selecting with a where clause in mysql, if you pass a value to check that is larger than the column size you will get false back (or an error). However when inserting a value larger than the column size, the extra space is trimmed away. Also, a value with trailing spaces is ignored in a where clause.

3. Specify the username as `natas28                                                         e`, with password `exfil` and submit.
4. It should say that the user has been created. Return to the previous screen and submit `natas28` and password `exfil` to get the password for natas28 printed.